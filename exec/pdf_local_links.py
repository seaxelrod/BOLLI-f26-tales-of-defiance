#!/usr/bin/env python3

"""Rewrite the base URL of web links in a PDF.

Turns links to the public course website into links to a local copy:

    python3 pdf_local_links.py week4_presentation_withnotes.pdf
        -> week4_presentation_withnotes_locallinks.pdf

Options:
    -o OUT         output file (default: <input>_locallinks.pdf)
    --from URL     base to replace (default: the public site)
    --to URL       new base        (default: http://localhost:8000/)

Only links that start with the --from base are changed; the rest of each link
(path, ?query, #anchor) is kept. The input file is never modified.

Needs pypdf:  pip install pypdf
"""
import argparse
import sys
from pathlib import Path

from pypdf import PdfReader, PdfWriter
from pypdf.generic import NameObject, TextStringObject

PUBLIC = "https://seaxelrod.github.io/BOLLI-f26-tales-of-defiance/"
LOCAL = "http://localhost:8000/"


def with_slash(url):
    return url if url.endswith("/") else url + "/"


def main():
    p = argparse.ArgumentParser(description="Rewrite the base URL of links in a PDF.")
    p.add_argument("input")
    p.add_argument("-o", "--output")
    p.add_argument("--from", dest="old", default=PUBLIC)
    p.add_argument("--to", dest="new", default=LOCAL)
    a = p.parse_args()

    src = Path(a.input)
    out = Path(a.output) if a.output else src.with_name(src.stem + "_locallinks.pdf")
    if out.resolve() == src.resolve():
        sys.exit("Output would overwrite the input; choose another name with -o.")
    old, new = with_slash(a.old), with_slash(a.new)

    writer = PdfWriter(clone_from=PdfReader(src))
    changed = 0
    for page in writer.pages:
        for ref in page.get("/Annots") or []:
            annot = ref.get_object()
            if annot.get("/Subtype") != "/Link":
                continue
            action = annot.get("/A")
            if action is None:
                continue
            action = action.get_object()
            uri = action.get("/URI")
            if action.get("/S") == "/URI" and uri is not None and str(uri).startswith(old):
                action[NameObject("/URI")] = TextStringObject(new + str(uri)[len(old):])
                changed += 1

    with open(out, "wb") as f:
        writer.write(f)
    print(f"{out}: {changed} link(s) changed from {old} to {new}")


if __name__ == "__main__":
    main()
