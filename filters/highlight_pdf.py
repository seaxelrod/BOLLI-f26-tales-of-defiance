#!/usr/bin/env python3
"""Post-process a plain PDF to add real PDF highlight annotations,
like the ones macOS Preview makes, so search, copy, and editing work normally.

Reads highlight color definitions from a shared colors.json file (searched via
--colors, current working directory, script directory, or parent directory),
falling back to built-in defaults if colors.json is not found.

Usage:
    .venv/bin/python3 highlight_pdf.py story.md story.pdf [-o out.pdf] [--colors colors.json]

If -o is omitted, story.pdf is updated in place.

Needs: pandoc, highlight.lua (and optionally pandoc-include.lua) in the same
folder as this script, plus: pip install pdfplumber pypdf
"""

import argparse, difflib, json, os, subprocess, sys, tempfile, unicodedata

import pdfplumber
from pypdf import PdfReader, PdfWriter
from pypdf.generic import (ArrayObject, DictionaryObject, FloatObject,
                           NameObject, NumberObject, StreamObject,
                           TextStringObject)

HERE = os.path.dirname(os.path.abspath(__file__))
FILTER = os.path.join(HERE, "highlight.lua")
INCLUDE_FILTER = os.path.join(HERE, "pandoc-include.lua")

DEFAULT_HEX_COLORS = {
    "yellow": "#FFF176",
    "green":  "#A5D6A7",
    "orange": "#FFCC80",
    "red":    "#EF9A9A",
    "brown":  "#D7CCC8",
    "purple": "#E1BEE7",
    "teal":   "#80CBC4",
}


def hex_to_rgb(hex_str):
    h = hex_str.lstrip("#")
    return (int(h[0:2], 16) / 255.0,
            int(h[2:4], 16) / 255.0,
            int(h[4:6], 16) / 255.0)


def load_colors(colors_arg=None):
    candidates = []
    if colors_arg:
        candidates.append(os.path.expanduser(colors_arg))
    else:
        candidates.extend([
            os.path.join(os.getcwd(), "colors.json"),
            os.path.join(HERE, "colors.json"),
            os.path.join(os.path.dirname(HERE), "colors.json"),
        ])

    for path in candidates:
        if os.path.isfile(path):
            with open(path, "r", encoding="utf-8") as f:
                data = json.load(f)
            items = data["colors"] if isinstance(data, dict) and "colors" in data else data
            loaded = {}
            for item in items:
                tag = str(item["tag"]).lower()
                hx = item.get("hex") or item.get("bg")
                if hx:
                    loaded[tag] = hex_to_rgb(hx)
            if loaded:
                return loaded

    if colors_arg:
        print(f"Error: colors file not found: {colors_arg}", file=sys.stderr)
        sys.exit(1)

    return {k: hex_to_rgb(v) for k, v in DEFAULT_HEX_COLORS.items()}


COLORS = load_colors()


# ---------- 1. words and their colours, from the Markdown ----------

def words_from_markdown(md):
    cmd = ["pandoc", md]
    if os.path.exists(INCLUDE_FILTER):
        cmd += ["--lua-filter", INCLUDE_FILTER]
    cmd += ["--lua-filter", FILTER, "-t", "json"]

    doc = json.loads(subprocess.run(
        cmd, check=True, capture_output=True, text=True).stdout)
    words, cur = [], []   # each word is a list of (character, colour)

    def end_word():
        if cur:
            words.append(list(cur))
        cur.clear()

    def add(text, color):
        cur.extend((ch, color) for ch in text)

    def inlines(xs, color):
        for x in xs:
            t, c = x["t"], x.get("c")
            if t == "Str":
                add(c, color)
            elif t in ("Space", "SoftBreak", "LineBreak"):
                end_word()
            elif t in ("Emph", "Strong", "Underline", "Strikeout", "SmallCaps",
                       "Superscript", "Subscript"):
                inlines(c, color)
            elif t == "Quoted":
                single = c[0]["t"] == "SingleQuote"
                add("‘" if single else "“", color)
                inlines(c[1], color)
                add("’" if single else "”", color)
            elif t == "Span":
                classes = c[0][1]
                hl = next((k[3:] for k in classes if k.startswith("hl-")), None)
                inlines(c[1], hl or color)
            elif t == "Link":
                inlines(c[1], color)
            elif t == "Cite":
                inlines(c[1], color)
            elif t == "Code":
                add(c[1], color)

    def blocks(bs):
        for b in bs:
            t, c = b["t"], b.get("c")
            if t in ("Para", "Plain"):
                inlines(c, None); end_word()
            elif t == "Header":
                inlines(c[2], None); end_word()
            elif t == "BlockQuote":
                blocks(c)
            elif t == "Div":
                blocks(c[1])
            elif t in ("BulletList",):
                for item in c: blocks(item)
            elif t == "OrderedList":
                for item in c[1]: blocks(item)

    blocks(doc["blocks"])
    return words


