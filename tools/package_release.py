#!/usr/bin/env python3
"""Build a self-contained FPGA Manager release ZIP from existing artifacts."""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import tempfile
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
PDF_RENDERER = ROOT / "tools" / "markdown_to_pdf.py"


def project_version() -> str:
    cmake = (ROOT / "CMakeLists.txt").read_text(encoding="utf-8")
    match = re.search(
        r"project\s*\(\s*fpga_mgr\s+VERSION\s+([0-9]+(?:\.[0-9]+){1,3})",
        cmake,
        re.IGNORECASE,
    )
    if match is None:
        raise SystemExit("could not determine fpga_mgr version from CMakeLists.txt")
    return match.group(1)


def add_data(archive: zipfile.ZipFile, data: bytes, name: str) -> None:
    entry = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
    entry.compress_type = zipfile.ZIP_DEFLATED
    entry.external_attr = 0o100644 << 16
    archive.writestr(entry, data, compresslevel=9)


def add_file(archive: zipfile.ZipFile, source: Path, name: str) -> None:
    if not source.is_file():
        raise SystemExit(f"missing release input: {source}")
    add_data(archive, source.read_bytes(), name)


def write_data_atomic(output: Path, data: bytes) -> None:
    with tempfile.NamedTemporaryFile(
        prefix=output.name + ".", suffix=".tmp", dir=output.parent, delete=False
    ) as temporary:
        temporary.write(data)
        temporary_path = Path(temporary.name)
    try:
        temporary_path.replace(output)
    finally:
        temporary_path.unlink(missing_ok=True)


def render_pdf(source: Path) -> bytes:
    with tempfile.NamedTemporaryFile(suffix=".pdf", delete=False) as temporary:
        temporary_path = Path(temporary.name)
    try:
        command = [
            os.environ.get("UV", "uv"),
            "run",
            str(PDF_RENDERER),
            str(source),
            str(temporary_path),
        ]
        try:
            subprocess.run(
                command,
                cwd=ROOT,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                check=True,
            )
        except FileNotFoundError as error:
            raise SystemExit(
                "uv is required to render the release PDFs with ReportLab"
            ) from error
        except subprocess.CalledProcessError as error:
            details = (error.stderr or error.stdout).strip()
            raise SystemExit(f"could not render {source} as PDF: {details}") from error
        data = temporary_path.read_bytes()
        if not data.startswith(b"%PDF-"):
            raise SystemExit(f"renderer did not produce a PDF for {source}")
        return data
    finally:
        temporary_path.unlink(missing_ok=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    build_dir = args.build_dir.resolve()
    version = project_version()
    output = args.output or build_dir / "release" / f"fpga-manager-{version}.zip"
    output = output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)

    release_readme = ROOT / "release" / "README.md"
    release_pdf = render_pdf(release_readme)

    files = (
        (build_dir / "fpga_mgr_B0C.uf2", "fpga_mgr_B0C.uf2"),
        (build_dir / "fpga_mgr_B0C.elf", "fpga_mgr_B0C.elf"),
        (build_dir / "fpga_mgr_B3B.uf2", "fpga_mgr_B3B.uf2"),
        (build_dir / "fpga_mgr_B3B.elf", "fpga_mgr_B3B.elf"),
        (ROOT / "k2" / "k2coremgr.pgz", "k2coremgr.pgz"),
        (ROOT / "LICENSE", "LICENSE"),
    )

    with tempfile.NamedTemporaryFile(
        prefix=output.name + ".", suffix=".tmp", dir=output.parent, delete=False
    ) as temporary:
        temporary_path = Path(temporary.name)

    try:
        with zipfile.ZipFile(temporary_path, "w") as archive:
            add_data(archive, release_pdf, "K2-FPGA-MANAGER.pdf")
            for source, name in files:
                add_file(archive, source, name)
        temporary_path.replace(output)
    finally:
        temporary_path.unlink(missing_ok=True)

    write_data_atomic(output.parent / "K2-FPGA-MANAGER.pdf", release_pdf)

    print(output)


if __name__ == "__main__":
    main()
