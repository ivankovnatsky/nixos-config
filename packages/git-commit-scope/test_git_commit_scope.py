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

    def test_no_args_preserves_repeated_numeric_path_segment(self):
        self.write("Daily/2026/07/07.md", "entry\n")

        result = self.run_scope()

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.last_subject(), "Daily/2026/07/07: init")
        self.assertEqual(self.status_short(), "")

    def test_no_args_shortens_repeated_non_numeric_path_segment(self):
        self.write("packages/tool/tool.py", "print('hello')\n")

        result = self.run_scope()

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.last_subject(), "packages/tool: init")
        self.assertEqual(self.status_short(), "")

    def test_no_args_commits_single_staged_new_file_as_init(self):
        self.write("new-tool.py", "print('hello')\n")
        self.git("add", "new-tool.py")

        result = self.run_scope()

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.last_subject(), "new-tool: init")
        self.assertEqual(self.status_short(), "")

    def test_no_args_commits_staged_new_file_from_subdir(self):
        subdir = self.repo / "subdir"
        self.write("subdir/new-tool.py", "print('hello')\n")
        self.git("add", "subdir/new-tool.py")

        result = self.run_scope(cwd=subdir)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.last_subject(), "subdir/new-tool: init")
        self.assertEqual(self.status_short(), "")

    def test_no_args_rejects_edited_rename_without_subject(self):
        # git mv + content edit produces an R<100 rename; its new path is
        # absent from HEAD but must NOT be defaulted to "init".
        self.git("mv", "tracked.txt", "renamed.txt")
        self.write("renamed.txt", "original\nedited\n")
        self.git("add", "renamed.txt")

        result = self.run_scope()

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Subject required for modified files", result.stderr)
        self.assertEqual(self.last_subject(), "seed")

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

    def test_explicit_directory_commits_multiple_new_files_as_init(self):
        self.write("repo/existing.txt", "existing\n")
        self.git("add", "repo/existing.txt")
        self.git("commit", "-m", "add existing repo file")
        self.write("repo/new-a.txt", "a\n")
        self.write("repo/nested/new-b.txt", "b\n")

        result = self.run_scope("repo")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.last_subject(), "repo: init")
        self.assertEqual(self.status_short(), "")

    def test_ignored_directory_does_not_commit_unrelated_staged_change(self):
        self.write(".gitignore", "ignored/\n")
        self.git("add", ".gitignore")
        self.git("commit", "-m", "ignore directory")
        self.write("ignored/new.txt", "new\n")
        self.write("unrelated.txt", "unrelated\n")
        self.git("add", "unrelated.txt")

        result = self.run_scope("ignored")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.last_subject(), "ignored: init")
        self.assertEqual(self.status_short(), "A  unrelated.txt")

    def test_directory_rename_requires_explicit_subject(self):
        self.write("old/file.txt", "old\n")
        self.git("add", "old/file.txt")
        self.git("commit", "-m", "add old directory")
        self.git("mv", "old", "new")

        result = self.run_scope("new")

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("looks like a file path, not a subject", result.stderr)
        self.assertEqual(self.last_subject(), "add old directory")

    def test_repository_root_commits_multiple_new_files_as_init(self):
        self.write("new-a.txt", "a\n")
        self.write("nested/new-b.txt", "b\n")

        result = self.run_scope(".")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.last_subject(), ".: init")
        self.assertEqual(self.status_short(), "")

    def test_new_directory_symlink_commits_as_init(self):
        target = self.repo / "target"
        target.mkdir()
        os.symlink("target", self.repo / "link")

        result = self.run_scope("link")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.last_subject(), "link: init")
        self.assertEqual(self.status_short(), "")

    def test_new_nested_repository_commits_gitlink_as_init(self):
        nested = self.repo / "nested-repo"
        nested.mkdir()
        subprocess.run(
            ["git", "init"], cwd=nested, env=self.env, check=True, capture_output=True
        )
        subprocess.run(
            ["git", "config", "commit.gpgsign", "false"],
            cwd=nested,
            env=self.env,
            check=True,
        )
        (nested / "file.txt").write_text("nested\n")
        subprocess.run(
            ["git", "add", "file.txt"], cwd=nested, env=self.env, check=True
        )
        subprocess.run(
            ["git", "commit", "-m", "seed nested repo"],
            cwd=nested,
            env=self.env,
            check=True,
            capture_output=True,
        )

        result = self.run_scope("nested-repo")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.last_subject(), "nested-repo: init")
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

    def test_body_line_over_80_chars_rejected(self):
        self.write("new.txt", "x\n")
        # Long line with whitespace so single-token exemption does not apply.
        long_body = ("word " * 20).strip()
        self.assertGreater(len(long_body), 80)

        result = self.run_scope("new.txt", "init", "-b", long_body)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Body line(s) exceed 80 chars", result.stderr)
        # No commit was created
        self.assertEqual(self.last_subject(), "seed")

    def test_body_line_exactly_80_chars_accepted(self):
        self.write("new.txt", "x\n")
        # 80 chars with spaces.
        body80 = ("word " * 16).strip()
        self.assertEqual(len(body80), 79)
        body80 = body80 + "x"  # pad to 80
        self.assertEqual(len(body80), 80)

        result = self.run_scope("new.txt", "init", "-b", body80)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.last_subject(), "new: init")

    def test_body_multiline_long_line_rejected(self):
        self.write("new.txt", "x\n")
        long_with_spaces = ("word " * 20).strip()
        body = "short\n" + long_with_spaces

        result = self.run_scope("new.txt", "init", "-b", body)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Body line(s) exceed 80 chars", result.stderr)

    def test_body_single_token_over_80_chars_accepted(self):
        """Unbreakable lines (no whitespace) like long URLs are exempt."""
        self.write("new.txt", "x\n")
        long_url = "https://example.com/" + ("a" * 100)
        self.assertGreater(len(long_url), 80)
        self.assertNotIn(" ", long_url)

        result = self.run_scope("new.txt", "init", "-b", long_url)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.last_subject(), "new: init")

    def test_long_path_collapses_middle_to_asterisk(self):
        # A 3-segment path with a long filename overflows 72 chars; instead of
        # dropping the filename we keep it and collapse the middle to '*'.
        fname = "HarvardCS502023FullComputerScienceUniversityCourse.md"
        self.write(f"Settings/Learning/{fname}", "x\n")

        result = self.run_scope()

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.last_subject(),
            "Settings/*/HarvardCS502023FullComputerScienceUniversityCourse: init",
        )
        self.assertIn("collapsed middle", result.stderr)
        self.assertEqual(self.status_short(), "")

    def test_collapse_preserves_leading_segments_when_possible(self):
        # Deeper path: keep as many leading segments as still fit.
        fname = "HarvardCS502023FullComputerScienceUniversityCourse.md"
        self.write(f"Settings/Learning/Courses/Online/{fname}", "x\n")

        result = self.run_scope()

        self.assertEqual(result.returncode, 0, result.stderr)
        subject = self.last_subject()
        self.assertTrue(subject.startswith("Settings/"), subject)
        self.assertIn("/*/", subject)
        self.assertTrue(
            subject.endswith(
                "HarvardCS502023FullComputerScienceUniversityCourse: init"
            ),
            subject,
        )
        self.assertLessEqual(len(subject), 72)
        self.assertEqual(self.status_short(), "")

    def test_body_two_short_flags_accepted(self):
        """Two -b flags, each ≤80, should be joined and accepted."""
        self.write("new.txt", "x\n")

        result = self.run_scope(
            "new.txt", "init", "-b", "first short line", "-b", "second short line"
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.last_subject(), "new: init")


if __name__ == "__main__":
    unittest.main()
