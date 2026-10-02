#!/usr/bin/env python3
"""Smoke-test a prepared release in a fresh clone, not a compatibility lab."""

import argparse
import os
from pathlib import Path
import subprocess
import tempfile

from archive_headers import inspect_headers


def smoke(repository, archive, python):
    env = dict(os.environ, GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_NOSYSTEM="1")
    revision = subprocess.check_output(
        ["git", "-C", str(repository), "rev-parse", "HEAD"], env=env, text=True
    ).strip()
    with tempfile.TemporaryDirectory(prefix="nvim release smoke ") as temporary:
        root = Path(temporary)
        clone = root / "clone"
        subprocess.run(
            [
                "git",
                "clone",
                "--no-local",
                "--no-checkout",
                str(repository),
                str(clone),
            ],
            env=env,
            check=True,
        )
        subprocess.run(
            ["git", "-C", str(clone), "checkout", "--detach", revision],
            env=env,
            check=True,
        )
        inspect_headers(archive, clone)
        subprocess.run(["tar", "-xzf", str(archive), "-C", str(clone)], check=True)
        home = root / "home"
        home.mkdir()
        env.update(
            HOME=str(home),
            XDG_CONFIG_HOME=str(home / ".config"),
            XDG_CACHE_HOME=str(root / "cache"),
            XDG_DATA_HOME=str(root / "data"),
            XDG_STATE_HOME=str(root / "state"),
        )
        subprocess.run(
            [str(python), str(clone / "manage"), "install", "--offline"],
            cwd=root,
            env=env,
            check=True,
            timeout=180,
        )
        subprocess.run(
            [
                "nvim",
                "--clean",
                "--headless",
                "-l",
                str(Path(__file__).with_name("startup.lua")),
                str(clone),
            ],
            cwd=root,
            env=env,
            check=True,
            timeout=60,
        )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repository", type=Path, required=True)
    parser.add_argument("--archive", type=Path, required=True)
    parser.add_argument("--python", type=Path, required=True)
    args = parser.parse_args()
    smoke(
        args.repository.resolve(strict=True),
        args.archive.resolve(strict=True),
        args.python.resolve(strict=True),
    )


if __name__ == "__main__":
    main()
