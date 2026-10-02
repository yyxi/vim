"""Read-only preflight for the documented tar extraction into a fresh clone."""

import ntpath
import os
from pathlib import Path
import posixpath
import tarfile

from support import load_manage


def inspect_headers(archive, repository):
    manage = load_manage(repository)
    lock = manage.load_git_worktrees_lock(str(repository))
    if lock is None:
        raise RuntimeError("invalid clone declarations")
    roots = {"node_modules", "vendor/python/wheels", manage.SCHEMA_CATALOG_DIR}
    runtime = manage.tree_sitter_runtime_site(str(repository), lock)
    if runtime is None:
        raise RuntimeError("missing declared Tree-sitter runtime")
    roots.add(os.path.relpath(runtime, repository).replace(os.sep, "/"))
    for source_id, source in manage.manifest_sources(lock).items():
        for function in (manage.source_repository_path, manage.source_worktree_path):
            path = function(str(repository), lock, source_id, source)
            if path is None:
                raise RuntimeError("invalid declared managed root")
            roots.add(os.path.relpath(path, repository).replace(os.sep, "/"))
    ancestors = {
        str(parent)
        for root in roots
        for parent in Path(root).parents
        if str(parent) != "."
    }
    names = set()
    links = {}
    with tarfile.open(archive, "r:gz") as source:
        for member in source:
            name = member.name.rstrip("/") if member.isdir() else member.name
            if manage.validated_relative_subpath(name) != name:
                raise RuntimeError("unsafe archive name: " + name)
            # Standard-library containment/type checks, without extracting.
            try:
                tarfile.data_filter(member, str(repository))
            except tarfile.FilterError as exc:
                raise RuntimeError(str(exc)) from exc
            if name in names:
                raise RuntimeError("duplicate archive name: " + name)
            names.add(name)
            owners = [
                root for root in roots if name == root or name.startswith(root + "/")
            ]
            if not owners and not (name in ancestors and member.isdir()):
                raise RuntimeError("undeclared archive destination: " + name)
            if (
                not (member.isfile() or member.isdir() or member.issym())
                or member.islnk()
            ):
                raise RuntimeError("special/hardlinked archive member: " + name)
            if member.mode & 0o7000:
                raise RuntimeError("unsafe archive permissions: " + name)
            if member.issym():
                target = member.linkname
                resolved = posixpath.normpath(
                    posixpath.join(posixpath.dirname(name), target)
                )
                if (
                    not target
                    or "\\" in target
                    or "\0" in target
                    or ntpath.splitdrive(target)[0]
                    or posixpath.isabs(target)
                ):
                    raise RuntimeError("unsafe archive link: " + name)
                if not any(
                    resolved == owner or resolved.startswith(owner + "/")
                    for owner in owners
                ):
                    raise RuntimeError("escaping archive link: " + name)
                links[name] = resolved
    for name in names:
        if any(str(parent) in links for parent in Path(name).parents):
            raise RuntimeError("member beneath linked ancestor: " + name)
    for name, target in links.items():
        visited = {name}
        while target in links:
            if target in visited:
                raise RuntimeError("cyclic archive link: " + name)
            visited.add(target)
            target = links[target]
        if target not in names:
            raise RuntimeError("unselected archive link target: " + name)
    return len(names)
