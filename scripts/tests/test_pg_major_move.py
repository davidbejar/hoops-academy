"""Black-box tests of scripts/pg-major-move.sh (WP144, ADR-0073): the move of the compose database to the PostgreSQL major
of compose.yaml, and its clean-up of the copies a move leaves (WP154, P-14). Podman and just are stubs on PATH that log
every call; nothing here touches a real container, volume or dump.
Run: python3 -I -m unittest discover -s scripts/tests"""
import os
import pathlib
import stat
import subprocess
import tempfile
import textwrap
import time
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts/pg-major-move.sh"
VERIFIER = "SCRAM-SHA-256$4096:c2FsdA==$planted-verifier-never-printed"

PODMAN = textwrap.dedent(f"""\
    #!/usr/bin/env bash
    echo "podman $*" >> "$STUB_LOG"
    case "$*" in
      "inspect --format {{{{.State.Running}}}} "*) echo "${{STUB_RUNNING:-true}}" ;;
      "inspect --format "*Mounts*) echo "${{STUB_MOUNTS:-hoops_pgdata:/var/lib/postgresql/data}}" ;;
      "volume exists "*) case " $STUB_VOLUMES " in *" ${{3}} "*) exit 0 ;; *) exit 1 ;; esac ;;
      "volume inspect --format {{{{.CreatedAt.Unix}}}} "*) echo "${{STUB_CREATED:-0}}" ;;
      "volume rm "*) ;;
      "ps -a --filter volume="*) echo "${{STUB_USERS:-}}" ;;
      *"show server_version_num"*) if [ -f "$STUB_STATE/up" ]; then echo 190000; else echo "${{STUB_OLD:-170007}}"; fi ;;
      *"show standard_conforming_strings"*) echo "${{STUB_SCS:-on}}" ;;
      *pg_dumpall*)
        printf '%s\\n' '--' '-- PostgreSQL database cluster dump' '--' \\
          "ALTER ROLE core_app WITH LOGIN PASSWORD '{VERIFIER}';" '--' '-- PostgreSQL database cluster dump complete' '--' ;;
      *) echo "unexpected podman call: $*" >&2; exit 99 ;;
    esac
    """)
JUST = textwrap.dedent("""\
    #!/usr/bin/env bash
    echo "just $*" >> "$STUB_LOG"
    [ "$1" != up ] || [ -z "${STUB_UP_FAILS:-}" ] || exit 3
    [ "$1" != up ] || touch "$STUB_STATE/up"
    """)


