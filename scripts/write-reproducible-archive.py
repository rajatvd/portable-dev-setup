#!/usr/bin/env python3
"""Write one directory as a canonical USTAR archive inside canonical gzip."""

import gzip
import os
import stat
import sys
import tarfile
from pathlib import Path
from typing import NoReturn


def fail(message: str) -> NoReturn:
    raise SystemExit(f"archive error: {message}")


def ordered_paths(root: Path) -> list[Path]:
    paths = [root]

    def visit(directory: Path) -> None:
        with os.scandir(directory) as entries:
            children = list(entries)
        for child in children:
            path = Path(child.path)
            paths.append(path)
            if child.is_dir(follow_symlinks=False):
                visit(path)

    visit(root)
    return sorted(
        paths,
        key=lambda path: os.fsencode(path.relative_to(root.parent).as_posix()),
    )


def archive_info(path: Path, archive_name: str, epoch: int) -> tarfile.TarInfo:
    metadata = path.lstat()
    info = tarfile.TarInfo(archive_name)
    info.mtime = epoch
    info.uid = 0
    info.gid = 0
    info.uname = ""
    info.gname = ""

    if stat.S_ISDIR(metadata.st_mode):
        info.type = tarfile.DIRTYPE
        info.mode = 0o755
    elif stat.S_ISLNK(metadata.st_mode):
        info.type = tarfile.SYMTYPE
        info.mode = 0o777
        info.linkname = os.readlink(path)
    elif stat.S_ISREG(metadata.st_mode):
        info.type = tarfile.REGTYPE
        info.mode = 0o755 if metadata.st_mode & 0o111 else 0o644
        info.size = metadata.st_size
    else:
        fail(f"unsupported file type: {path}")

    return info


def write_archive(source: Path, destination: Path, epoch: int) -> None:
    paths = ordered_paths(source)
    with destination.open("wb") as raw_archive:
        with gzip.GzipFile(
            filename="",
            mode="wb",
            compresslevel=9,
            fileobj=raw_archive,
            mtime=epoch,
        ) as compressed_archive:
            with tarfile.open(
                fileobj=compressed_archive,
                mode="w|",
                format=tarfile.USTAR_FORMAT,
            ) as archive:
                for path in paths:
                    archive_name = path.relative_to(source.parent).as_posix()
                    info = archive_info(path, archive_name, epoch)
                    if info.isreg():
                        with path.open("rb") as contents:
                            archive.addfile(info, contents)
                    else:
                        archive.addfile(info)


def main() -> None:
    if len(sys.argv) != 4:
        fail("usage: write-reproducible-archive.py SOURCE DESTINATION EPOCH")

    source = Path(sys.argv[1])
    destination = Path(sys.argv[2])
    try:
        epoch = int(sys.argv[3])
    except ValueError:
        fail(f"invalid epoch: {sys.argv[3]}")

    if not source.is_dir():
        fail(f"source is not a directory: {source}")
    if not 0 <= epoch <= 0xFFFFFFFF:
        fail(f"epoch is outside the gzip timestamp range: {epoch}")

    write_archive(source, destination, epoch)


if __name__ == "__main__":
    main()
