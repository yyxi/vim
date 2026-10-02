"""Temporary fixtures and loading the standalone manager; no vendor probes."""

import contextlib
import importlib.machinery
import importlib.util
import io
from pathlib import Path
import sys
import tempfile
import unittest

REPOSITORY = Path(__file__).resolve().parents[1]


def load_manage(repository):
    loader = importlib.machinery.SourceFileLoader(
        "manage_under_test", str(repository / "manage")
    )
    spec = importlib.util.spec_from_loader(loader.name, loader)
    if spec is None:
        raise RuntimeError("cannot load manage")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    loader.exec_module(module)
    return module


manage = load_manage(REPOSITORY)


class FixtureTestCase(unittest.TestCase):
    def setUp(self):
        directory = self.enterContext(
            tempfile.TemporaryDirectory(prefix="manage-test-")
        )
        self.root = Path(directory)
        self.enterContext(contextlib.redirect_stdout(io.StringIO()))
        self.enterContext(contextlib.redirect_stderr(io.StringIO()))
