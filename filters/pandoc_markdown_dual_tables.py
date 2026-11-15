#!/usr/bin/env python3
import argparse
import html
import re
import sys


def splitRow(line):
    line = line.strip()
    if line.startswith("|"):
        line = line[1:]
    if line.endswith("|"):
        line = line[:-1]
    return [cell.strip() for cell in line.split("|")]


def isSeparator(line):
    cells = splitRow(line)
    return bool(cells) and all(
        re.fullmatch(r":?-{3,}:?", cell.replace(" ", "")) for cell in cells
    )


def latexEscape(text):
    replacements = {
        "\\": r"\textbackslash{}",
        "&": r"\&",
        "%": r"\%",
        "$": r"\$",
        "#": r"\#",
        "_": r"\_",
        "{": r"\{",
        "}": r"\}",
        "~": r"\textasciitilde{}",
        "^": r"\textasciicircum{}",
    }
    return "".join(replacements.get(char, char) for char in text)


def htmlCell(text):
    parts = re.split(r"<br\s*/?>", text, flags=re.IGNORECASE)
    return "<br>".join(html.escape(part) for part in parts)


def latexCell(text):
    parts = re.split(r"<br\s*/?>", text, flags=re.IGNORECASE)
    escapedParts = [latexEscape(part) for part in parts]

    if len(escapedParts) == 1:
        return escapedParts[0]

    return r"{\renewcommand{\arraystretch}{1.0}\begin{tabular}[t]{@{}l@{}}" + r" \\ ".join(escapedParts) + r"\end{tabular}}"


def convertTable(lines, rowPadding, verticalLines):
    header = splitRow(lines[0])
    body = [splitRow(line) for line in lines[2:]]
    width = len(header)

    rows = [header]
    for row in body:
        row = row[:width] + [""] * max(0, width - len(row))
        rows.append(row)

    htmlRows = [
        "<tr>"
        + "".join(f'<th style="vertical-align: top;">{htmlCell(cell)}</th>' for cell in rows[0])
        + "</tr>"
    ]

    for row in rows[1:]:
        htmlRows.append(
            "<tr>"
            + "".join(f'<td style="vertical-align: top;">{htmlCell(cell)}</td>' for cell in row)
            + "</tr>"
        )

    if verticalLines:
        latexColumns = "|" + "|".join("l" for _ in range(width)) + "|"
    else:
        latexColumns = "l" * width

    latexRows = [
        " & ".join(latexCell(cell) for cell in row) + r" \\ \hline"
        for row in rows
    ]

    return (
        "```{=html}\n"
        "<table>\n"
        + "\n".join(htmlRows)
        + "\n</table>\n"
        "```\n\n"
        "```{=latex}\n"
        + f"\\renewcommand{{\\arraystretch}}{{{rowPadding}}}\n"
        + f"\\begin{{tabular}}{{{latexColumns}}}\n"
        + "\\hline\n"
        + "\n".join(latexRows)
        + "\n\\end{tabular}\n"
        "```"
    )


def main():
    parser = argparse.ArgumentParser(
        description="Convert Markdown pipe tables to HTML and LaTeX blocks."
    )
    parser.add_argument(
        "--row-padding",
        type=float,
        default=2.5,
        help="LaTeX row-height multiplier (default: 2.5). Use 1.0 for normal height.",
    )
    parser.add_argument(
        "--no-vertical-lines",
        action="store_true",
        help="Turn off vertical lines in the LaTeX table.",
    )
    args = parser.parse_args()

    if args.row_padding <= 0:
        parser.error("--row-padding must be greater than zero")

    lines = sys.stdin.read().splitlines()
    output = []
    i = 0

    while i < len(lines):
        if i + 1 < len(lines) and "|" in lines[i] and isSeparator(lines[i + 1]):
            tableLines = [lines[i], lines[i + 1]]
            i += 2

            while i < len(lines) and "|" in lines[i] and lines[i].strip():
                tableLines.append(lines[i])
                i += 1

            output.append(
                convertTable(
                    tableLines,
                    args.row_padding,
                    not args.no_vertical_lines,
                )
            )
        else:
            output.append(lines[i])
            i += 1

    print("\n".join(output))


if __name__ == "__main__":
    main()
