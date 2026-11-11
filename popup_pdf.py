#!/usr/bin/env python3
"""
popup_pdf.py — export a PowerPoint deck with click-to-reveal popups to a PDF
in which each popup gets its own page.

PDFs don't run animations, so an exported popup covers its slide. This script:
  1. finds the popups: shapes revealed by a click trigger (an entrance
     animation in an interactive sequence), or any shape whose name contains
     "popup";
  2. makes a copy of the deck with the popups removed;
  3. exports both decks to PDF;
  4. merges them: every slide from the clean copy, and right after each slide
     that has a popup, the same slide with its popup showing.

Usage
  All in one step (needs LibreOffice installed):
      python3 popup_pdf.py deck.pptx
      -> deck.pdf

  Using PowerPoint for the export (PowerPoint's fonts and rendering):
      python3 popup_pdf.py deck.pptx --prepare
          -> writes deck_nopopup.pptx; export it and deck.pptx to PDF in PowerPoint
      python3 popup_pdf.py deck.pptx --merge deck.pdf deck_nopopup.pdf
          -> writes deck_with_popups.pdf

Requires: python-pptx and pypdf  (pip3 install python-pptx pypdf)
"""
import argparse, os, shutil, subprocess, sys, tempfile
from pptx import Presentation
from pypdf import PdfReader, PdfWriter

P = '{http://schemas.openxmlformats.org/presentationml/2006/main}'


def popup_ids(slide):
    """Shape ids on this slide that are popups."""
    ids = set()
    for seq in slide._element.iter(P + 'seq'):
        ctn = seq.find(P + 'cTn')
        if ctn is None or ctn.get('nodeType') != 'interactiveSeq':
            continue
        for eff in seq.iter(P + 'cTn'):
            if eff.get('presetClass') == 'entr':
                ids |= {t.get('spid') for t in eff.iter(P + 'spTgt')}
    for sh in slide.shapes:
        if 'popup' in sh.name.lower():
            ids.add(str(sh.shape_id))
    return ids


def find_popups(pptx_path):
    """{slide index (0-based): set of popup shape ids}"""
    prs = Presentation(pptx_path)
    found = {}
    for i, slide in enumerate(prs.slides):
        ids = popup_ids(slide)
        if ids:
            found[i] = ids
    return found


def write_without_popups(pptx_path, out_path):
    prs = Presentation(pptx_path)
    for slide in prs.slides:
        ids = popup_ids(slide)
        if not ids:
            continue
        for sh in list(slide.shapes):
            if str(sh.shape_id) in ids:
                sh._element.getparent().remove(sh._element)
        timing = slide._element.find(P + 'timing')
        if timing is not None:          # its triggers point at the removed shapes
            slide._element.remove(timing)
    prs.save(out_path)


def soffice_export(pptx_path, out_dir):
    exe = shutil.which('soffice') or shutil.which('libreoffice')
    mac = '/Applications/LibreOffice.app/Contents/MacOS/soffice'
    if not exe and os.path.exists(mac):
        exe = mac
    if not exe:
        sys.exit('LibreOffice not found. Use --prepare and --merge with PowerPoint exports instead.')
    subprocess.run([exe, '--headless', '--convert-to', 'pdf', '--outdir', out_dir, pptx_path],
                   check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return os.path.join(out_dir, os.path.splitext(os.path.basename(pptx_path))[0] + '.pdf')


def merge(popups, full_pdf, clean_pdf, out_pdf):
    full, clean = PdfReader(full_pdf), PdfReader(clean_pdf)
    if len(full.pages) != len(clean.pages):
        sys.exit('The two PDFs have different page counts (%d vs %d). Were hidden slides '
                 'left out of one export?' % (len(full.pages), len(clean.pages)))
    w = PdfWriter()
    for i, page in enumerate(clean.pages):
        w.add_page(page)
        if i in popups:
            pop = w.add_page(full.pages[i])
            # links from the slide underneath would still be clickable through the
            # popup; they are on the previous page anyway
            if '/Annots' in pop:
                del pop['/Annots']
    with open(out_pdf, 'wb') as f:
        w.write(f)
    return len(w.pages)


def report(popups, out_pdf, n_pages):
    extra = 0
    for i in sorted(popups):
        print('  slide %d: popup page added as PDF page %d' % (i + 1, i + 2 + extra))
        extra += 1
    print('Wrote %s (%d pages)' % (out_pdf, n_pages))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('deck')
    ap.add_argument('--prepare', action='store_true', help='only write deck_nopopup.pptx')
    ap.add_argument('--merge', nargs=2, metavar=('FULL_PDF', 'NOPOPUP_PDF'),
                    help='merge PDFs you exported yourself')
    ap.add_argument('-o', '--out', help='output PDF name')
    a = ap.parse_args()

    base = os.path.splitext(a.deck)[0]
    popups = find_popups(a.deck)
    if not popups:
        print('No popups found; just export the deck as usual.')
        return

    if a.prepare:
        write_without_popups(a.deck, base + '_nopopup.pptx')
        print('Wrote %s_nopopup.pptx — export it and %s to PDF, then run --merge.' % (base, a.deck))
        return

    if a.merge:
        out = a.out or base + '_with_popups.pdf'
        report(popups, out, merge(popups, a.merge[0], a.merge[1], out))
        return

    out = a.out or base + '.pdf'
    with tempfile.TemporaryDirectory() as tmp:
        clean_pptx = os.path.join(tmp, 'nopopup.pptx')
        write_without_popups(a.deck, clean_pptx)
        full_dir, clean_dir = os.path.join(tmp, 'full'), os.path.join(tmp, 'clean')
        os.makedirs(full_dir); os.makedirs(clean_dir)
        full_pdf = soffice_export(os.path.abspath(a.deck), full_dir)
        clean_pdf = soffice_export(clean_pptx, clean_dir)
        report(popups, out, merge(popups, full_pdf, clean_pdf, out))


if __name__ == '__main__':
    main()
