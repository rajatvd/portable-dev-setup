#!/usr/bin/env python3
"""Assert that a release bundle contains only canonical archive metadata."""

import os
import sys
import tarfile
from pathlib import Path
from typing import NoReturn


def fail(message: str) -> NoReturn:
    raise SystemExit(f"BUNDLE METADATA PROOF FAILED: {message}")


def main() -> None:
    if len(sys.argv) != 4:
        fail("usage: verify-bundle-metadata.py ARCHIVE PACKAGE EPOCH")

    archive_path = Path(sys.argv[1])
    package = sys.argv[2]
    try:
        epoch = int(sys.argv[3])
    except ValueError:
        fail(f"invalid epoch: {sys.argv[3]}")

    with archive_path.open("rb") as archive_file:
        gzip_header = archive_file.read(10)
    if len(gzip_header) != 10 or gzip_header[:3] != b"\x1f\x8b\x08":
        fail("archive does not have a gzip header")
    if gzip_header[3] != 0:
        fail("gzip header contains optional filename, comment, or extra fields")
    if int.from_bytes(gzip_header[4:8], "little") != epoch:
        fail("gzip timestamp does not match the source commit epoch")
    if gzip_header[9] != 255:
        fail("gzip OS field is not the platform-neutral value 255")

    with tarfile.open(archive_path, "r:gz") as archive:
        members = archive.getmembers()

    if not members or members[0].name != package or not members[0].isdir():
        fail("archive does not begin with the package root directory")

    names = [member.name for member in members]
    if names != sorted(names, key=os.fsencode):
        fail("archive members are not bytewise name-sorted")

    for member in members:
        if member.mtime != epoch:
            fail(f"noncanonical timestamp: {member.name}")
        if member.uid != 0 or member.gid != 0 or member.uname or member.gname:
            fail(f"noncanonical ownership: {member.name}")
        if member.pax_headers:
            fail(f"extended archive metadata is present: {member.name}")
        if member.isdir():
            expected_mode = 0o755
        elif member.issym():
            expected_mode = 0o777
        elif member.isreg():
            expected_mode = 0o755 if member.mode & 0o111 else 0o644
        else:
            fail(f"unsupported archive member type: {member.name}")
        if member.mode != expected_mode:
            fail(f"noncanonical mode: {member.name}")

    print(f"Verified canonical metadata for {len(members)} archive members.")


if __name__ == "__main__":
    main()
