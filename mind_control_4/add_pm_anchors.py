#!/usr/bin/env python3
"""Add pm-* anchors to ThePerfectMatch_Highlighted.md.

Usage:  python3 add_pm_anchors.py ../materials/perfect_match/ThePerfectMatch_Highlighted.md

Each anchor is an empty Pandoc span, []{#pm-name}, put at the start of the
paragraph that begins with the given text. Pandoc turns it into <span id=...>
in HTML and a \\label in PDF, and highlight.lua leaves it alone.

The file is edited in place (a .bak copy is kept). Running it again is safe:
anchors already present are skipped. If a paragraph start is not found exactly
once, nothing is written and the problem is reported.
"""
import shutil
import sys

ANCHORS = [
    ("pm-il-sospetto",         "Sai woke to the rousing"),
    ("pm-what-you-want",       "<GREEN>“Tilly doesn’t just tell you what you want,” Jenny shouted."),
    ("pm-boring-date",         "Although everything had gone exceedingly well"),
    ("pm-dessert",             "In that moment, <ORANGE>Tilly’s voice"),
    ("pm-treated-like-child",  "*I’m being treated like a child.*"),
    ("pm-gaps-in-sharing",     "“Are you sure? Gaps in sharing"),
    ("pm-leisure-regimen",     "“Your savings rate is right on target."),
    ("pm-paid-pitch",          "<ORANGE>[Jenny:] “You mean some advertiser"),
    ("pm-advertising-match",   "<GREEN>[Sai:]</GREEN> “<GREEN>That’s the point of advertising"),
    ("pm-sniffing-wifi",       "“Years ago, they caught"),
    ("pm-segregation",         "“<YELLOW>Centillion noticed"),
    ("pm-bits-not-him",        "<ORANGE>Collectively, the bits"),
    ("pm-so-what",             "Sai woke to Miles Davis"),
    ("pm-exhilarating",        "Getting to know Jenny was the oddest"),
    ("pm-frogs",               "<ORANGE>“I grew up in China,”"),
    ("pm-types",               "<ORANGE>“I never really thought of you as my type,”"),
    ("pm-champions",           "Sai woke to—what else?"),
    ("pm-cant-do-that",        "<YELLOW>[Sai:] “Tilly, call the police!”"),
    ("pm-white-tea",           "When the strange men had appeared"),
    ("pm-accelerometer",       "<ORANGE>[Rinn:] “It was his phone"),
    ("pm-just-like-us",        "“They know that there’s no way to hack"),
    ("pm-surprised-by-you",    "<ORANGE>“It’s not like that,” Jenny said."),
    ("pm-darkness",            "<GREEN>“We unveil only the darkness"),
    ("pm-neutral",             "<GREEN>[Rinn:]</GREEN> “<GREEN>There’s no such thing"),
    ("pm-cyborgs",             "“You see? <YELLOW>[Rinn:] Without Tilly"),
    ("pm-come-work",           "<GREEN>[Rinn:] “I want you to come and work"),
    ("pm-replace-us",          "“If we fail, who do you think will replace us?"),
    ("pm-cant-be-found",       "<GREEN>[Rinn:] “No one would believe you."),
    ("pm-adapt",               "<GREEN>“In the face of the inevitable"),
    ("pm-my-way",              "Sai closed the door of the apartment behind him."),
    ("pm-red-light",           "<GREEN>But a red light continued"),
]


def main(path):
    with open(path, encoding="utf-8") as f:
        lines = f.read().split("\n")

    problems, added, skipped = [], 0, 0
    for anchor, start in ANCHORS:
        tag = "[]{#" + anchor + "}"
        if any(tag in line for line in lines):
            skipped += 1
            continue
        hits = [i for i, line in enumerate(lines) if line.startswith(start)]
        if len(hits) != 1:
            problems.append(f"{anchor}: paragraph start found {len(hits)} times: {start}")
            continue
        lines[hits[0]] = tag + lines[hits[0]]
        added += 1

    if problems:
        print("No changes written. Fix these first:")
        print("\n".join("  " + p for p in problems))
        sys.exit(1)

    shutil.copyfile(path, path + ".bak")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    print(f"Added {added} anchors, {skipped} already present. Backup: {path}.bak")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    main(sys.argv[1])
