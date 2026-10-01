"""Behavioral tests for the standalone CLI; all mutable fixtures are temporary."""

import contextlib
import copy
import hashlib
import importlib.machinery
import importlib.util
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tarfile
import tempfile
import unittest
from unittest.mock import patch

REPOSITORY = Path(__file__).resolve().parents[1]
loader = importlib.machinery.SourceFileLoader(
    "manage_under_test", str(REPOSITORY / "manage")
)
spec = importlib.util.spec_from_loader(loader.name, loader)
if spec is None:
    raise RuntimeError("unable to load manage")
manage = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = manage
loader.exec_module(manage)


class FixtureTestCase(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory(prefix="manage-test-")
        self.addCleanup(directory.cleanup)
        self.root = Path(directory.name)
        self.output = self.enterContext(contextlib.redirect_stdout(io.StringIO()))
        self.diagnostics = self.enterContext(contextlib.redirect_stderr(io.StringIO()))

    def git(self, *args):
        return subprocess.run(
            [
                "git",
                "-c",
                "user.name=Test",
                "-c",
                "user.email=test@example.invalid",
                *args,
            ],
            env=dict(os.environ, GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_NOSYSTEM="1"),
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()

    def tracked_source(self):
        source = self.root / "source"
        source.mkdir()
        self.git("-C", str(source), "init", "-q")
        (source / "Makefile").write_text(
            "all:\n\tmkdir -p build\n\tprintf clean > build/libfzf.so\n"
        )
        (source / "grammar.c").write_text("original source\n")
        self.git("-C", str(source), "add", ".")
        self.git("-C", str(source), "commit", "-qm", "fixture")
        commit = self.git("-C", str(source), "rev-parse", "HEAD")
        return source, commit

    def managed_source(self):
        source, commit = self.tracked_source()
        bare = self.root / "bare.git"
        worktree = self.root / "worktree"
        self.git("clone", "--bare", str(source), str(bare))
        self.git(
            "--git-dir",
            str(bare),
            "worktree",
            "add",
            "--detach",
            "--lock",
            str(worktree),
            commit,
        )
        lock = {
            "sources": {
                "fixture": {
                    "url": str(source),
                    "commit": commit,
                    "repository": "bare.git",
                    "worktree": "worktree",
                    "allowedDirtyPaths": ["build"],
                    "plugin": {"nativeBuild": {"kind": "make"}},
                }
            }
        }
        return lock, worktree

    def install_context(self, lock):
        stack = contextlib.ExitStack()
        for name, value in (
            ("repository_dir", str(self.root)),
            ("load_git_worktrees_lock", lock),
            ("sync_uv_production_if_needed", True),
            ("sync_pnpm_production", True),
            ("link_neovim_config", True),
        ):
            stack.enter_context(patch.object(manage, name, return_value=value))
        return stack


class ScanTests(FixtureTestCase):
    def test_severity_matrix(self):
        (self.root / "rules").mkdir()
        target = self.root / "fixture.py"
        target.write_text("fixture = 1\n")
        for findings in ((), ("ERROR",), ("WARNING",), ("ERROR", "WARNING")):
            for strict in (False, True):
                with self.subTest(findings=findings, strict=strict):

                    def scanner(command, env, repository):
                        selected = [
                            command[i + 1]
                            for i, item in enumerate(command[:-1])
                            if item == "--severity"
                        ]
                        self.assertIn("ERROR", selected)
                        self.assertEqual("WARNING" in selected, strict)
                        self.assertIn("--error", command)
                        return not any(finding in selected for finding in findings)

                    with (
                        patch.object(
                            manage, "repository_dir", return_value=str(self.root)
                        ),
                        patch.object(manage, "resolve_required", return_value="uv"),
                        patch.object(manage, "run_logged_command", side_effect=scanner),
                    ):
                        result = manage.scan(strict, [str(target)])
                    self.assertEqual(
                        result,
                        int("ERROR" in findings or (strict and "WARNING" in findings)),
                    )

    def test_scanner_failure_and_invalid_target(self):
        (self.root / "rules").mkdir()
        with (
            patch.object(manage, "repository_dir", return_value=str(self.root)),
            patch.object(manage, "resolve_required", return_value="uv"),
            patch.object(manage, "run_logged_command", return_value=False) as command,
        ):
            self.assertEqual(manage.scan(True, [str(self.root)]), 1)
            command.reset_mock()
            self.assertEqual(manage.scan(True, [str(self.root / "missing")]), 1)
            command.assert_not_called()


class PathTests(FixtureTestCase):
    def test_relative_paths(self):
        for value, expected in (
            ("dir/file", "dir/file"),
            ("./dir/file/", "dir/file"),
            ("dir/../file", "file"),
            ("dir\\file", "dir/file"),
        ):
            with self.subTest(value=value):
                self.assertEqual(manage.validated_relative_subpath(value), expected)
        for value in (
            "",
            ".",
            "..",
            "../outside",
            "dir/../../outside",
            "/absolute",
            "C:\\absolute",
            "//host/share",
        ):
            with self.subTest(value=value):
                self.assertIsNone(manage.validated_relative_subpath(value))
        self.assertEqual(manage.validated_relative_subpath_or_current("."), ".")
        self.assertFalse(manage.valid_source_id("."))
        self.assertFalse(manage.valid_source_id(".."))
        self.assertTrue(manage.valid_source_id("tree-sitter-lua"))

    def test_repository_paths_use_canonical_relative_form(self):
        self.assertEqual(
            manage.repository_path(str(self.root), r"nested\bare.git"),
            str(self.root / "nested/bare.git"),
        )
        self.assertIsNone(manage.repository_path(str(self.root), "."))
        self.assertIsNone(manage.repository_path(str(self.root), "/"))

    def test_path_collections(self):
        for paths in (["src", "LICENSE"], ["nested/file", "another"]):
            self.assertTrue(
                manage.source_sparse_checkout_paths({"files": paths}, "fixture")
            )
        for paths in ([], ["src", "./src"], ["src", "src/file"], ["../outside"], [1]):
            with self.subTest(paths=paths):
                self.assertEqual(
                    manage.source_sparse_checkout_paths({"files": paths}, "fixture"), []
                )
        self.assertIsNone(manage.source_sparse_checkout_paths({}, "fixture"))
        self.assertIsNone(
            manage.native_build_dependency_sources(
                "fixture", {"dependencySources": {"deps/../../outside": "dep"}}
            )
        )

    def test_overlay_rejects_escape_and_symlink_parent(self):
        worktree = self.root / "plugin"
        (worktree / "deps").mkdir(parents=True)
        sibling = self.root / "sibling"
        sibling.mkdir()
        original = sibling / "original"
        original.write_text("preserve")
        dependency = self.root / "dependency"
        dependency.mkdir()
        (dependency / "new").write_text("dependency")
        with patch.object(
            manage, "source_worktree_by_id", return_value=str(dependency)
        ):
            self.assertFalse(
                manage.overlay_native_build_dependency_sources(
                    str(self.root), {}, str(worktree), {"deps/../../sibling": "dep"}
                )
            )
            (worktree / "linked").symlink_to(sibling, target_is_directory=True)
            self.assertFalse(
                manage.overlay_native_build_dependency_sources(
                    str(self.root), {}, str(worktree), {"linked/child": "dep"}
                )
            )
        self.assertEqual(original.read_text(), "preserve")
        self.assertFalse((sibling / "child").exists())


@unittest.skipUnless(shutil.which("git"), "git is required for worktree fixtures")
class GitTests(FixtureTestCase):
    def test_pristine_changes_and_rename_origins(self):
        source, _ = self.tracked_source()

        def pristine():
            return manage.check_worktree_pristine(
                "git",
                os.environ,
                str(self.root),
                "fixture",
                str(source),
                ["build"],
                emit_warnings=False,
            )

        self.assertTrue(pristine())
        (source / "grammar.c").write_text("modified\n")
        self.assertFalse(pristine())
        self.git("-C", str(source), "checkout", "--", "grammar.c")
        (source / "build").mkdir()
        (source / "build/quoted\nfile").write_text("allowed output")
        self.assertTrue(pristine())
        self.git("-C", str(source), "mv", "grammar.c", "build/grammar.c")
        self.assertFalse(pristine())

    def test_ignored_files(self):
        source, _ = self.tracked_source()
        (source / ".git/info/exclude").write_text("*.out\n")
        (source / "unexpected.out").write_text("ignored")
        self.assertFalse(
            manage.check_worktree_pristine(
                "git",
                os.environ,
                str(self.root),
                "fixture",
                str(source),
                ["build"],
                emit_warnings=False,
            )
        )
        (source / "unexpected.out").unlink()
        (source / "build").mkdir()
        (source / "build/allowed.out").write_text("ignored")
        self.assertTrue(
            manage.check_worktree_pristine(
                "git",
                os.environ,
                str(self.root),
                "fixture",
                str(source),
                ["build"],
                emit_warnings=False,
            )
        )


@unittest.skipUnless(shutil.which("git"), "git is required for installation fixtures")
class SourceGateTests(FixtureTestCase):
    def test_rejected_sources_never_build(self):
        for failure in ("dirty", "missing", "unavailable"):
            with (
                self.subTest(failure=failure),
                tempfile.TemporaryDirectory() as directory,
            ):
                previous_root = self.root
                self.root = Path(directory)
                try:
                    lock, worktree = self.managed_source()
                    if failure == "dirty":
                        (worktree / "Makefile").write_text(
                            "all:\n\tmkdir -p build\n\tprintf rejected > build/libfzf.so\n"
                        )
                    elif failure == "missing":
                        shutil.rmtree(worktree)
                    else:
                        lock["sources"]["fixture"]["commit"] = "f" * 40
                    ensure_bare = manage.ensure_bare_repository

                    def repository_ready(*args):
                        return failure != "missing" and ensure_bare(*args)

                    with (
                        self.install_context(lock),
                        patch.object(
                            manage,
                            "ensure_bare_repository",
                            side_effect=repository_ready,
                        ),
                        patch.object(
                            manage,
                            "fetch_source_commit",
                            return_value=failure != "unavailable",
                        ),
                        patch.object(
                            manage, "install_native_plugin_artifacts"
                        ) as build,
                    ):
                        self.assertEqual(manage.install(False, False), 1)
                    build.assert_not_called()
                    self.assertFalse((worktree / "build/.manage-native-build").exists())
                finally:
                    self.root = previous_root

    def test_failed_dependency_source_prevents_build(self):
        lock, _ = self.managed_source()
        lock["sources"]["dependency"] = copy.deepcopy(lock["sources"]["fixture"])
        lock["sources"]["dependency"]["worktree"] = "missing"
        with (
            self.install_context(lock),
            patch.object(manage, "materialize_git_sources", return_value=False),
            patch.object(manage, "install_native_plugin_artifacts") as build,
        ):
            self.assertEqual(manage.install(False, False), 1)
        build.assert_not_called()


@unittest.skipUnless(
    shutil.which("git") and shutil.which("make"), "git and make are required"
)
class InstallModeTests(FixtureTestCase):
    def test_normal_refresh_offline_and_repeated_fast_paths(self):
        lock, worktree = self.managed_source()
        (self.root / "init.lua").write_text(
            "-- No vendored plugins in this isolated fixture.\n"
        )
        resolve_required = manage.resolve_required

        def resolve(name, env):
            return (
                "fixture-tree-sitter"
                if name == "tree-sitter"
                else resolve_required(name, env)
            )

        with (
            self.install_context(lock),
            patch.object(manage, "resolve_required", side_effect=resolve),
            patch.object(manage, "check_tree_sitter_cli", return_value=True),
            patch.object(
                manage,
                "tree_sitter_cli_version_text",
                return_value="tree-sitter 0.26.1",
            ),
            patch.object(
                manage, "materialize_git_sources", wraps=manage.materialize_git_sources
            ) as sources,
            patch.object(
                manage,
                "build_native_plugin_runtime",
                wraps=manage.build_native_plugin_runtime,
            ) as builds,
        ):
            self.assertEqual(manage.install(False, False), 0)
            self.assertEqual(sources.call_count, 1)
            self.assertEqual(builds.call_count, 1)
            self.assertEqual(manage.install(False, False), 0)
            self.assertEqual(sources.call_count, 1)
            self.assertEqual(builds.call_count, 1)
            self.assertEqual(manage.install(False, True), 0)
            self.assertEqual(sources.call_count, 2)
            self.assertEqual(builds.call_count, 1)
            self.assertEqual(manage.install(True, False), 0)
            self.assertEqual(sources.call_count, 2)
            self.assertEqual(builds.call_count, 1)
        self.assertEqual((worktree / "grammar.c").read_text(), "original source\n")
        self.assertIn("managed state already current", self.output.getvalue())

    def test_cli_runs_from_another_working_directory(self):
        result = subprocess.run(
            [sys.executable, str(REPOSITORY / "manage"), "--help"],
            cwd=self.root,
            check=True,
            capture_output=True,
            text=True,
        )
        self.assertIn("install", result.stdout)
        self.assertEqual(result.stderr, "")


class TreeSitterTests(FixtureTestCase):
    def tree_fixture(self):
        source = self.root / "grammar"
        for directory in ("src", "nested/src", "queries-old", "queries-new", "extra"):
            (source / directory).mkdir(parents=True)
        (source / "src/parser.c").write_text("source")
        (source / "nested/src/parser.c").write_text("nested source")
        (source / "queries-old/highlights.scm").write_text("(old) @variable")
        (source / "queries-new/highlights.scm").write_text("(new) @variable")
        (source / "extra/textobjects.scm").write_text("(object) @object")
        lock = {
            "sources": {
                "grammar": {
                    "commit": "a" * 40,
                    "worktree": "grammar",
                    "treesitter": {
                        "parsers": {
                            "fixture": {
                                "querySource": "grammar",
                                "queryPath": "queries-old",
                                "requiredQueries": ["highlights"],
                            }
                        }
                    },
                }
            },
            "treesitter": {"runtimeSite": "runtime"},
        }
        return lock, self.root / "runtime"

    def install_tree(self, lock, produce_output=True):
        def command(args, env, cwd, **kwargs):
            if "build" in args and produce_output:
                Path(args[args.index("-o") + 1]).write_bytes(b"compiled parser")
            return True

        with (
            patch.object(manage, "check_tree_sitter_cli", return_value=True),
            patch.object(manage, "resolve_required", return_value="tree-sitter"),
            patch.object(
                manage,
                "tree_sitter_cli_version_text",
                return_value="tree-sitter 0.26.1",
            ),
            patch.object(manage, "run_logged_command", side_effect=command) as commands,
        ):
            result = manage.install_treesitter_runtime(
                {"PATH": "/fixture-tools"}, str(self.root), lock
            )
        return result, commands.call_count

    def test_install_and_unchanged_fast_path(self):
        lock, runtime = self.tree_fixture()
        self.assertEqual(self.install_tree(lock)[0], True)
        self.assertTrue(manage.treesitter_runtime_state_ok(str(self.root), lock, False))
        self.assertEqual(self.install_tree(lock), (True, 0))
        self.assertEqual(
            (runtime / "queries/fixture/highlights.scm").read_text(), "(old) @variable"
        )
        self.assertEqual((self.root / "grammar/src/parser.c").read_text(), "source")

    def test_same_commit_configuration_changes_are_stale(self):
        lock, _ = self.tree_fixture()
        self.assertTrue(self.install_tree(lock)[0])
        for field, value in (
            ("queryPath", "queries-new"),
            ("generate", True),
            ("location", "nested"),
            ("requiredQueries", ["highlights", "indents"]),
        ):
            candidate = copy.deepcopy(lock)
            candidate["sources"]["grammar"]["treesitter"]["parsers"]["fixture"][
                field
            ] = value
            with self.subTest(field=field):
                self.assertFalse(
                    manage.treesitter_runtime_state_ok(str(self.root), candidate, False)
                )
        candidate = copy.deepcopy(lock)
        candidate["sources"]["grammar"]["commit"] = "b" * 40
        self.assertFalse(
            manage.treesitter_runtime_state_ok(str(self.root), candidate, False)
        )

    def test_removal_and_unexpected_outputs(self):
        lock, runtime = self.tree_fixture()
        self.assertTrue(self.install_tree(lock)[0])
        extra = runtime / "queries/fixture/obsolete.scm"
        extra.write_text("obsolete")
        self.assertFalse(
            manage.treesitter_runtime_state_ok(str(self.root), lock, False)
        )
        self.assertTrue(self.install_tree(lock)[0])
        self.assertFalse(extra.exists())
        lock["sources"]["grammar"]["treesitter"]["parsers"] = {}
        self.assertFalse(
            manage.treesitter_runtime_state_ok(str(self.root), lock, False)
        )
        self.assertTrue(self.install_tree(lock)[0])
        self.assertFalse((runtime / "parser/fixture.so").exists())
        self.assertTrue(manage.treesitter_runtime_state_ok(str(self.root), lock, False))

    def test_invalid_staging_preserves_previous_runtime(self):
        lock, runtime = self.tree_fixture()
        self.assertTrue(self.install_tree(lock)[0])
        previous = (runtime / "parser/fixture.so").read_bytes()
        lock["sources"]["grammar"]["commit"] = "b" * 40
        self.assertFalse(self.install_tree(lock, produce_output=False)[0])
        self.assertEqual((runtime / "parser/fixture.so").read_bytes(), previous)
        lock["sources"]["grammar"]["treesitter"]["parsers"]["fixture"][
            "requiredQueries"
        ].append("indents")
        self.assertFalse(self.install_tree(lock)[0])
        self.assertEqual((runtime / "parser/fixture.so").read_bytes(), previous)

    def test_query_dependencies_and_supplemental_changes(self):
        lock, runtime = self.tree_fixture()
        lock["sources"]["grammar"]["treesitter"]["parsers"]["fixture"][
            "queryDependencies"
        ] = ["extra"]
        lock["treesitter"]["defaults"] = {
            "supplementalQueryGroups": [
                {
                    "name": "textobjects",
                    "source": "grammar",
                    "path": "extra/textobjects.scm",
                    "languages": ["fixture", "extra"],
                }
            ]
        }
        self.assertTrue(self.install_tree(lock)[0])
        self.assertTrue((runtime / "queries/extra/highlights.scm").is_file())
        self.assertTrue((runtime / "queries/fixture/textobjects.scm").is_file())
        lock["treesitter"]["defaults"]["supplementalQueryGroups"] = []
        self.assertFalse(
            manage.treesitter_runtime_state_ok(str(self.root), lock, False)
        )
        self.assertTrue(self.install_tree(lock)[0])
        self.assertFalse((runtime / "queries/fixture/textobjects.scm").exists())

    def test_bad_signature_and_symlink_query_source(self):
        lock, runtime = self.tree_fixture()
        self.assertTrue(self.install_tree(lock)[0])
        Path(manage.treesitter_runtime_signature_path(str(runtime))).write_text("[]")
        self.assertFalse(
            manage.treesitter_runtime_state_ok(str(self.root), lock, False)
        )
        source = self.root / "grammar/queries-old/highlights.scm"
        source.unlink()
        outside = self.root / "outside.scm"
        outside.write_text("unreviewed")
        source.symlink_to(outside)
        self.assertFalse(self.install_tree(lock)[0])


class ReleasedSourceTests(FixtureTestCase):
    def archive_fixture(self, members=None):
        archive = self.root / "candidate.tar.gz"
        members = members or {
            "./src/parser.c": b"parser source",
            "./queries/highlights.scm": b"(source) @variable",
        }
        with tarfile.open(archive, "w:gz") as tar:
            for name, body in members.items():
                member = tarfile.TarInfo(name)
                member.size = len(body)
                tar.addfile(member, io.BytesIO(body))
        released = {
            "url": "https://example.invalid/archive.tar.gz",
            "sha256": hashlib.sha256(archive.read_bytes()).hexdigest(),
            "files": ["src", "queries"],
        }
        source = {"commit": "a" * 40, "treesitter": {"releasedSource": released}}
        lock = {
            "sources": {"grammar": source},
            "treesitter": {"runtimeSite": "runtime"},
        }

        def download(url, destination):
            shutil.copy2(archive, destination)
            return True

        with patch.object(manage, "download_url", side_effect=download):
            self.assertTrue(
                manage.materialize_treesitter_released_source(
                    str(self.root), lock, "grammar", source
                )
            )
        return (
            lock,
            source,
            Path(
                manage.treesitter_released_source_source_path(
                    str(self.root), lock, "grammar"
                )
            ),
        )

    def test_verified_archive_and_extracted_contents(self):
        lock, source, root = self.archive_fixture()
        self.assertTrue(
            manage.treesitter_released_source_state_ok(
                str(self.root), lock, "grammar", source, False
            )
        )
        original = root / "src/parser.c"
        original.write_bytes(b"modified source")
        self.assertFalse(
            manage.treesitter_released_source_state_ok(
                str(self.root), lock, "grammar", source, False
            )
        )
        original.write_bytes(b"parser source")
        (root / "extra").write_text("unexpected")
        self.assertFalse(
            manage.treesitter_released_source_state_ok(
                str(self.root), lock, "grammar", source, False
            )
        )
        (root / "extra").unlink()
        original.unlink()
        original.symlink_to(self.root / "candidate.tar.gz")
        self.assertFalse(
            manage.treesitter_released_source_state_ok(
                str(self.root), lock, "grammar", source, False
            )
        )

    def test_archive_invalid_paths_and_links(self):
        for name in ("../escape", "/absolute", "nested/../../escape"):
            archive = self.root / "bad.tar.gz"
            with tarfile.open(archive, "w:gz") as tar:
                member = tarfile.TarInfo(name)
                member.size = 3
                tar.addfile(member, io.BytesIO(b"bad"))
            self.assertFalse(
                manage.extract_tar_gz(str(archive), str(self.root / "extract"))
            )
        with tarfile.open(archive, "w:gz") as tar:
            member = tarfile.TarInfo("symlink")
            member.type = tarfile.SYMTYPE
            member.linkname = "../outside"
            tar.addfile(member)
        self.assertFalse(
            manage.extract_tar_gz(str(archive), str(self.root / "extract"))
        )
        self.assertFalse((self.root / "escape").exists())


class CatalogTests(FixtureTestCase):
    def test_json_loader_round_trip_and_delimiters(self):
        path = self.root / "catalog.lua"
        entries = [
            {
                "name": "fixture",
                "path": "schemas/example.json",
                "description": "control:\x01" + "23; ' \\ \n λ ]=] ]==]",
                "fileMatch": ["*.json"],
                "versions": {"1": "schema.json"},
            }
        ]
        self.assertTrue(manage.write_schema_catalog_lua(str(path), entries))
        import re

        match = re.search(
            r"return vim\.json\.decode\(\[(=*)\[(.*?)\]\1\]\)",
            path.read_text(),
            re.DOTALL,
        )
        if match is None:
            self.fail("generated catalog did not contain the JSON loader")
        self.assertEqual(json.loads(match.group(2)), {"entries": entries})
        nvim = shutil.which("nvim")
        if nvim is not None:
            command = [
                nvim,
                "--clean",
                "--headless",
                "--cmd",
                "lua io.write(vim.json.encode(assert(loadfile("
                + manage.lua_quote(str(path))
                + "))()))",
                "--cmd",
                "qa",
            ]
            result = subprocess.run(
                command, check=True, capture_output=True, text=True, timeout=30
            )
            self.assertEqual(json.loads(result.stdout), {"entries": entries})

    def test_invalid_serialization_is_reported(self):
        path = self.root / "catalog.lua"
        for value in (float("nan"), float("inf"), object(), "\ud800"):
            with self.subTest(value=value):
                self.assertFalse(
                    manage.write_schema_catalog_lua(str(path), [{"invalid": value}])
                )
        self.assertIn("serialize", self.diagnostics.getvalue())

    def test_lua_argument_quoting(self):
        self.assertEqual(manage.lua_quote("\x01" + "23"), "'\\00123'")
        if shutil.which("luajit"):
            value = "\x01" + "23'\\\nλ"
            command = "local value = " + manage.lua_quote(value) + "; io.write(value)"
            result = subprocess.run(
                ["luajit", "-e", command], check=True, capture_output=True, text=True
            )
            self.assertEqual(result.stdout, value)


class CheckGateTests(FixtureTestCase):
    def test_python_checks_run_but_managed_harness_is_gated_on_failures(self):
        for failure in ("sources", "development"):
            with self.subTest(failure=failure), contextlib.ExitStack() as stack:
                for name, value in (
                    ("repository_dir", str(self.root)),
                    ("resolve_required", "fixture-tool"),
                    ("load_git_worktrees_lock", {"sources": {}}),
                    ("check_git_sources", failure != "sources"),
                    ("check_treesitter_runtime", True),
                    ("check_native_plugin_artifacts", True),
                    ("schema_catalog_state_ok", True),
                    ("check_vendored_plugins", True),
                    ("neovim_runtime", "/builtin-runtime"),
                    ("lua_workspace_libraries", []),
                    ("source_worktree_by_id", str(self.root)),
                    ("discover_lua_specs", ["fixture_spec.lua"]),
                ):
                    stack.enter_context(patch.object(manage, name, return_value=value))

                def command_result(command, *args, **kwargs):
                    return not (
                        failure == "development" and command[1:3] == ["-m", "unittest"]
                    )

                commands = stack.enter_context(
                    patch.object(
                        manage, "run_logged_command", side_effect=command_result
                    )
                )
                self.assertEqual(manage.check(False), 1)
                arguments = [call.args[0] for call in commands.call_args_list]
                self.assertTrue(
                    any(command[1:3] == ["-m", "unittest"] for command in arguments)
                )
                self.assertFalse(any("--headless" in command for command in arguments))


class IOTests(FixtureTestCase):
    def test_capture_and_logging_policies(self):
        env = {"PATH": "/tools"}
        completed = subprocess.CompletedProcess(["tool"], 0, "stdout\n", "stderr\n")
        with patch.object(manage.subprocess, "run", return_value=completed) as run:
            self.assertEqual(manage.run_logged_probe(["tool"], env, str(self.root)), 0)
            self.assertEqual(self.diagnostics.getvalue(), "")
            self.assertTrue(
                manage.run_logged_command(
                    ["tool"], env, str(self.root), show_success_output_on_stderr=False
                )
            )
            self.assertNotIn("stdout", self.output.getvalue())
            self.assertTrue(manage.run_logged_command(["tool"], env, str(self.root)))
            self.assertIn("stderr", self.diagnostics.getvalue())
            self.assertEqual(run.call_args.kwargs["cwd"], str(self.root))
            self.assertEqual(run.call_args.kwargs["env"], env)
        completed.returncode = 2
        with patch.object(manage.subprocess, "run", return_value=completed):
            self.assertFalse(manage.run_logged_command(["tool"], env, str(self.root)))
        self.assertIn("exit code 2", self.diagnostics.getvalue())
        for function in (
            manage.run_captured_command,
            manage.run_logged_probe,
            manage.run_logged_command,
        ):
            with patch.object(
                manage.subprocess, "run", side_effect=OSError("fixture failure")
            ):
                self.assertFalse(function(["tool"], env, str(self.root)))
        self.assertIn("fixture failure", self.diagnostics.getvalue())

    def test_clean_neovim_query(self):
        for code, stdout, expected in (
            (0, "runtime\n", "runtime"),
            (0, "", None),
            (1, "", None),
        ):
            with patch.object(
                manage.subprocess,
                "run",
                return_value=subprocess.CompletedProcess([], code, stdout, "failure"),
            ) as run:
                self.assertEqual(
                    manage.neovim_runtime("nvim", {}, str(self.root)), expected
                )
                self.assertIn("--clean", run.call_args.args[0])

    def test_json_object_boundaries(self):
        path = self.root / ".luarc.json"
        for text in ("[]", "null", "broken"):
            path.write_text(text)
            self.assertIsNone(manage.lua_workspace_libraries({}, str(self.root)))
        path.write_bytes(b"\xff")
        self.assertIsNone(manage.lua_workspace_libraries({}, str(self.root)))
        path.write_text('{"workspace.library": ["relative", "${3rd}/luv"]}')
        self.assertEqual(
            manage.lua_workspace_libraries({}, str(self.root)),
            [str(self.root / "relative")],
        )


class PublicationTests(FixtureTestCase):
    def directories(self):
        live = self.root / "live"
        staged = self.root / "staged"
        for root, value in ((live, "old"), (staged, "new")):
            for child in ("parser", "queries", "state"):
                (root / child).mkdir(parents=True)
                (root / child / "value").write_text(value)
        return live, staged

    def test_grouped_success_preserves_unowned_children(self):
        live, staged = self.directories()
        (live / "sources").mkdir()
        self.assertTrue(
            manage.publish_runtime_subdirectories(
                str(live), str(staged), ("parser", "queries", "state")
            )
        )
        self.assertTrue((live / "sources").is_dir())
        self.assertEqual((live / "parser/value").read_text(), "new")
        self.assertFalse(list(self.root.rglob("*.previous.*")))

    def test_failure_rollback_at_each_rename(self):
        for failure_index in range(1, 7):
            with (
                self.subTest(failure_index=failure_index),
                tempfile.TemporaryDirectory() as directory,
            ):
                original_root = self.root
                self.root = Path(directory)
                try:
                    live, staged = self.directories()
                    rename = os.rename
                    calls = 0

                    def fail_once(source, destination):
                        nonlocal calls
                        calls += 1
                        if calls == failure_index:
                            raise OSError("publication failure")
                        return rename(source, destination)

                    with patch.object(manage.os, "rename", side_effect=fail_once):
                        self.assertFalse(
                            manage.publish_runtime_subdirectories(
                                str(live), str(staged), ("parser", "queries", "state")
                            )
                        )
                    for child in ("parser", "queries", "state"):
                        self.assertEqual((live / child / "value").read_text(), "old")
                finally:
                    self.root = original_root

    def test_rollback_failure_reports_backup_location(self):
        live, staged = self.directories()
        rename = os.rename

        def fail_publish_and_restore(source, destination):
            if str(source).startswith(str(staged)) or ".previous." in str(source):
                raise OSError("cannot restore")
            return rename(source, destination)

        with patch.object(manage.os, "rename", side_effect=fail_publish_and_restore):
            self.assertFalse(manage.replace_directory(str(live), str(staged)))
        self.assertIn("recovery", self.diagnostics.getvalue())
        self.assertIn(".previous.", self.diagnostics.getvalue())
        self.assertTrue(list(self.root.glob("live.previous.*")))

    def test_cleanup_failure_and_missing_staging(self):
        live, staged = self.directories()
        with patch.object(manage, "remove_path", return_value=False):
            self.assertFalse(manage.replace_directory(str(live), str(staged)))
        self.assertTrue(list(self.root.glob("live.previous.*")))
        self.assertFalse(
            manage.replace_directory(str(live), str(self.root / "missing"))
        )
        self.assertEqual((live / "parser/value").read_text(), "new")


class ManifestTests(FixtureTestCase):
    def manifest(self):
        return {
            "sources": {
                "grammar": {
                    "url": "https://example.invalid/grammar.git",
                    "commit": "a" * 40,
                    "files": ["src", "queries"],
                    "treesitter": {
                        "parsers": {
                            "fixture": {
                                "querySource": "grammar",
                                "queryPath": "queries",
                            }
                        }
                    },
                }
            }
        }

    def load(self, value):
        (self.root / "source-manifest.json").write_text(json.dumps(value))
        return manage.load_git_worktrees_lock(str(self.root))

    def test_current_manifest_and_optional_absence(self):
        self.assertIsNotNone(manage.load_git_worktrees_lock(str(REPOSITORY)))
        self.assertIsNotNone(self.load(self.manifest()))

    def test_invalid_types_paths_and_refs(self):
        for field, value in (("roots", []), ("treesitter", []), ("sources", [])):
            lock = self.manifest()
            lock[field] = value
            with self.subTest(field=field):
                self.assertIsNone(self.load(lock))
        for field, value in (
            ("commit", "main"),
            ("url", None),
            ("ref", 1),
            ("locked", None),
            ("files", None),
            ("files", ["src", "src/file"]),
            ("worktree", "."),
            ("allowedDirtyPaths", ["deps/../../outside"]),
        ):
            lock = self.manifest()
            lock["sources"]["grammar"][field] = value
            with self.subTest(field=field, value=value):
                self.assertIsNone(self.load(lock))

    def test_duplicate_outputs_and_unknown_references(self):
        lock = self.manifest()
        lock["sources"]["second"] = copy.deepcopy(lock["sources"]["grammar"])
        self.assertIsNone(self.load(lock))
        lock = self.manifest()
        lock["sources"]["grammar"]["treesitter"]["parsers"]["fixture"][
            "querySource"
        ] = "unknown"
        self.assertIsNone(self.load(lock))
        lock = self.manifest()
        for path in (
            "vendor/treesitter/source",
            "vendor/schemas",
            r"vendor\git\worktrees\second",
        ):
            lock = self.manifest()
            lock["sources"]["grammar"]["worktree"] = path
            if path.endswith("second"):
                lock["sources"]["second"] = {
                    "url": "https://example.invalid/second.git",
                    "commit": "b" * 40,
                }
            self.assertIsNone(self.load(lock))

    def test_native_kind_field_combinations(self):
        for native in (
            {"kind": "make", "features": []},
            {"kind": "make", "optional": True},
            {
                "kind": "cargo",
                "artifactStem": "target/release/libfixture",
                "dependencySources": {},
            },
        ):
            lock = self.manifest()
            lock["sources"]["grammar"]["allowedDirtyPaths"] = ["build", "target"]
            lock["sources"]["grammar"]["plugin"] = {"nativeBuild": native}
            with self.subTest(native=native):
                self.assertIsNone(self.load(lock))


class NativeTests(FixtureTestCase):
    def native_fixture(self):
        worktree = self.root / "plugin"
        (worktree / "target/release").mkdir(parents=True)
        native = {
            "kind": "cargo",
            "optional": True,
            "artifactStem": "target/release/libfixture",
        }
        lock = {
            "sources": {
                "fixture": {
                    "url": "https://example.invalid/plugin.git",
                    "commit": "b" * 40,
                    "worktree": "plugin",
                    "allowedDirtyPaths": ["target"],
                    "plugin": {"nativeBuild": native},
                }
            }
        }
        return lock, worktree, native

    def test_write_permissions_and_symlink_outputs(self):
        lock, worktree, native = self.native_fixture()
        lock["sources"]["fixture"]["allowedDirtyPaths"] = []
        self.assertFalse(
            manage.validate_source_settings("fixture", lock["sources"]["fixture"])
        )
        with patch.object(manage, "run_logged_command") as build:
            self.assertEqual(
                manage.build_native_plugin_runtime(
                    os.environ, str(self.root), lock, "fixture", str(worktree), native
                ),
                "failed",
            )
            build.assert_not_called()
        lock["sources"]["fixture"]["allowedDirtyPaths"] = ["target"]
        self.assertTrue(
            manage.validate_source_settings("fixture", lock["sources"]["fixture"])
        )
        inside = worktree / "src"
        inside.mkdir()
        shutil.rmtree(worktree / "target")
        (worktree / "target").symlink_to(inside, target_is_directory=True)
        with patch.object(manage, "run_logged_command") as build:
            self.assertEqual(
                manage.build_native_plugin_runtime(
                    os.environ, str(self.root), lock, "fixture", str(worktree), native
                ),
                "failed",
            )
            build.assert_not_called()
        (worktree / "target").unlink()
        (worktree / "target/release").mkdir(parents=True)
        outside = self.root / "outside"
        outside.mkdir()
        shutil.rmtree(worktree / "target")
        (worktree / "target").symlink_to(outside, target_is_directory=True)
        with patch.object(manage, "run_logged_command") as build:
            self.assertEqual(
                manage.build_native_plugin_runtime(
                    os.environ, str(self.root), lock, "fixture", str(worktree), native
                ),
                "failed",
            )
            build.assert_not_called()

    def test_make_file_symlinks_cannot_escape_write_permissions(self):
        lock, worktree, _ = self.native_fixture()
        source = lock["sources"]["fixture"]
        native = {"kind": "make"}
        source["plugin"]["nativeBuild"] = native
        source["allowedDirtyPaths"] = ["build"]
        (worktree / "build").mkdir()
        victim = self.root / "victim"
        victim.write_text("preserve")
        for name in ("libfzf.so", ".manage-native-build"):
            destination = worktree / "build" / name
            destination.symlink_to(victim)
            self.assertFalse(
                manage.native_build_paths_ok(str(worktree), "fixture", source)
            )
            with patch.object(manage, "run_logged_command") as build:
                self.assertEqual(
                    manage.build_native_plugin_runtime(
                        os.environ,
                        str(self.root),
                        lock,
                        "fixture",
                        str(worktree),
                        native,
                    ),
                    "failed",
                )
                build.assert_not_called()
            destination.unlink()
        self.assertEqual(victim.read_text(), "preserve")

    @unittest.skipUnless(
        shutil.which("git") and shutil.which("make"), "git and make are required"
    )
    def test_ready_source_builds_only_declared_outputs(self):
        lock, worktree = self.managed_source()
        self.assertTrue(
            manage.install_native_plugin_artifacts(os.environ, str(self.root), lock)
        )
        self.assertTrue(
            manage.native_plugin_artifacts_state_ok(str(self.root), lock, False)
        )
        self.assertEqual((worktree / "grammar.c").read_text(), "original source\n")

    def test_optional_absent_current_stale_transitions(self):
        lock, worktree, native = self.native_fixture()
        artifact = Path(manage.native_plugin_artifact_path(str(worktree), native))
        with patch.object(manage, "resolve_required", return_value=None):
            self.assertTrue(
                manage.install_native_plugin_artifacts(os.environ, str(self.root), lock)
            )
        self.assertTrue(
            manage.native_plugin_artifacts_state_ok(str(self.root), lock, False)
        )
        stamp = Path(manage.native_build_revision_path(str(worktree), native))
        self.assertTrue(
            manage.write_native_build_revision(str(worktree), lock, "fixture", native)
        )
        self.assertFalse(
            manage.native_plugin_artifacts_state_ok(str(self.root), lock, False)
        )
        stamp.unlink()
        artifact.write_bytes(b"current")
        self.assertTrue(
            manage.write_native_build_revision(str(worktree), lock, "fixture", native)
        )
        with patch.object(manage, "build_native_plugin_runtime") as build:
            self.assertTrue(
                manage.install_native_plugin_artifacts(os.environ, str(self.root), lock)
            )
            build.assert_not_called()
        lock["sources"]["fixture"]["commit"] = "c" * 40
        for outcome in ("skipped", "failed"):
            with self.subTest(outcome=outcome):
                artifact.write_bytes(b"stale")
                with patch.object(
                    manage, "build_native_plugin_runtime", return_value=outcome
                ):
                    self.assertEqual(
                        manage.install_native_plugin_artifacts(
                            os.environ, str(self.root), lock
                        ),
                        outcome == "skipped",
                    )
                self.assertFalse(artifact.exists())
                self.assertFalse(stamp.exists())

        def rebuilt(*args):
            artifact.write_bytes(b"new")
            self.assertTrue(
                manage.write_native_build_revision(
                    str(worktree), lock, "fixture", native
                )
            )
            return "built"

        with patch.object(manage, "build_native_plugin_runtime", side_effect=rebuilt):
            self.assertTrue(
                manage.install_native_plugin_artifacts(os.environ, str(self.root), lock)
            )
        self.assertTrue(
            manage.native_plugin_artifacts_state_ok(str(self.root), lock, False)
        )

    @unittest.skipUnless(
        shutil.which("git"), "git is required for source postconditions"
    )
    def test_build_writes_outside_declared_paths_are_rejected(self):
        git = shutil.which("git")
        lock, worktree = self.managed_source()
        native = lock["sources"]["fixture"]["plugin"]["nativeBuild"]
        artifact = Path(manage.native_plugin_artifact_path(str(worktree), native))
        stamp = Path(manage.native_build_revision_path(str(worktree), native))

        def fake_build(*args, **kwargs):
            artifact.parent.mkdir(parents=True, exist_ok=True)
            artifact.write_bytes(b"compiled")
            (worktree / "grammar.c").write_text("unexpected source mutation")
            return True

        with (
            patch.object(
                manage,
                "resolve_required",
                side_effect=lambda name, env: git if name == "git" else "fake-make",
            ),
            patch.object(manage, "run_logged_command", side_effect=fake_build),
        ):
            self.assertFalse(
                manage.install_native_plugin_artifacts(os.environ, str(self.root), lock)
            )
        self.assertFalse(artifact.exists())
        self.assertFalse(stamp.exists())
        self.assertIn("worktree is not pristine", self.diagnostics.getvalue())

    def test_success_without_output_never_stamps_current(self):
        lock, worktree, native = self.native_fixture()
        with (
            patch.object(manage, "resolve_required", return_value="cargo"),
            patch.object(manage, "run_logged_command", return_value=True),
        ):
            self.assertEqual(
                manage.build_native_plugin_runtime(
                    os.environ, str(self.root), lock, "fixture", str(worktree), native
                ),
                "skipped",
            )
        self.assertFalse(
            Path(manage.native_build_revision_path(str(worktree), native)).exists()
        )


if __name__ == "__main__":
    unittest.main()
