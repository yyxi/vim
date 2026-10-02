"""CLI safety boundaries, not simulations of every reviewed vendor build."""

import contextlib
import json
from unittest.mock import patch

from support import FixtureTestCase, manage


class ManageTests(FixtureTestCase):
    def test_paths_cannot_escape_owned_root(self):
        for path in ("../outside", "/absolute", "C:\\absolute", "nested/../../outside"):
            with self.subTest(path=path):
                self.assertIsNone(manage.source_subpath(str(self.root), path))
        outside = self.root.parent / "outside"
        (self.root / "link").symlink_to(outside)
        self.assertIsNone(manage.source_subpath(str(self.root), "link/file"))

    def test_nested_cache_paths_cannot_escape_repository(self):
        repository = self.root / "repository"
        repository.mkdir()
        outside = self.root / "outside"
        outside.mkdir()
        for relative in ("vendor/python", "vendor/python/wheels"):
            path = repository / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.symlink_to(outside)
            with (
                self.subTest(path=relative),
                patch.object(
                    manage,
                    "python_runtime_identity",
                    side_effect=AssertionError("probe"),
                ),
            ):
                self.assertFalse(manage.prepare_python_cache("uv", {}, str(repository)))
            path.unlink()
        runtime = repository / manage.TREE_SITTER_RUNTIME_SITE
        for relative in ("sources", "sources/fixture", "sources/fixture/source"):
            path = runtime / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.symlink_to(outside)
            with self.subTest(path=relative):
                self.assertIsNone(
                    manage.treesitter_released_source_source_path(
                        str(repository), {"sources": {}}, "fixture"
                    )
                )
            path.unlink()
        self.assertEqual(list(outside.iterdir()), [])

    def test_python_inventory_rejects_escaping_directory_links(self):
        repository = self.root / "repository"
        repository.mkdir()
        environment = repository / ".venv"
        manage.subprocess.run(
            [manage.python_driver(), "-m", "venv", "--without-pip", str(environment)],
            check=True,
            timeout=30,
        )
        lib = environment / "lib"
        minor = next(lib.iterdir())
        (minor / "site-packages/fixture.py").write_text("value = 1\n")
        original = manage.python_environment_inventory(str(repository))
        self.assertIsNotNone(original)
        external = self.root / "external"
        for path in (lib, minor, environment / "bin"):
            path.rename(external)
            path.symlink_to(external)
            with self.subTest(path=str(path.relative_to(environment))):
                self.assertIsNone(manage.python_environment_inventory(str(repository)))
            path.unlink()
            external.rename(path)
        self.assertEqual(manage.python_environment_inventory(str(repository)), original)

    def test_sparse_checkout_errors_fail_closed(self):
        for status, output, expected in (
            (0, "true", True),
            (0, "false", False),
            (1, "", False),
            (128, "", None),
        ):
            result = manage.subprocess.CompletedProcess(["git"], status, output, "")
            with (
                self.subTest(status=status, output=output),
                patch.object(manage, "run_captured_command", return_value=result),
            ):
                self.assertIs(
                    manage.worktree_sparse_checkout_enabled(
                        "git", {}, str(self.root), str(self.root)
                    ),
                    expected,
                )
                self.assertEqual(
                    manage.check_worktree_sparse_checkout(
                        "git", {}, str(self.root), "fixture", {}, str(self.root)
                    ),
                    expected is False,
                )

    def test_schema_catalog_output_integrity_and_repair(self):
        source = self.root / "source"
        catalog = source / manage.SCHEMA_CATALOG_SRC_CATALOG
        catalog.parent.mkdir(parents=True)
        schemas = source / manage.SCHEMA_CATALOG_SRC_SCHEMAS
        schemas.mkdir(parents=True)
        (schemas / "fixture.json").write_text("{}")
        catalog.write_text(
            json.dumps(
                {"schemas": [{"url": "https://json.schemastore.org/fixture.json"}]}
            )
        )
        lock = {
            "sources": {
                manage.SCHEMASTORE_SOURCE_ID: {"worktree": "source", "commit": "a" * 40}
            }
        }
        self.assertTrue(manage.materialize_schema_catalog(str(self.root), lock))
        self.assertTrue(manage.schema_catalog_state_ok(str(self.root), lock, True))
        output = self.root / manage.SCHEMA_CATALOG_DIR / manage.SCHEMA_CATALOG_LUA_NAME
        output.write_text("corrupt generated Lua")
        self.assertFalse(manage.schema_catalog_state_ok(str(self.root), lock, True))
        self.assertTrue(manage.materialize_schema_catalog(str(self.root), lock))
        self.assertTrue(manage.schema_catalog_state_ok(str(self.root), lock, True))

    def test_metadata_publication_preserves_conflicts_and_previous_state(self):
        metadata = self.root / "state.json"
        metadata.write_text("previous state")
        scratch = self.root / ("state.json.tmp-" + str(manage.os.getpid()))
        scratch.mkdir()
        retained = scratch / "keep"
        retained.write_text("pre-existing bytes")
        with patch.object(manage.os, "replace", side_effect=OSError("publication")):
            self.assertFalse(
                manage.write_component_state(str(metadata), {"version": 1})
            )
        self.assertEqual(metadata.read_text(), "previous state")
        self.assertEqual(retained.read_text(), "pre-existing bytes")
        self.assertEqual(set(self.root.iterdir()), {metadata, scratch})
        self.assertTrue(manage.write_component_state(str(metadata), {"version": 1}))
        self.assertEqual(json.loads(metadata.read_text()), {"version": 1})
        self.assertEqual(retained.read_text(), "pre-existing bytes")
        self.assertEqual(set(self.root.iterdir()), {metadata, scratch})

    def test_removal_handles_special_files_without_following_links(self):
        target = self.root / "target"
        target.mkdir()
        retained = target / "keep"
        retained.write_text("contents")
        link = self.root / "link"
        link.symlink_to(target)
        self.assertTrue(manage.remove_path(str(link)))
        self.assertEqual(retained.read_text(), "contents")
        pipe = self.root / "pipe"
        manage.os.mkfifo(pipe)
        self.assertTrue(manage.remove_path(str(pipe)))
        self.assertFalse(pipe.exists())
        self.assertTrue(manage.remove_path(str(pipe)))
        with patch.object(
            manage.os, "lstat", side_effect=PermissionError("inspection")
        ):
            self.assertFalse(manage.remove_path(str(target)))
        self.assertEqual(retained.read_text(), "contents")

    def test_stored_source_url_is_independent_of_transport_rewrites(self):
        bare = self.root / "fixture.git"
        url = "https://source.invalid/fixture.git"
        env = dict(
            manage.os.environ,
            GIT_CONFIG_GLOBAL=manage.os.devnull,
            GIT_CONFIG_NOSYSTEM="1",
            GIT_CONFIG_COUNT="1",
            GIT_CONFIG_KEY_0="url.ssh://git@mirror.invalid/.insteadOf",
            GIT_CONFIG_VALUE_0="https://source.invalid/",
        )
        manage.subprocess.run(
            ["git", "init", "--bare", "--initial-branch=fixture", str(bare)],
            env=env,
            check=True,
            capture_output=True,
        )
        for urls, expected in (
            ([url], True),
            (["https://source.invalid/other.git"], False),
            ([url, "https://source.invalid/other.git"], False),
        ):
            for index, value in enumerate(urls):
                manage.subprocess.run(
                    [
                        "git",
                        "--git-dir",
                        str(bare),
                        "config",
                        "--replace-all" if index == 0 else "--add",
                        "remote.origin.url",
                        value,
                    ],
                    env=env,
                    check=True,
                    capture_output=True,
                )
            with self.subTest(urls=urls):
                self.assertEqual(
                    manage.ensure_bare_repository(
                        "git", env, str(self.root), "fixture", {"url": url}, str(bare)
                    ),
                    expected,
                )

    def test_invalid_manifest_fails_before_installation(self):
        path = self.root / "source-manifest.json"
        for value in ([], {"sources": {"fixture": {"commit": "not-a-commit"}}}):
            path.write_text(json.dumps(value))
            self.assertIsNone(manage.load_git_worktrees_lock(str(self.root)))

    def test_offline_install_never_acquires_and_links_only_valid_state(self):
        for ready in (False, True):
            with self.subTest(ready=ready), contextlib.ExitStack() as stack:
                for name, value in (
                    ("repository_dir", str(self.root)),
                    ("load_git_worktrees_lock", {"sources": {}}),
                    ("complete_python_offline", True),
                    ("node_state_ok", True),
                    ("install_managed_state_ok", ready),
                    ("git_sources_state_ok", False),
                    ("treesitter_released_sources_state_ok", True),
                ):
                    stack.enter_context(patch.object(manage, name, return_value=value))
                link = stack.enter_context(
                    patch.object(manage, "link_neovim_config", return_value=True)
                )
                for name in (
                    "sync_uv_production_if_needed",
                    "sync_pnpm_production",
                    "materialize_git_sources",
                    "install_native_plugin_artifacts",
                ):
                    stack.enter_context(
                        patch.object(
                            manage,
                            name,
                            side_effect=AssertionError("offline acquisition: " + name),
                        )
                    )
                self.assertEqual(manage.install(True, False), 0 if ready else 1)
                self.assertEqual(link.called, ready)

    def test_config_conflict_is_not_overwritten(self):
        config = self.root / ".config/nvim"
        config.parent.mkdir()
        config.write_text("keep")
        self.assertFalse(
            manage.link_neovim_config(str(self.root), str(self.root / "repository"))
        )
        self.assertEqual(config.read_text(), "keep")
