#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11"
# dependencies = ["reportlab==5.0.0"]
# ///
"""Render the release Markdown subset in the established Wildbits PDF style."""

from __future__ import annotations

import argparse
import html
from io import BytesIO
import json
import re
import subprocess
import tempfile
from pathlib import Path

from reportlab import rl_config
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import (
    Image,
    PageBreak,
    Paragraph,
    Preformatted,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)


rl_config.invariant = 1
rl_config.useA85 = 0

PAGE_WIDTH = A4[0] - 36 * mm
ACCENT = colors.HexColor("#245a78")
INK = colors.HexColor("#202631")
MUTED = colors.HexColor("#667085")
RULE = colors.HexColor("#d4d9df")
MERMAID_CLI_PACKAGE = "@mermaid-js/mermaid-cli@11.16.0"
PUPPETEER_PACKAGE = "puppeteer@25.9.0"


def styles() -> dict[str, ParagraphStyle]:
    base = getSampleStyleSheet()
    return {
        "title": ParagraphStyle(
            "ReleaseTitle",
            parent=base["Title"],
            fontName="Helvetica-Bold",
            fontSize=22,
            leading=27,
            textColor=colors.HexColor("#14213d"),
            spaceAfter=6 * mm,
        ),
        "h1": ParagraphStyle(
            "ReleaseH1",
            parent=base["Heading1"],
            fontName="Helvetica-Bold",
            fontSize=15.5,
            leading=18,
            textColor=ACCENT,
            spaceBefore=3.5 * mm,
            spaceAfter=2 * mm,
            keepWithNext=True,
        ),
        "h2": ParagraphStyle(
            "ReleaseH2",
            parent=base["Heading2"],
            fontName="Helvetica-Bold",
            fontSize=12.2,
            leading=15,
            textColor=colors.HexColor("#27364b"),
            spaceBefore=3.5 * mm,
            spaceAfter=1.7 * mm,
            keepWithNext=True,
        ),
        "body": ParagraphStyle(
            "ReleaseBody",
            parent=base["BodyText"],
            fontName="Helvetica",
            fontSize=9.5,
            leading=13.2,
            textColor=INK,
            spaceAfter=2 * mm,
        ),
        "bullet": ParagraphStyle(
            "ReleaseBullet",
            parent=base["BodyText"],
            fontName="Helvetica",
            fontSize=9.5,
            leading=13.7,
            leftIndent=5 * mm,
            firstLineIndent=-3 * mm,
            bulletIndent=1 * mm,
            textColor=INK,
            spaceAfter=1.3 * mm,
        ),
        "definition": ParagraphStyle(
            "ReleaseDefinition",
            parent=base["BodyText"],
            fontName="Helvetica-Oblique",
            fontSize=9,
            leading=13,
            leftIndent=4 * mm,
            textColor=colors.HexColor("#4b5565"),
            spaceAfter=2.5 * mm,
        ),
        "cell": ParagraphStyle(
            "ReleaseCell",
            parent=base["BodyText"],
            fontName="Helvetica",
            fontSize=8.1,
            leading=10.3,
            textColor=INK,
        ),
        "cell_head": ParagraphStyle(
            "ReleaseCellHead",
            parent=base["BodyText"],
            fontName="Helvetica-Bold",
            fontSize=8.1,
            leading=10.3,
            textColor=colors.HexColor("#14213d"),
        ),
        "code": ParagraphStyle(
            "ReleaseCode",
            parent=base["Code"],
            fontName="Courier",
            fontSize=7.4,
            leading=9.5,
            backColor=colors.HexColor("#f6f8fa"),
            borderColor=RULE,
            borderWidth=0.4,
            borderPadding=5,
        ),
        "rule": ParagraphStyle(
            "ReleaseRule",
            parent=base["BodyText"],
            alignment=TA_CENTER,
            textColor=RULE,
            spaceBefore=2 * mm,
            spaceAfter=2 * mm,
        ),
    }


STYLES = styles()