class Harness(unittest.TestCase):
    """Stub podman and just on PATH, a call log, a dump directory that does not exist yet."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        base = pathlib.Path(self.tmp.name)
        self.bin, self.state, self.out = base / "bin", base / "state", base / "dumps"
        self.bin.mkdir()
        self.state.mkdir()
        for name, body in (("podman", PODMAN), ("just", JUST)):
            (self.bin / name).write_text(body)
            (self.bin / name).chmod(0o755)
        self.log = base / "calls.log"
        self.log.touch()

    def tearDown(self):
        self.tmp.cleanup()

    def run_move(self, *args, **env):
        environment = {"PATH": f"{self.bin}:/usr/bin:/bin", "STUB_LOG": str(self.log), "STUB_STATE": str(self.state),
                       "STUB_VOLUMES": "hoops_pgdata", "HOME": os.environ.get("HOME", "/tmp"), **env}
        done = subprocess.run(["bash", str(SCRIPT), *args], capture_output=True, text=True, env=environment, cwd=ROOT)
        return done.returncode, done.stdout + done.stderr, self.log.read_text().splitlines()

    def dumps(self):
        return sorted(self.out.glob("*.sql")) if self.out.exists() else []


class PgMajorMove(Harness):

    # --- arguments
    def test_without_arguments_it_prints_the_usage_and_calls_nothing(self):
        code, out, calls = self.run_move()
        self.assertEqual(code, 2, out)
        self.assertIn("usage", out.lower())
        self.assertEqual(calls, [])

    def test_an_unknown_option_is_refused(self):
        code, out, calls = self.run_move("--out", str(self.out), "--force")
        self.assertEqual(code, 2, out)
        self.assertEqual(calls, [])

    def test_the_dump_directory_must_be_absolute_and_outside_the_repository(self):
        for out in ("dumps", str(ROOT / "tmp-dumps")):
            code, text, calls = self.run_move("--out", out)
            self.assertEqual(code, 2, text)
            self.assertEqual(calls, [])

    # --- dry run (the default)
    def test_the_default_is_a_dry_run_that_only_reads(self):
        code, out, calls = self.run_move("--out", str(self.out))
        self.assertEqual(code, 0, out)
        self.assertIn("dry run", out.lower())
        self.assertFalse([c for c in calls if c.startswith("just ") or "pg_dumpall" in c], calls)
        self.assertEqual(self.dumps(), [])
        self.assertIn("pg_dumpall", out)  # says what --apply would run
        self.assertIn("just up", out)

    # --- apply
    def test_apply_dumps_privately_then_recreates_the_stack_on_the_new_volume(self):
        code, out, calls = self.run_move("--out", str(self.out), "--apply")
        self.assertEqual(code, 0, out)
        [dump] = self.dumps()
        self.assertEqual(stat.S_IMODE(dump.stat().st_mode), 0o600)
        self.assertEqual(stat.S_IMODE(self.out.stat().st_mode), 0o700)
        self.assertIn("cluster dump complete", dump.read_text())
        self.assertIn("pg17", dump.name)
        self.assertTrue(dump.with_suffix(".sql.sha256").exists())
        just = [c for c in calls if c.startswith("just ")]
        self.assertEqual(just, ["just down", "just up"])
        self.assertLess(next(i for i, c in enumerate(calls) if "pg_dumpall" in c), calls.index("just down"))
        self.assertIn("hoops_pgdata-19", out)
        self.assertIn("way back", out.lower())
        self.assertIn("hoops_pgdata", out)

    def test_no_password_or_verifier_is_ever_printed(self):
        code, out, _ = self.run_move("--out", str(self.out), "--apply")
        self.assertEqual(code, 0, out)
        self.assertNotIn("planted-verifier", out)
        self.assertNotIn("PASSWORD '", out)

    def test_the_old_volume_is_never_removed_by_the_move(self):
        _, out, calls = self.run_move("--out", str(self.out), "--apply")
        for call in calls:
            self.assertNotRegex(call, r"volume (rm|prune)|\brm\b.*-v|down -v|--volumes", call)
        text = SCRIPT.read_text()
        self.assertNotRegex(text, r"down -v|--volumes|system prune|volume prune")
        start, end = text.index("# --- clean-up (P-14)"), text.index("# --- end of clean-up")
        self.assertNotRegex(text[:start] + text[end:], r"volume (rm|remove)", "only the clean-up step removes a volume")
        self.assertIn("--clean-up", out)  # the closing message names the clean-up step

    def test_dump_only_stops_after_the_dump(self):
        code, out, calls = self.run_move("--out", str(self.out), "--apply", "--dump-only")
        self.assertEqual(code, 0, out)
        self.assertEqual(len(self.dumps()), 1)
        self.assertFalse([c for c in calls if c.startswith("just ")], calls)

    def test_container_and_old_volume_can_be_named(self):
        code, out, calls = self.run_move("--out", str(self.out), "--apply", "--dump-only", "--container", "pg-throwaway",
                                         "--old-volume", "throwaway_data", STUB_VOLUMES="throwaway_data",
                                         STUB_MOUNTS="throwaway_data:/var/lib/postgresql/data")
        self.assertEqual(code, 0, out)
        self.assertTrue(any("exec" in c and "pg-throwaway" in c and "pg_dumpall" in c for c in calls), calls)

    def test_a_failed_just_up_after_just_down_says_what_to_do_by_hand(self):
        code, out, calls = self.run_move("--out", str(self.out), "--apply", STUB_UP_FAILS="1")
        self.assertEqual(code, 1, out)
        self.assertEqual([c for c in calls if c.startswith("just ")], ["just down", "just up"])
        self.assertEqual(len(self.dumps()), 1)
        self.assertIn("just up by hand", out)
        self.assertIn("way back", out.lower())

    # --- refusals: nothing dumped, nothing stopped
    def refused(self, *args, **env):
        code, out, calls = self.run_move("--out", str(self.out), "--apply", *args, **env)
        self.assertEqual(code, 1, out)
        self.assertEqual(self.dumps(), [])
        self.assertFalse([c for c in calls if c.startswith("just ") or "pg_dumpall" in c], calls)
        return out

    def test_refused_when_the_new_volume_already_exists(self):
        self.assertIn("hoops_pgdata-19", self.refused(STUB_VOLUMES="hoops_pgdata hoops_pgdata-19"))

    def test_refused_when_the_container_is_not_running(self):
        self.refused(STUB_RUNNING="false")

    def test_refused_when_the_container_does_not_use_the_old_volume(self):
        self.refused(STUB_MOUNTS="other:/var/lib/postgresql/data")

    def test_refused_when_the_database_already_runs_the_major_of_compose(self):
        self.refused(STUB_OLD="190000")

    def test_refused_when_standard_conforming_strings_is_off(self):
        self.assertIn("standard_conforming_strings", self.refused(STUB_SCS="off"))


class CleanUp(Harness):
    """--clean-up (P-14): lists the old volume and the dumps with their age; removes them only with --remove and the
    words typed at a terminal, after the move is done, never a volume compose names or a container uses."""
    DAY = 86400

    def setUp(self):
        super().setUp()
        self.out.mkdir(mode=0o700)
        old = time.time() - 20 * self.DAY
        self.copies = [self.out / "pg_dumpall-hoops-postgres-pg17-20261101T100000Z.sql",
                       self.out / "pg_dumpall-hoops-postgres-pg17-20261101T100000Z.sql.sha256"]
        for copy in self.copies:
            copy.write_text("x")
            os.utime(copy, (old, old))
        self.other = self.out / "notes.txt"
        self.other.write_text("kept")
        self.after_move = {"STUB_OLD": "190000", "STUB_MOUNTS": "hoops_pgdata-19:/var/lib/postgresql",
                           "STUB_CREATED": str(int(old)), "STUB_VOLUMES": "hoops_pgdata hoops_pgdata-19"}

    def clean(self, *args, typed=None, **env):
        """Runs --clean-up; with typed= the words arrive on a terminal (a pty), as only a person at one can give them."""
        if typed is None:
            return self.run_move("--clean-up", "--out", str(self.out), *args, **{**self.after_move, **env})
        import pty
        master, slave = pty.openpty()
        environment = {"PATH": f"{self.bin}:/usr/bin:/bin", "STUB_LOG": str(self.log), "STUB_STATE": str(self.state),
                       "HOME": os.environ.get("HOME", "/tmp"), **self.after_move, **env}
        os.write(master, (typed + "\n").encode())
        done = subprocess.run(["bash", str(SCRIPT), "--clean-up", "--out", str(self.out), *args], stdin=slave,
                              capture_output=True, text=True, env=environment, cwd=ROOT, timeout=30)
        os.close(slave)
        os.close(master)
        return done.returncode, done.stdout + done.stderr, self.log.read_text().splitlines()

    def removed_volumes(self, calls):
        return [c for c in calls if c.startswith("podman volume rm")]

    def test_the_default_lists_the_copies_with_their_age_and_removes_nothing(self):
        code, out, calls = self.clean()
        self.assertEqual(code, 0, out)
        self.assertIn("hoops_pgdata", out)
        self.assertIn("20 days", out)
        for copy in self.copies:
            self.assertIn(copy.name, out)
            self.assertTrue(copy.exists())
        self.assertNotIn("notes.txt", out)
        self.assertEqual(self.removed_volumes(calls), [])
        self.assertIn("--remove", out)  # says how

    def test_remove_without_a_terminal_refuses(self):
        code, out, calls = self.clean("--remove")
        self.assertEqual(code, 1, out)
        self.assertIn("terminal", out)
        self.assertEqual(self.removed_volumes(calls), [])
        self.assertTrue(all(copy.exists() for copy in self.copies))

    def test_remove_with_other_words_typed_removes_nothing(self):
        code, out, calls = self.clean("--remove", typed="yes")
        self.assertEqual(code, 1, out)
        self.assertEqual(self.removed_volumes(calls), [])
        self.assertTrue(all(copy.exists() for copy in self.copies))

    def test_remove_with_the_words_typed_removes_the_old_volume_and_the_dumps_only(self):
        code, out, calls = self.clean("--remove", typed="remove hoops_pgdata")
        self.assertEqual(code, 0, out)
        self.assertEqual(self.removed_volumes(calls), ["podman volume rm hoops_pgdata"])
        self.assertFalse(any(copy.exists() for copy in self.copies))
        self.assertTrue(self.other.exists())

    def test_refused_for_the_volume_compose_names(self):
        code, out, calls = self.clean("--old-volume", "hoops_pgdata-19")
        self.assertEqual(code, 1, out)
        self.assertEqual(self.removed_volumes(calls), [])

    def test_remove_refused_while_a_container_uses_the_old_volume(self):
        code, out, calls = self.clean("--remove", typed="remove hoops_pgdata", STUB_USERS="hoops-old-postgres")
        self.assertEqual(code, 1, out)
        self.assertIn("hoops-old-postgres", out)
        self.assertEqual(self.removed_volumes(calls), [])

    def test_remove_refused_before_the_move_is_done(self):
        code, out, calls = self.clean("--remove", typed="remove hoops_pgdata", STUB_OLD="170007",
                                      STUB_MOUNTS="hoops_pgdata:/var/lib/postgresql/data")
        self.assertEqual(code, 1, out)
        self.assertEqual(self.removed_volumes(calls), [])
        self.assertTrue(all(copy.exists() for copy in self.copies))

    def test_remove_belongs_to_the_clean_up(self):
        code, out, calls = self.run_move("--out", str(self.out), "--remove")
        self.assertEqual(code, 2, out)
        self.assertEqual(calls, [])


if __name__ == "__main__":
    unittest.main()
