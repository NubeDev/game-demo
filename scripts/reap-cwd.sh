#!/bin/sh
# reap-cwd.sh — repo-scoped process/port signalling for `make kill`.
#
# Adapted from the gh-workflow repo's script of the same name; same contract, this
# project's process set. `make kill` must signal ONLY processes rooted under this
# checkout, so a shared signature never kills a sibling one. `flutter run`, `dart` and
# the Gradle daemon are signatures EVERY Flutter checkout on this box shares, and a
# command line carries no cwd — so `pkill -f 'flutter run'` cannot tell two checkouts
# apart. `reap` resolves each candidate PID's cwd and signals only those under REPO_ROOT.
#
# Usage:
#   reap-cwd.sh reap     <REPO_ROOT> <signal> <pgrep-pattern>   # signal repo-scoped matches
#   reap-cwd.sh freeport <REPO_ROOT> <signal> <tcp-port>        # signal repo-scoped listener
#   reap-cwd.sh alive    <REPO_ROOT> <pgrep-pattern>            # print "x" if any still alive
#   reap-cwd.sh whoport  <REPO_ROOT> <tcp-port>                 # describe a FOREIGN listener
#
# `readlink /proc/<pid>/cwd` is the Linux fast path; `lsof -a -p <pid> -d cwd` covers
# macOS, where /proc does not exist (CLAUDE.md §1: macOS is a dev machine here). A PID
# whose cwd cannot be read is SKIPPED, never signalled — for a cross-repo footgun,
# failing to kill is the safe direction. freeport reports each foreign listener it
# spared, so a port that stays held names its holder instead of looking like success.
#
# SELF-EXCLUSION. `pgrep -f` matches full command lines, so every process merely
# CARRYING the pattern matches — starting with this script, whose argv is the pattern it
# was asked to search for. Without this, `reap` SIGTERMs its own caller and `alive` never
# returns empty. The walk goes up the whole ancestry to PID 1: the chain (`make kill` →
# recipe shell → this script → pgrep) is arbitrarily deep, and excluding only the
# immediate parent leaves the grandparent to be signalled, which kills the caller just as
# dead. Call sites also use a bracket class (`[f]lutter`), but that is a convention a
# future caller can forget; this does not depend on it.
self_pids=" $$ "
_p=$PPID
while [ -n "$_p" ] && [ "$_p" -gt 1 ] 2>/dev/null; do
	self_pids="$self_pids$_p "
	_p=$(ps -o ppid= -p "$_p" 2>/dev/null | tr -d ' ')
done

# is_self <pid> — true for this script, any ancestor of it, or any child it spawned.
is_self() {
	case "$self_pids" in
		*" $1 "*) return 0 ;;
	esac
	ppid=$(ps -o ppid= -p "$1" 2>/dev/null | tr -d ' ')
	[ -n "$ppid" ] && [ "$ppid" = "$$" ]
}

# is_emulator <pid> — true for the Android emulator and its helper processes.
#
# NEVER reaped by `make kill`. `flutter emulators --launch` starts qemu with its cwd set
# to whichever repo launched it, so the cwd test alone treats the emulator as ours; and
# it is a CHILD of the flutter tool process, so signalling a process group catches it
# too. But it is shared with every other Flutter project on the box and costs ~40s to
# boot, and killing it without killing its adb connection leaves it unreachable — worse
# than either running or stopped. `make kill-emulator` stops it deliberately instead.
#
# Also spares the adb server: it is long-lived, shared by every Android project, and
# reaping it makes `adb devices` come back empty until it is restarted, which makes a
# running emulator look gone.
is_emulator() {
	a=$(ps -o args= -p "$1" 2>/dev/null)
	case "$a" in
		*qemu-system*|*emulator64*|*/emulator\ *|*"/emulator/emulator"*|*crashpad_handler*) return 0 ;;
		*adb\ -L*|*"fork-server server"*) return 0 ;;
	esac
	return 1
}

pidcwd() {
	readlink "/proc/$1/cwd" 2>/dev/null && return 0
	lsof -a -p "$1" -d cwd -Fn 2>/dev/null | sed -n 's/^n//p' | head -1
}

# in_repo <cwd> <repo_root> — true if cwd is the repo root or under it. The Gradle daemon
# runs from android/, a SUBDIRECTORY, so an equality test alone would miss it.
in_repo() {
	case "$1" in
		"$2" | "$2"/*) return 0 ;;
		*) return 1 ;;
	esac
}

cmd=$1
repo=$2

case "$cmd" in
	reap)
		sig=$3; pat=$4
		for p in $(pgrep -f "$pat" 2>/dev/null); do
			is_self "$p" && continue
			is_emulator "$p" && continue
			c=$(pidcwd "$p"); [ -n "$c" ] || continue
			in_repo "$c" "$repo" && kill "-$sig" "$p" 2>/dev/null || true
		done
		;;
	freeport)
		sig=$3; port=$4
		for p in $(lsof -tiTCP:"$port" -sTCP:LISTEN 2>/dev/null); do
			is_emulator "$p" && continue
			c=$(pidcwd "$p")
			if [ -z "$c" ]; then
				echo "  note: port $port is held by pid $p, whose cwd is unreadable — not signalled." >&2
				continue
			fi
			if in_repo "$c" "$repo"; then
				kill "-$sig" "$p" 2>/dev/null || true
			else
				echo "  note: port $port is held by pid $p from ANOTHER checkout ($c) — left running." >&2
				echo "        \`make kill\` only signals processes under $repo. To take the port:" >&2
				echo "          kill $p" >&2
			fi
		done
		;;
	whoport)
		# One line per FOREIGN listener on <port>, or nothing. Nothing printed == the port
		# is free, or held by one of ours (which `kill` handles).
		port=$3
		for p in $(lsof -tiTCP:"$port" -sTCP:LISTEN 2>/dev/null); do
			c=$(pidcwd "$p")
			[ -n "$c" ] && in_repo "$c" "$repo" && continue
			cl=$(ps -o args= -p "$p" 2>/dev/null | cut -c1-70)
			echo "pid $p (${cl:-unknown}) cwd=${c:-unreadable}"
		done
		;;
	alive)
		pat=$3
		for p in $(pgrep -f "$pat" 2>/dev/null); do
			is_self "$p" && continue
			is_emulator "$p" && continue
			c=$(pidcwd "$p"); [ -n "$c" ] || continue
			in_repo "$c" "$repo" && { echo x; break; }
		done
		;;
	*)
		echo "reap-cwd.sh: unknown command '$cmd'" >&2; exit 2 ;;
esac
