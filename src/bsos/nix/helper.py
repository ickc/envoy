#!/usr/bin/env python3

import json
import re
import subprocess
from collections import defaultdict
from pathlib import Path

import defopt
import pandas as pd
import yaml
import yamlloader


def get_executable_paths(
    nix_bin_dir: Path = Path("/run/current-system/sw/bin"),
) -> list[Path]:
    """Get realpath to executables in the nix bin directory."""
    return [path.readlink() for path in nix_bin_dir.iterdir()]


def get_package_install_name(name: str) -> str:
    """Get the package install name by looking it up in a dictionary."""
    return {
        "bash-interactive": "bashInteractive",
        "batdiff": "bat-extras.batdiff",
        "batgrep": "bat-extras.batgrep",
        "batman": "bat-extras.batman",
        "batpipe": "bat-extras.batpipe",
        "batwatch": "bat-extras.batwatch",
        "gcc-wrapper": "gcc14",
        "Image-ExifTool": "exiftool",
        "mpv-with-scripts": "mpv",
        "nixfmt-unstable": "nixfmt-rfc-style",
        "pam_reattach": "pam-reattach",
        "pandoc-cli": "pandoc",
        "patch": "gnupatch",
        "prettybat": "bat-extras.prettybat",
        "whisper-cpp": "openai-whisper-cpp",
    }.get(name, name)


def parse_nix_path(
    path: Path,
    version_regex: str = re.compile(
        r"^(?P<interpreter>(python|perl)[.0-9]+-)?(?P<package>.+?)(?P<version>-[-_.0-9p]+(pre)?)?(?P<date>\+date=[-0-9]+)?(?P<git>\+git[-0-9]+)?(?P<bin>-bin)?$"
    ),
) -> list[str | Path]:
    """Parse a nix path."""
    command = path.name
    parent = path.parent
    assert parent.name == "bin"
    parent = parent.parent
    name = parent.name
    assert parent.parent == Path("/nix/store")
    assert name[32] == "-"
    symbolink_name = name[33:]
    match = version_regex.match(symbolink_name)
    if not match:
        raise ValueError(f"Invalid format for: {symbolink_name}")
    groups = match.groupdict()

    interpreter = groups["interpreter"]
    package = groups["package"]
    version = groups["version"]
    date = groups["date"]
    git = groups["git"]
    is_bin = not groups["bin"]
    if interpreter:
        interpreter = interpreter[:-1]
    if version:
        version = version[1:]
    if date:
        date = date[6:]
    if git:
        git = git[5:]
    return [
        command,
        get_package_install_name(package),
        interpreter,
        package,
        version,
        date,
        git,
        is_bin,
        path,
    ]


def parse_nix_paths(
    nix_bin_dir: Path = Path("/run/current-system/sw/bin"),
) -> pd.DataFrame:
    paths = get_executable_paths(nix_bin_dir)
    df = pd.DataFrame(
        (parse_nix_path(path) for path in paths),
        columns=[
            "executable",
            "install",
            "interpreter",
            "package",
            "version",
            "date",
            "git",
            "is_bin",
            "path",
        ],
    )
    df.set_index("executable", inplace=True)
    return df


def get_package_descriptions() -> dict[str, str]:
    """Get a mapping of package names to their descriptions from nix."""
    try:
        result = subprocess.run(
            ["nix", "search", "--json", "nixpkgs", ".*"],
            capture_output=True,
            text=True,
            check=True,
        )
        packages = json.loads(result.stdout)
        descriptions = {}
        for _, pkg_info in packages.items():
            pname = pkg_info.get("pname")
            version = pkg_info.get("version")
            description = pkg_info.get("description", None)
            if pname and version and description:
                descriptions[pname] = description
        return descriptions
    except (subprocess.CalledProcessError, FileNotFoundError, json.JSONDecodeError) as e:
        print(f"Warning: Could not fetch package descriptions: {e}")
        return {}


def read_environment_systemPackages(
    path: Path = Path("flake.nix"),
) -> list[str]:
    """Read environment.systemPackages from flake.nix.

    Read the lines between these:

        with pkgs;
        [
        ...
        ];
    """
    with path.open("r", encoding="utf-8") as f:
        lines = f.readlines()
    # Find the indices of the lines to replace
    start_index = -1
    end_index = -1

    for i, line in enumerate(lines):
        if line.strip() == "with pkgs;":
            start_index = i + 2
        elif start_index != -1 and line.strip().startswith("]"):
            end_index = i
            break

    if start_index == -1 or end_index == -1:
        raise ValueError("Could not find the target lines in the file.")

    return [line.strip() for line in lines[start_index:end_index]]


def command2package(
    path: Path,
    *,
    nix_bin_dir: Path = Path("/run/current-system/sw/bin"),
) -> None:
    """Write the command to package mapping to a file."""
    df = parse_nix_paths(nix_bin_dir)
    df.to_csv(path)


def package2command(
    path: Path,
    *,
    flake_path: Path = Path("flake.nix"),
    nix_bin_dir: Path = Path("/run/current-system/sw/bin"),
) -> None:
    """Write the package to command mapping to a file."""
    packages = set(p.split("_")[0] for p in read_environment_systemPackages(flake_path))
    df = parse_nix_paths(nix_bin_dir)

    installed = set(df.install.tolist())
    excess = installed - packages
    if excess:
        print(f"Installed but not in {flake_path}:")
        for i in sorted(excess):
            print(f"\t{i}")
    no_bin = packages - installed
    if no_bin:
        print(f"Installed but not in {nix_bin_dir}:")
        for i in sorted(no_bin):
            print(f"\t{i}")

    descriptions = get_package_descriptions()
    res = defaultdict(lambda: {"command": []})
    for name, row in df.iterrows():
        res[row.install]["command"].append(name)

    # sort dict and its values
    sorted_res = {}
    for k, v in sorted(res.items()):
        temp = {
            "command": sorted(v["command"]),
        }
        desc = descriptions.get(k, None)
        if desc:
            temp["description"] = desc
        sorted_res[k] = temp
    res = sorted_res
    with path.open("w", encoding="utf-8") as f:
        yaml.dump(res, f, Dumper=yamlloader.ordereddict.CSafeDumper)


def cli() -> None:
    defopt.run([command2package, package2command])


if __name__ == "__main__":
    cli()