# ---------- 2. characters and their positions, from the PDF ----------

def chars_from_pdf(pdf):
    """Every visible character, in reading order, with its box."""
    out = []  # (char, (page, x0, top, x1, bottom))
    with pdfplumber.open(pdf) as doc:
        for pno, page in enumerate(doc.pages):
            words = page.extract_words(use_text_flow=True, return_chars=True)
            for w in words:
                for c in w["chars"]:
                    box = (pno, c["x0"], c["top"], c["x1"], c["bottom"])
                    for ch in unicodedata.normalize("NFKC", c["text"]):  # splits ligatures
                        if not ch.isspace():
                            out.append((ch, box))
    return out


# ---------- 3. match the two character streams ----------

def md_chars(md_words):
    chars = []  # (char, colour, word index)
    for wi, word in enumerate(md_words):
        for c, color in word:
            for ch in unicodedata.normalize("NFKC", c):
                if not ch.isspace():
                    chars.append((ch, color, wi))
    # A quote mark left outside the tags between two pieces of one highlight
    # (e.g. <GREEN>[Sai:]</GREEN> “<GREEN>…) gets the highlight too.
    i = 0
    while i < len(chars):
        if chars[i][1] is None:
            j = i
            while j < len(chars) and chars[j][1] is None and not chars[j][0].isalnum():
                j += 1
            if 0 < i and j < len(chars) and j - i <= 3 and chars[j][1] \
                    and chars[i - 1][1] == chars[j][1]:
                for k in range(i, j):
                    chars[k] = (chars[k][0], chars[j][1], chars[k][2])
            i = max(j, i + 1)
        else:
            i += 1
    return chars


def colour_pdf_chars(md_words, pdf_chars):
    a = md_chars(md_words)
    sm = difflib.SequenceMatcher(None, [c for c, _, _ in a],
                                 [c for c, _ in pdf_chars], autojunk=False)
    colors, ids = [None] * len(pdf_chars), [None] * len(pdf_chars)
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == "equal" or (tag == "replace" and i2 - i1 == j2 - j1):
            for k in range(j2 - j1):
                colors[j1 + k], ids[j1 + k] = a[i1 + k][1], a[i1 + k][2]
        elif tag in ("replace", "insert"):
            # extra PDF characters (e.g. a hyphen at a line break): colour them
            # only if the characters on both sides belong to the same highlight
            before = a[i1 - 1] if i1 > 0 else None
            after = a[i2] if i2 < len(a) else None
            if before and after and before[1] and before[1] == after[1] \
                    and after[2] - before[2] <= 1:
                for j in range(j1, j2):
                    colors[j], ids[j] = before[1], before[2]
    return colors, ids


# ---------- 4. draw highlight annotations ----------

