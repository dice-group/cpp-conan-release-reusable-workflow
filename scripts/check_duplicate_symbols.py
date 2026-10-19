"""This script checks whether any of the linked libraries define global symbols with the same name.

Usage: check_duplicate_symbols.py < cargo build --message-format=json-render-diagnostics

When we link two libraries that each export global symbols with the same name then depending on the link order we might
silently use one or the other which can cause errors as whatever function is behind the symbol might be radically different.

We don't report C++ allocation functions, which are often replaced on purpose (by e.g. mimalloc).
Libraries that are neither in the search dirs of their crate nor in the -L dirs of RUSTFLAGS (system libraries like
libstdc++ on glibc) and symbols of rust crates themselves, e.g. #[no_mangle] functions, are not checked.
RUSTFLAGS is read from the environment, so run the script with the RUSTFLAGS of the build.
"""

import itertools
import json
import os
import re
import subprocess
import sys
from collections import defaultdict
from pathlib import Path

# operator new, new[], delete, delete[] and std::get_new_handler
REPLACEABLE = re.compile(r"_Z(nw|na|dl|da).*|_ZSt15get_new_handlerv")

MACOS = sys.platform == "darwin"


def defined_globals(archive):
    """Map of the global symbols an archive defines to whether any definition of it is non-weak"""
    # The posix format shows weak Mach-O definitions as T like any other definition, only the darwin format tells them apart
    nm_format = "--format=darwin" if MACOS else "--format=posix"
    nm = subprocess.run(["nm", nm_format, "--no-sort", "--defined-only", "--extern-only", archive],
                        check=True, capture_output=True, text=True)
    errors = [line for line in nm.stderr.splitlines() if not line.endswith(": no symbols")]
    if errors:
        raise SystemExit(f"nm could not read {archive}:\n" + "\n".join(errors))
    symbols = defaultdict(bool)
    for line in nm.stdout.splitlines():
        if line and not line.endswith(":"):  # skip the "archive[member.o]:" headers
            fields = line.split()
            if MACOS:
                # "address (segment,section) [weak] [private] external [attributes] name". Mach-O prefixes all names
                # with an underscore, without it they are the names on Linux, which REPLACEABLE expects.
                name, strong = fields[-1].removeprefix("_"), "weak" not in fields[:-1]
            else:
                name, strong = fields[0], fields[1] not in "WVu"  # the nm types of weak definitions
            symbols[name] |= strong
    return symbols


def rustflags_search_dirs():
    """The -L dirs in RUSTFLAGS, setup-macos-env.sh e.g. makes libstdc++.a and libgcc.a available through them"""
    return [Path(path.split("=", 1)[-1]) for path in re.findall(r"(?:^|\s)-L\s*(\S+)", os.environ.get("RUSTFLAGS", ""))]


def main():
    messages = [json.loads(line) for line in sys.stdin]
    if not any(m["reason"] == "build-finished" and m["success"] for m in messages):
        raise SystemExit("Input does not contain a successful build, pass the json output of cargo build")

    libraries = {}  # (crate, file name) -> path. A crate that is a build dependency too is built twice.
    unchecked = []
    rustflags_dirs = rustflags_search_dirs()
    for message in (m for m in messages if m["reason"] == "build-script-executed"):
        crate = message["package_id"]
        search_dirs = [Path(path.split("=", 1)[-1]) for path in message["linked_paths"]] + rustflags_dirs
        for lib in message["linked_libs"]:
            kind, _, name = lib.rpartition("=")
            if kind.partition(":")[0] not in ("static", ""):  # without a kind, a static lib if one exists
                continue
            file_name = f"lib{name}.a"
            paths = [d / file_name for d in search_dirs if (d / file_name).is_file()]
            if paths:
                libraries.setdefault((crate, file_name), paths[0].resolve())
            else:
                unchecked.append(f"{file_name} ({crate})")

    archives = {path: crate for (crate, _), path in libraries.items()}
    if not archives:
        raise SystemExit("No static libraries found")
    if unchecked:
        print(f"Not in the search dirs of their crate or RUSTFLAGS, assuming system libraries: {', '.join(sorted(set(unchecked)))}")

    definitions = defaultdict(list)  # symbol -> [(archive, non-weak)]
    for archive in archives:
        for name, strong in defined_globals(archive).items():
            definitions[name].append((archive, strong))

    duplicates = defaultdict(list)  # (archive, archive) -> symbols
    for name, defs in definitions.items():
        if REPLACEABLE.fullmatch(name):
            continue
        for (a, a_strong), (b, b_strong) in itertools.combinations(defs, 2):
            # one non-weak definition is enough across crates, within a crate it takes two
            if (a_strong and b_strong) or ((a_strong or b_strong) and archives[a] != archives[b]):
                duplicates[a, b].append(name)

    print(f"Checked {len(definitions)} global symbols in {len(archives)} static libraries")
    for (a, b), names in sorted(duplicates.items()):
        print(f"::error title=Duplicate symbols::{len(names)} symbols are defined in both {a} ({archives[a]}) and {b} ({archives[b]})")
        print("\n".join(f"    {name}" for name in sorted(names)[:20]))
        if len(names) > 20:
            print(f"    ... and {len(names) - 20} more")
    sys.exit(1 if duplicates else 0)


if __name__ == "__main__":
    main()