def render_mermaid(source: str):
    """Render one inline Mermaid definition as a scalable ReportLab drawing."""

    config = {
        "theme": "base",
        "flowchart": {
            "curve": "basis",
            "htmlLabels": False,
            "nodeSpacing": 28,
            "rankSpacing": 36,
            "useMaxWidth": False,
        },
        "themeVariables": {
            "background": "#f8fafc",
            "fontFamily": "Helvetica, Arial, sans-serif",
            "fontSize": "13px",
            "lineColor": "#53687a",
            "primaryColor": "#e8f0f5",
            "primaryBorderColor": "#245a78",
            "primaryTextColor": "#14213d",
            "clusterBkg": "#f8fafc",
            "clusterBorder": "#d4d9df",
            "edgeLabelBackground": "#f8fafc",
            "tertiaryColor": "#f1f3f5",
        },
    }

    with tempfile.TemporaryDirectory(prefix="k2-mermaid-") as temporary:
        directory = Path(temporary)
        source_path = directory / "diagram.mmd"
        config_path = directory / "config.json"
        output_path = directory / "diagram.png"
        source_path.write_text(source, encoding="utf-8")
        config_path.write_text(json.dumps(config), encoding="utf-8")
        command = [
            "npx",
            "--yes",
            "--package",
            MERMAID_CLI_PACKAGE,
            "--package",
            PUPPETEER_PACKAGE,
            "mmdc",
            "--input",
            str(source_path),
            "--output",
            str(output_path),
            "--configFile",
            str(config_path),
            "--backgroundColor",
            "transparent",
            "--scale",
            "3",
        ]
        try:
            result = subprocess.run(
                command,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
            )
        except FileNotFoundError as error:
            raise RuntimeError(
                "Node.js/npm is required to render inline Mermaid diagrams"
            ) from error

        details = (result.stderr or result.stdout).strip()
        if result.returncode and "Could not find chrome-headless-shell" in details:
            install = subprocess.run(
                [
                    "npx",
                    "--yes",
                    PUPPETEER_PACKAGE,
                    "browsers",
                    "install",
                    "chrome-headless-shell",
                ],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
            )
            if install.returncode:
                install_details = (install.stderr or install.stdout).strip()
                raise RuntimeError(
                    "could not install Mermaid's headless browser: "
                    f"{install_details}"
                )
            result = subprocess.run(
                command,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
            )
            details = (result.stderr or result.stdout).strip()
        if result.returncode:
            raise RuntimeError(f"could not render Mermaid diagram: {details}")

        image = Image(BytesIO(output_path.read_bytes()))

    maximum_height = 82 * mm
    scale = min(PAGE_WIDTH / image.drawWidth, maximum_height / image.drawHeight)
    image.drawWidth *= scale
    image.drawHeight *= scale
    image.hAlign = "CENTER"
    return image


def inline_markup(text: str) -> str:
    """Escape text, retain basic emphasis/code, and deliberately strip links."""

    text = re.sub(r"\[([^]]+)]\([^)]+\)", r"\1", text)
    code: list[str] = []

    def save_code(match: re.Match[str]) -> str:
        code.append(html.escape(match.group(1)))
        return f"@@CODE{len(code) - 1}@@"

    text = re.sub(r"`([^`]+)`", save_code, text)
    text = html.escape(text)
    text = re.sub(r"\*\*([^*]+)\*\*", r"<b>\1</b>", text)
    for index, value in enumerate(code):
        text = text.replace(
            f"@@CODE{index}@@", f'<font name="Courier">{value}</font>'
        )
    return text


def table_cells(line: str) -> list[str]:
    return [cell.strip() for cell in line.strip().strip("|").split("|")]


def is_table_separator(line: str) -> bool:
    cells = table_cells(line)
    return bool(cells) and all(re.fullmatch(r":?-{2,}:?", cell) for cell in cells)


def is_block_start(lines: list[str], index: int) -> bool:
    line = lines[index].rstrip()
    if not line:
        return True
    if line.startswith(("#", "- ", ":", "```")) or line in (
        "---",
        "<!-- pagebreak -->",
    ):
        return True
    if re.match(r"^\d+\.\s+", line):
        return True
    return (
        line.startswith("|")
        and index + 1 < len(lines)
        and is_table_separator(lines[index + 1])
    )