def highlight_annot(writer, page_height, lines, rgb):
    pad = 1.0
    quads, xs, ys = [], [], []
    for x0, top, x1, bottom in lines:
        y_top = page_height - top + pad
        y_bot = page_height - bottom - pad
        x0, x1 = x0 - pad, x1 + pad
        quads += [x0, y_top, x1, y_top, x0, y_bot, x1, y_bot]
        xs += [x0, x1]; ys += [y_top, y_bot]
    rect = [min(xs), min(ys), max(xs), max(ys)]

    # Appearance stream so every viewer shows it the same way (multiply blend).
    ops = ["/GS0 gs", "%.3f %.3f %.3f rg" % rgb]
    for x0, top, x1, bottom in lines:
        ops.append("%.2f %.2f %.2f %.2f re f" % (
            x0 - pad, page_height - bottom - pad, (x1 - x0) + 2 * pad,
            (bottom - top) + 2 * pad))
    ap = StreamObject()
    ap.set_data("\n".join(ops).encode())
    ap.update({
        NameObject("/Type"): NameObject("/XObject"),
        NameObject("/Subtype"): NameObject("/Form"),
        NameObject("/BBox"): ArrayObject([FloatObject(v) for v in rect]),
        NameObject("/Resources"): DictionaryObject({
            NameObject("/ExtGState"): DictionaryObject({
                NameObject("/GS0"): DictionaryObject({
                    NameObject("/BM"): NameObject("/Multiply"),
                    NameObject("/ca"): FloatObject(1)})})}),
    })
    ap_ref = writer._add_object(ap)
    return DictionaryObject({
        NameObject("/Type"): NameObject("/Annot"),
        NameObject("/Subtype"): NameObject("/Highlight"),
        NameObject("/Rect"): ArrayObject([FloatObject(v) for v in rect]),
        NameObject("/QuadPoints"): ArrayObject([FloatObject(v) for v in quads]),
        NameObject("/C"): ArrayObject([FloatObject(v) for v in rgb]),
        NameObject("/F"): NumberObject(4),
        NameObject("/T"): TextStringObject("highlight_pdf.py"),
        NameObject("/AP"): DictionaryObject({NameObject("/N"): ap_ref}),
    })


def annotate(plain_pdf, out_pdf, pdf_words, colors, ids):
    reader = PdfReader(plain_pdf)
    writer = PdfWriter(clone_from=reader)
    # group consecutive words of one highlight into runs
    runs, cur, cur_key = [], [], None
    for (ch, box), col, wid in zip(pdf_words, colors, ids):
        if col and cur and cur_key == col and wid - cur[-1][2] <= 1:
            cur.append(([box], col, wid))
        else:
            if cur and cur_key: runs.append((cur_key, cur))
            cur, cur_key = ([([box], col, wid)] if col else []), col
    if cur and cur_key: runs.append((cur_key, cur))

    count = 0
    for color, items in runs:
        if color not in COLORS:
            continue
        by_page = {}
        for boxes, _, _ in items:
            for pno, x0, top, x1, bottom in boxes:
                lines = by_page.setdefault(pno, [])
                for ln in lines:  # same line if vertical positions overlap
                    if abs(ln[1] - top) < 3:
                        ln[0] = min(ln[0], x0); ln[2] = max(ln[2], x1)
                        ln[3] = max(ln[3], bottom); break
                else:
                    lines.append([x0, top, x1, bottom])
        for pno, lines in by_page.items():
            h = float(writer.pages[pno].mediabox.height)
            writer.add_annotation(pno, highlight_annot(writer, h, lines, COLORS[color]))
            count += 1

    # Write to a temp file in the destination folder, then atomically replace.
    out_dir = os.path.dirname(os.path.abspath(out_pdf))
    fd, tmp_out = tempfile.mkstemp(suffix=".pdf", dir=out_dir)
    try:
        with os.fdopen(fd, "wb") as f:
            writer.write(f)
        os.replace(tmp_out, out_pdf)
    except Exception:
        if os.path.exists(tmp_out):
            os.remove(tmp_out)
        raise
    return count


def main():
    global COLORS
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("markdown", help="Source Markdown file with highlight tags")
    ap.add_argument("pdf", help="Plain PDF generated by Pandoc (with HL_PDF_PLAIN=1)")
    ap.add_argument("-o", "--output", help="Output PDF path (defaults to overwriting input PDF)")
    ap.add_argument("--colors", help="Path to shared colors.json file")
    args = ap.parse_args()

    if args.colors:
        COLORS = load_colors(args.colors)

    out_pdf = args.output or args.pdf
    md_words = words_from_markdown(args.markdown)
    pdf_words = chars_from_pdf(args.pdf)
    colors, ids = colour_pdf_chars(md_words, pdf_words)
    n = annotate(args.pdf, out_pdf, pdf_words, colors, ids)

    wanted = sum(1 for _, c, _ in md_chars(md_words) if c)
    got = sum(1 for c in colors if c)
    print(f"Wrote {out_pdf}: {n} highlight annotations; "
          f"{got} of {wanted} highlighted characters placed.")


if __name__ == "__main__":
    main()
