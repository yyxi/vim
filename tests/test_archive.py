"""Packaging boundaries and deterministic transport of ordinary state."""

import io
import os
from pathlib import Path
import tarfile
import tempfile
from unittest.mock import patch

from archive_headers import inspect_headers
from support import FixtureTestCase, manage


class ArchiveTests(FixtureTestCase):
    def setUp(self):
        super().setUp()
        self.outputs = tempfile.TemporaryDirectory(prefix="manage-archive-test-")
        self.addCleanup(self.outputs.cleanup)
        self.destination = Path(self.outputs.name)

    def write(self, selected, name="state.tar.gz"):
        return manage.write_state_archive(
            str(self.root), str(self.destination / name), selected, {}
        )

    def test_normalized_headers_and_same_input_bytes(self):
        directory = self.root / "node_modules/pkg"
        directory.mkdir(parents=True)
        file = directory / "entry.js"
        file.write_text("module.exports = {};")
        file.chmod(0o711)
        link = self.root / "node_modules/provider"
        link.symlink_to("pkg/entry.js")
        selected = {
            "node_modules": str(directory.parent),
            "node_modules/pkg": str(directory),
            "node_modules/pkg/entry.js": str(file),
            "node_modules/provider": str(link),
        }
        self.assertTrue(self.write(selected, "first.tar.gz"))
        os.utime(file, (42, 42))
        self.assertTrue(self.write(selected, "second.tar.gz"))
        self.assertEqual(
            (self.destination / "first.tar.gz").read_bytes(),
            (self.destination / "second.tar.gz").read_bytes(),
        )
        with tarfile.open(self.destination / "first.tar.gz") as archive:
            self.assertEqual(archive.getnames(), sorted(selected))
            for member in archive:
                self.assertEqual(
                    (member.uid, member.gid, member.mtime, member.uname, member.gname),
                    (0, 0, 0, "", ""),
                )
                self.assertFalse(member.islnk())
            self.assertEqual(archive.getmember("node_modules/pkg/entry.js").mode, 0o755)
            self.assertEqual(
                archive.getmember("node_modules/provider").linkname, "pkg/entry.js"
            )

    def test_invalid_members_do_not_publish(self):
        file = self.root / "file"
        file.write_text("contents")
        for name in ("../escape", "/absolute", "C:/drive", "node_modules/../collision"):
            with self.subTest(name=name):
                self.assertFalse(self.write({name: str(file)}))
                self.assertFalse((self.destination / "state.tar.gz").exists())
        file.chmod(0o4755)
        self.assertFalse(self.write({"vendor/file": str(file)}))
        file.chmod(0o644)
        pipe = self.root / "pipe"
        os.mkfifo(pipe)
        self.assertFalse(self.write({"vendor/pipe": str(pipe)}))

    def test_node_links_cannot_leave_component_even_to_selected_file(self):
        directory = self.root / "node_modules"
        directory.mkdir()
        file = self.root / "outside"
        file.write_text("contents")
        link = directory / "link"
        link.symlink_to("../outside")
        self.assertFalse(
            self.write({"node_modules/link": str(link), "outside": str(file)})
        )
        link.unlink()
        link.symlink_to(file)
        self.assertFalse(
            self.write({"node_modules/link": str(link), "outside": str(file)})
        )

    def test_independent_header_controls(self):
        manifest = Path(__file__).resolve().parents[1] / "source-manifest.json"
        (self.root / "source-manifest.json").write_bytes(manifest.read_bytes())
        (self.root / "manage").write_bytes((manifest.parent / "manage").read_bytes())
        cases = [
            [("../escape", tarfile.REGTYPE, "", 0o644)],
            [(".git/config", tarfile.REGTYPE, "", 0o644)],
            [("vendor/plugins/file", tarfile.REGTYPE, "", 0o644)],
            [("node_modules/file", tarfile.REGTYPE, "", 0o644)] * 2,
            [("node_modules/link", tarfile.SYMTYPE, "../../escape", 0o777)],
            [("node_modules/link", tarfile.LNKTYPE, "node_modules/file", 0o644)],
            [("node_modules/file", tarfile.REGTYPE, "", 0o4755)],
            [("node_modules/pipe", tarfile.FIFOTYPE, "", 0o644)],
            [
                ("node_modules/parent", tarfile.SYMTYPE, "target", 0o777),
                ("node_modules/parent/file", tarfile.REGTYPE, "", 0o644),
                ("node_modules/target", tarfile.DIRTYPE, "", 0o755),
            ],
        ]
        for index, members in enumerate(cases):
            archive = self.destination / f"negative-{index}.tar.gz"
            with tarfile.open(archive, "w:gz") as output:
                for name, kind, target, mode in members:
                    entry = tarfile.TarInfo(name)
                    entry.type, entry.linkname, entry.mode = kind, target, mode
                    entry.size = 1 if kind == tarfile.REGTYPE else 0
                    output.addfile(entry, io.BytesIO(b"x") if entry.size else None)
            with self.subTest(members=members), self.assertRaises(RuntimeError):
                inspect_headers(archive, self.root)

    def test_checksum_failure_does_not_publish(self):
        file = self.root / "file"
        file.write_text("contents")
        with patch.object(manage, "sha256_file", return_value=None):
            self.assertFalse(self.write({"vendor/file": str(file)}))
        self.assertEqual(list(self.destination.iterdir()), [])

    def test_home_lookup_failure_returns_operational_error(self):
        output = self.destination / "state.tar.gz"
        with patch.object(manage, "home_dir", side_effect=RuntimeError("HOME")):
            self.assertEqual(manage.export_archive(str(output)), 1)
        self.assertFalse(output.exists())

    def test_existing_output_is_never_replaced(self):
        output = self.destination / "state.tar.gz"
        output.write_text("original")
        self.assertFalse(self.write({}))
        self.assertEqual(output.read_text(), "original")
        self.assertFalse(
            manage.write_state_archive(
                str(self.root), str(self.root / "state.tar.gz"), {}, {}
            )
        )
