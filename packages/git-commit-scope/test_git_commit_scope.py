#!/usr/bin/env python3

import os
import pathlib
import subprocess
import sys
import tempfile
import unittest


SCRIPT = pathlib.Path(__file__).with_name("git-commit-scope.py")


class GitCommitScopeTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.repo = pathlib.Path(self.tmp.name)
        self.env = os.environ.copy()
        self.env.update(
            {
                "GIT_AUTHOR_EMAIL": "test@example.invalid",
                "GIT_AUTHOR_NAME": "Test User",
                "GIT_COMMITTER_EMAIL": "test@example.invalid",
                "GIT_COMMITTER_NAME": "Test User",
            }
        )
        self.git("init")
        self.git("config", "commit.gpgsign", "false")
        self.git("config", "user.email", "test@example.invalid")
        self.git("config", "user.name", "Test User")
        self.write("tracked.txt", "original\n")
        self.git("add", "tracked.txt")
        self.git("commit", "-m", "seed")

    def tearDown(self):
        self.tmp.cleanup()

    def git(self, *args):
        return subprocess.run(
            ["git", *args],
            cwd=self.repo,
            env=self.env,
            check=True,
            capture_output=True,
            text=True,
        )

    def write(self, path, content):
        target = self.repo / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content)

    def run_scope(self, *args, cwd=None):
        return subprocess.run(
            [sys.executable, str(SCRIPT), *args],
            cwd=cwd or self.repo,
            env=self.env,
            capture_output=True,
            text=True,
        )

    def last_subject(self):
        return self.git("log", "-1", "--pretty=%s").stdout.strip()

    def status_short(self):
        return self.git("status", "--short").stdout.strip()

    def test_no_args_commits_single_untracked_file_as_init(self):
        self.write("new-tool.py", "print('hello')\n")

        result = self.run_scope()

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.last_subject(), "new-tool: init")
        self.assertEqual(self.status_short(), "")

    def test_no_args_commits_single_deleted_file_as_remove(self):
        (self.repo / "tracked.txt").unlink()

        result = self.run_scope()

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.last_subject(), "tracked: remove")
        self.assertEqual(self.status_short(), "")

    def test_no_args_commits_deleted_file_from_subdir(self):
        subdir = self.repo / "subdir"
        subdir.mkdir()
        (self.repo / "tracked.txt").unlink()

        result = self.run_scope(cwd=subdir)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.last_subject(), "tracked: remove")
        self.assertEqual(self.status_short(), "")

    def test_no_args_deleted_root_path_ignores_same_name_subdir_file(self):
        subdir = self.repo / "subdir"
        self.write("subdir/tracked.txt", "subdir\n")
        self.git("add", "subdir/tracked.txt")
        self.git("commit", "-m", "add subdir file")
        (self.repo / "tracked.txt").unlink()

        result = self.run_scope(cwd=subdir)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.last_subject(), "tracked: remove")
        self.assertEqual((subdir / "tracked.txt").read_text(), "subdir\n")
        self.assertEqual(self.status_short(), "")

    def test_no_args_commits_untracked_file_from_subdir(self):
        subdir = self.repo / "subdir"
        self.write("subdir/new-tool.py", "print('hello')\n")

        result = self.run_scope(cwd=subdir)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.last_subject(), "subdir/new-tool: init")
        self.assertEqual(self.status_short(), "")

    def test_explicit_deleted_file_from_subdir_preserves_cwd_path(self):
        subdir = self.repo / "subdir"
        self.write("subdir/file.txt", "subdir\n")
        self.git("add", "subdir/file.txt")
        self.git("commit", "-m", "add subdir file")
        (subdir / "file.txt").unlink()

        result = self.run_scope("file.txt", "remove", cwd=subdir)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.last_subject(), "subdir/file: remove")
        self.assertEqual(self.status_short(), "")

    def test_explicit_deleted_root_file_from_subdir_preserves_root_path(self):
        subdir = self.repo / "subdir"
        subdir.mkdir()
        (self.repo / "tracked.txt").unlink()

        result = self.run_scope("tracked.txt", "remove", cwd=subdir)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.last_subject(), "tracked: remove")
        self.assertEqual(self.status_short(), "")

    def test_no_args_rejects_modified_file_without_subject(self):
        self.write("tracked.txt", "changed\n")

        result = self.run_scope()

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Subject required for modified files", result.stderr)
        self.assertEqual(self.last_subject(), "seed")
        self.assertEqual(self.status_short(), "M tracked.txt")

    def test_no_args_rejects_replaced_file_without_subject(self):
        self.git("rm", "tracked.txt")
        self.write("tracked.txt", "replacement\n")

        result = self.run_scope()

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Subject required for replaced files", result.stderr)
        self.assertEqual(self.last_subject(), "seed")
        self.assertIn("D  tracked.txt", self.status_short())
        self.assertIn("?? tracked.txt", self.status_short())

    def test_no_args_rejects_replaced_root_file_from_subdir(self):
        subdir = self.repo / "subdir"
        subdir.mkdir()
        self.git("rm", "tracked.txt")
        self.write("tracked.txt", "replacement\n")

        result = self.run_scope(cwd=subdir)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Subject required for replaced files", result.stderr)
        self.assertEqual(self.last_subject(), "seed")
        self.assertIn("D  tracked.txt", self.status_short())
        self.assertIn("?? tracked.txt", self.status_short())


    def test_directory_deletion_from_subdir_resolves_root_path(self):
        self.write("dir/a.txt", "a\n")
        self.git("add", "dir/a.txt")
        self.git("commit", "-m", "add dir")
        self.git("rm", "dir/a.txt")
        subdir = self.repo / "subdir"
        subdir.mkdir()

        result = self.run_scope("dir", "remove", cwd=subdir)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.last_subject(), "dir: remove")
        self.assertEqual(self.status_short(), "")

    def test_directory_with_all_contents_staged_deleted(self):
        self.write("dir/a.txt", "a\n")
        self.write("dir/b.txt", "b\n")
        self.git("add", "dir/a.txt", "dir/b.txt")
        self.git("commit", "-m", "add dir")
        self.git("rm", "dir/a.txt", "dir/b.txt")

        result = self.run_scope("dir", "remove")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.last_subject(), "dir: remove")
        self.assertEqual(self.status_short(), "")


if __name__ == "__main__":
    unittest.main()