def parse_markdown(source: Path) -> list[object]:
    # splitlines() deliberately retains trailing spaces so Markdown's explicit
    # two-space line breaks can be preserved.
    lines = source.read_text(encoding="utf-8").splitlines()
    story: list[object] = []
    index = 0

    while index < len(lines):
        raw_line = lines[index]
        line = raw_line.rstrip()
        if not line:
            index += 1
            continue

        if line.startswith("```"):
            language = line[3:].strip().lower()
            index += 1
            code: list[str] = []
            while index < len(lines) and not lines[index].startswith("```"):
                code.append(lines[index])
                index += 1
            if index == len(lines):
                raise ValueError(f"{source}: unterminated code block")
            if language == "mermaid":
                story.extend(
                    (render_mermaid("\n".join(code)), Spacer(1, 2.5 * mm))
                )
            else:
                story.append(
                    Preformatted(
                        "\n".join(code), STYLES["code"], maxLineLength=100
                    )
                )
            index += 1
            continue

        if line == "<!-- pagebreak -->":
            story.append(PageBreak())
            index += 1
            continue

        heading = re.match(r"^(#{1,4})\s+(.+)$", line)
        if heading:
            level = len(heading.group(1))
            style = "title" if level == 1 else "h1" if level == 2 else "h2"
            if level == 1 and story:
                story.append(PageBreak())
            story.append(Paragraph(inline_markup(heading.group(2)), STYLES[style]))
            index += 1
            continue

        if line == "---":
            story.append(Paragraph("- - -", STYLES["rule"]))
            index += 1
            continue

        if (
            line.startswith("|")
            and index + 1 < len(lines)
            and is_table_separator(lines[index + 1])
        ):
            rows = [table_cells(line)]
            index += 2
            while index < len(lines) and lines[index].startswith("|"):
                rows.append(table_cells(lines[index]))
                index += 1
            columns = len(rows[0])
            if any(len(row) != columns for row in rows):
                raise ValueError(f"{source}: inconsistent Markdown table")
            data = [
                [
                    Paragraph(
                        inline_markup(cell),
                        STYLES["cell_head" if row == 0 else "cell"],
                    )
                    for cell in values
                ]
                for row, values in enumerate(rows)
            ]
            table = Table(
                data, colWidths=[PAGE_WIDTH / columns] * columns, repeatRows=1
            )
            table.setStyle(
                TableStyle(
                    [
                        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#e8f0f5")),
                        ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#b8c5cf")),
                        ("VALIGN", (0, 0), (-1, -1), "TOP"),
                        ("LEFTPADDING", (0, 0), (-1, -1), 5),
                        ("RIGHTPADDING", (0, 0), (-1, -1), 5),
                        ("TOPPADDING", (0, 0), (-1, -1), 4),
                        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
                    ]
                )
            )
            story.extend((table, Spacer(1, 2.5 * mm)))
            continue

        if line.startswith("- "):
            parts = [line[2:].strip()]
            index += 1
            while index < len(lines) and lines[index].startswith("  "):
                parts.append(lines[index].strip())
                index += 1
            story.append(
                Paragraph(
                    inline_markup(" ".join(parts)), STYLES["bullet"], bulletText="-"
                )
            )
            continue

        ordered_item = re.match(r"^(\d+)\.\s+(.+)$", line)
        if ordered_item:
            parts = [ordered_item.group(2).strip()]
            index += 1
            while index < len(lines) and lines[index].startswith("  "):
                parts.append(lines[index].strip())
                index += 1
            story.append(
                Paragraph(
                    inline_markup(" ".join(parts)),
                    STYLES["bullet"],
                    bulletText=f"{ordered_item.group(1)}.",
                )
            )
            continue

        if line.startswith(":"):
            parts = [line[1:].strip()]
            index += 1
            while index < len(lines) and lines[index].startswith("  "):
                parts.append(lines[index].strip())
                index += 1
            story.append(
                Paragraph(inline_markup(" ".join(parts)), STYLES["definition"])
            )
            continue

        paragraph = [raw_line]
        index += 1
        while index < len(lines) and not is_block_start(lines, index):
            paragraph.append(lines[index])
            index += 1
        joined = ""
        for part_index, part in enumerate(paragraph):
            joined += part.strip()
            if part_index + 1 < len(paragraph):
                joined += "@@HARD_BREAK@@" if part.endswith("  ") else " "
        markup = inline_markup(joined).replace("@@HARD_BREAK@@", "<br/>")
        story.append(Paragraph(markup, STYLES["body"]))

    if not story:
        raise ValueError(f"{source}: document is empty")
    return story


def footer(canvas, document, label: str) -> None:
    canvas.saveState()
    canvas.setStrokeColor(RULE)
    canvas.line(18 * mm, 15 * mm, 192 * mm, 15 * mm)
    canvas.setFont("Helvetica", 8)
    canvas.setFillColor(MUTED)
    canvas.drawString(18 * mm, 10.5 * mm, label)
    canvas.drawRightString(192 * mm, 10.5 * mm, f"Page {document.page}")
    canvas.restoreState()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check-only", action="store_true")
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path, nargs="?")
    args = parser.parse_args()

    story = parse_markdown(args.source)
    if args.check_only:
        print(f"Checked {args.source}: {len(story)} document blocks")
        return
    if args.output is None:
        parser.error("output is required unless --check-only is used")

    title = args.source.stem.replace("_", " ")
    document_label = "Wildbits/K2 FPGA Manager documentation"
    document = SimpleDocTemplate(
        str(args.output),
        pagesize=A4,
        rightMargin=18 * mm,
        leftMargin=18 * mm,
        topMargin=14 * mm,
        bottomMargin=18 * mm,
        title=title,
        author="Wildbits Computing",
        subject=document_label,
        pageCompression=1,
    )

    def page_footer(canvas, page_document) -> None:
        footer(canvas, page_document, document_label)

    document.build(story, onFirstPage=page_footer, onLaterPages=page_footer)
    print(f"Rendered {args.output}")


if __name__ == "__main__":
    main()
