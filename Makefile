# Little Games — the build, check and run entry points.
# `make check` is the gate: analyze clean, tests passing, and the privacy grep.
# It is not the whole story on purpose — touch-target size, gameplay feel and
# sound are only proven under a thumb (`make run-device`), and no make target
# can assert that. See CLAUDE.md §6.
FLUTTER ?= flutter
ADB ?= adb

# The development target. Desktop is for fast iteration only — iOS and Android
# are the shipping targets, and CLAUDE.md §1 says so. macOS on a Mac, linux here.
#   make run DEV_DEVICE=macos
DEV_DEVICE ?= linux

# The Android emulator to boot. `flutter emulators` lists the ids.
EMULATOR ?= district_pixel

# How long to wait for a cold emulator to finish booting, in seconds.
EMULATOR_BOOT_TIMEOUT ?= 180

# The port `make run-web` serves on.
WEB_PORT ?= 8080

# A real phone or tablet. No default: `flutter devices` lists the ids, and a
# guessed one is worse than an error that tells you to pick.
DEVICE ?=

.PHONY: deps run run-device run-web emulator run-emulator devices emulators \
        analyze test check privacy format build-apk build-ios icons clean

deps:
	$(FLUTTER) pub get

# --- running it ---------------------------------------------------------

run: deps
	$(FLUTTER) run -d $(DEV_DEVICE)

# **The one that counts.** A green test suite is not a played game: coarse motor
# control, 80×80 targets and sound only answer on the hardware a 5-year-old holds.
#   make run-device DEVICE=<id>
run-device: deps
	@test -n "$(DEVICE)" || { \
		echo 'set DEVICE=<id> — run `make devices` for the list'; exit 1; }
	$(FLUTTER) run -d $(DEVICE)

# --- testing without a phone --------------------------------------------
#
# None of these are shipping targets (CLAUDE.md §1) — they exist so the game can
# be driven when no device is to hand. In rough order of how much they prove:
#
#   run-emulator  a real touch surface, real landscape — closest to the truth
#   run-web       a browser; what the 2026-09-17 play session used
#   run           desktop; mouse and a resizable window, logic only
#
# What none of them prove: whether an 80x80 target is big enough under a
# 5-year-old's finger. A mouse click is not a thumb. The runbook
# (docs/testing/first-play-runbook.md) still wants real hardware.

# `make run-emulator` is the one to use — it boots the emulator itself if none is
# running. This target is here for when you only want the device up (to watch it
# boot, or to warm it before a demo), and it returns before the boot finishes.
emulator:
	$(FLUTTER) emulators --launch $(EMULATOR)
	@echo 'booting — this takes a minute; `make run-emulator` waits for it'

# Boots the emulator if none is running, waits for the boot to complete, then
# runs. One command from cold: you never have to `make emulator` first, and you
# never have to guess when it is ready.
#
# Resolves the RUNNING device id rather than using $(EMULATOR): the emulator id
# ("district_pixel") launches an emulator, but `flutter run` only knows the
# device it becomes ("emulator-5554"), and rejects the former outright.
run-emulator: deps
	@id=$$($(ADB) devices | awk '/^emulator-/ {print $$1; exit}'); \
	if [ -z "$$id" ]; then \
		echo 'no emulator running — booting $(EMULATOR)'; \
		$(FLUTTER) emulators --launch $(EMULATOR) || exit 1; \
		printf 'waiting for boot '; \
		for i in $$(seq 1 $$(($(EMULATOR_BOOT_TIMEOUT) / 2))); do \
			sleep 2; \
			id=$$($(ADB) devices | awk '/^emulator-/ {print $$1; exit}'); \
			if [ -n "$$id" ] && \
			   [ "$$($(ADB) -s $$id shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; then \
				echo ' ready'; break; \
			fi; \
			id=''; printf '.'; \
		done; \
		test -n "$$id" || { \
			echo; \
			echo 'emulator did not boot within $(EMULATOR_BOOT_TIMEOUT)s.'; \
			echo 'Run `$(FLUTTER) emulators --launch $(EMULATOR)` directly to see why,'; \
			echo 'or raise the wait: make run-emulator EMULATOR_BOOT_TIMEOUT=300'; \
			exit 1; }; \
	fi; \
	echo "running on $$id"; \
	$(FLUTTER) run -d "$$id"

# `web-server` rather than `-d chrome`: it needs no Chrome on PATH (this box has
# none) and prints a URL any browser can open. The only recorded play session so
# far was headless Chrome against exactly this.
run-web: deps
	$(FLUTTER) run -d web-server --web-port=$(WEB_PORT)

devices:
	$(FLUTTER) devices

emulators:
	$(FLUTTER) emulators

# --- the gate -----------------------------------------------------------

analyze:
	$(FLUTTER) analyze

test:
	$(FLUTTER) test

# The pre-release grep CLAUDE.md §4 and HOW-TO-CODE §6 both call for, scripted so
# it is run rather than remembered. This app makes no network calls of any kind —
# that is the privacy promise, not a simplification, so a single hit is a failure
# and not a warning. `lib/` and `pubspec.yaml` only: the template's ios/ and
# android/ scaffolding mentions http in places this app never reaches.
privacy:
	@if grep -rnE "package:http|[^a-z]dio[^a-z]|dart:io.*Socket|HttpClient|firebase|analytics|crashlytics" \
		lib pubspec.yaml; then \
		echo; \
		echo 'FAIL: network or SDK reference found — see CLAUDE.md §4. Nothing leaves the device.'; \
		exit 1; \
	else \
		echo 'privacy: clean — no network, no analytics, no third-party SDK'; \
	fi

check: analyze test privacy
	@echo
	@echo 'check passed — now play it: make run-device DEVICE=<id>'
	@echo 'The kid-rules (CLAUDE.md §6) are not checkable here: no reading needed,'
	@echo 'targets >= 80x80, no way to lose, home button visible.'

format:
	dart format lib test

# --- shipping -----------------------------------------------------------

build-apk: deps
	$(FLUTTER) build apk

# The simulator build, which needs no signing identity — the one that works on
# any machine. A device build is `flutter build ios` and wants a team set up.
build-ios: deps
	$(FLUTTER) build ios --simulator

# Regenerates the launcher icons from assets/icons/icon.png (flutter_launcher_icons
# in pubspec.yaml). Only needed when that image changes.
icons: deps
	dart run flutter_launcher_icons

clean:
	$(FLUTTER) clean
