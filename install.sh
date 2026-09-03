#!/usr/bin/env bash
#
# Installs a Firefox customization layer:
#
#   1. fx-autoconfig  - lets Firefox load chrome-context scripts
#   2. Natsumi Browser - the theme itself
#   3. This repository - userChrome.css, natsumi-config.css and user.js
#
# Both dependencies are fetched from their upstream repositories at pinned
# versions. Nothing is vendored here.
#
# Usage:
#   ./install.sh                 # from a clone
#   curl -fsSL <raw-url> | bash  # standalone
#
# Environment overrides:
#   FIREFOX_APP       path to the Firefox .app bundle
#   FIREFOX_PROFILE   path to the profile directory
#   NATSUMI_VERSION   Natsumi git tag
#   FXAC_COMMIT       fx-autoconfig commit SHA
#   ASSUME_YES        set to 1 to skip every prompt

set -euo pipefail

NATSUMI_VERSION="${NATSUMI_VERSION:-v6.12.2}"
# fx-autoconfig publishes no tags, so it is pinned by commit.
FXAC_COMMIT="${FXAC_COMMIT:-dfdab5684faffc112b76ccb1d8cab7f75da0102c}"
REPO_RAW="${REPO_RAW:-https://raw.githubusercontent.com/kroticw/krotic-firefox-setup/master}"
ASSUME_YES="${ASSUME_YES:-0}"

REPO_FILES=(
  "profile/chrome/userChrome.css"
  "profile/chrome/userContent.css"
  "profile/chrome/natsumi-config.css"
  "profile/chrome/assets/home-background.jpg"
  "profile/user.js"
)

# --------------------------------------------------------------------------
# Output helpers
# --------------------------------------------------------------------------

if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'; C_DIM=$'\033[2m'
  C_RED=$'\033[31m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'
else
  C_RESET=""; C_BOLD=""; C_DIM=""; C_RED=""; C_GREEN=""; C_YELLOW=""
fi

step() { printf '%s==>%s %s\n' "$C_BOLD$C_GREEN" "$C_RESET$C_BOLD" "$*$C_RESET"; }
info() { printf '    %s\n' "$*"; }
note() { printf '    %s%s%s\n' "$C_DIM" "$*" "$C_RESET"; }
warn() { printf '%s !! %s%s\n' "$C_YELLOW" "$*" "$C_RESET" >&2; }
die()  { printf '%s !! %s%s\n' "$C_RED" "$*" "$C_RESET" >&2; exit 1; }

# Reads a line from the terminal rather than stdin, so prompts still work when
# the script itself arrives on stdin through `curl | bash`.
ask() {
  local prompt="$1" answer
  if [[ "$ASSUME_YES" == "1" ]]; then
    echo ""
    return 0
  fi
  [[ -r /dev/tty ]] || die "Need to ask a question but there is no terminal. Re-run from a clone, or set FIREFOX_PROFILE / FIREFOX_APP explicitly."
  printf '%s' "$prompt" > /dev/tty
  read -r answer < /dev/tty
  echo "$answer"
}

# --------------------------------------------------------------------------
# Preconditions
# --------------------------------------------------------------------------

[[ "$(uname -s)" == "Darwin" ]] || die "This installer currently supports macOS only. On Linux the fx-autoconfig 'program' files go next to the firefox binary instead; see https://github.com/MrOtherGuy/fx-autoconfig"

command -v curl >/dev/null || die "curl is required"
command -v tar  >/dev/null || die "tar is required"

# An explicit template keeps the scratch directory inside TMPDIR. Without one,
# the BSD mktemp on macOS ignores TMPDIR and uses the per-user Darwin temp dir.
TMP="$(mktemp -d "${TMPDIR:-/tmp}/krotic-firefox-setup.XXXXXXXX")"
trap 'rm -rf "$TMP"' EXIT

# --------------------------------------------------------------------------
# Locate the Firefox application bundle
# --------------------------------------------------------------------------

step "Locating Firefox"

if [[ -n "${FIREFOX_APP:-}" ]]; then
  APP="$FIREFOX_APP"
else
  APP=""
  for candidate in \
    "/Applications/Firefox Developer Edition.app" \
    "/Applications/Firefox.app" \
    "/Applications/Firefox Nightly.app"
  do
    if [[ -d "$candidate" ]]; then
      APP="$candidate"
      break
    fi
  done
fi

[[ -n "$APP" && -d "$APP" ]] || die "No Firefox bundle found. Set FIREFOX_APP to the .app path."
RESOURCES="$APP/Contents/Resources"
[[ -d "$RESOURCES" ]] || die "Not a Firefox bundle: $APP"
info "$APP"

if pgrep -f "$APP/Contents/MacOS" >/dev/null 2>&1; then
  die "Firefox is running. Quit it with Cmd+Q first — otherwise it will overwrite prefs.js on exit and undo this install."
fi

# --------------------------------------------------------------------------
# Locate the profile
# --------------------------------------------------------------------------

step "Locating the Firefox profile"

FF_ROOT="$HOME/Library/Application Support/Firefox"

if [[ -n "${FIREFOX_PROFILE:-}" ]]; then
  PROFILE="$FIREFOX_PROFILE"
else
  INI="$FF_ROOT/profiles.ini"
  [[ -f "$INI" ]] || die "profiles.ini not found at $INI. Set FIREFOX_PROFILE explicitly."

  # Every [InstallXXXX] section names the profile that installation actually
  # uses. That is a far better signal than the legacy Default=1 flag.
  #
  # Candidates go to a file rather than a bash array: macOS still ships bash
  # 3.2, which has no mapfile and errors on empty arrays under `set -u`.
  CAND="$TMP/profile-candidates"

  awk '
    /^\[Install/ { in_install = 1; next }
    /^\[/        { in_install = 0 }
    in_install && /^Default=/ { sub(/^Default=/, ""); sub(/\r$/, ""); print }
  ' "$INI" | sort -u > "$CAND"

  if [[ ! -s "$CAND" ]]; then
    awk '
      /^\[Profile/ { path = ""; def = 0 }
      /^Path=/     { sub(/^Path=/, ""); sub(/\r$/, ""); path = $0 }
      /^Default=1/ { def = 1 }
      /^[[:space:]]*$/ { if (def && path != "") { print path; def = 0; path = "" } }
      END          { if (def && path != "") print path }
    ' "$INI" | sort -u > "$CAND"
  fi

  [[ -s "$CAND" ]] || die "Could not determine a profile from $INI. Set FIREFOX_PROFILE explicitly."

  COUNT="$(wc -l < "$CAND" | tr -d '[:space:]')"

  if [[ "$COUNT" == "1" ]]; then
    PROFILE="$FF_ROOT/$(cat "$CAND")"
  else
    printf '    Several profiles are in use:\n'
    awk '{ printf "      %d) %s\n", NR, $0 }' "$CAND"
    choice="$(ask "    Pick one [1-$COUNT]: ")"
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > COUNT )); then
      die "Invalid choice."
    fi
    PROFILE="$FF_ROOT/$(sed -n "${choice}p" "$CAND")"
  fi
fi

[[ -d "$PROFILE" ]] || die "Profile directory does not exist: $PROFILE"
info "$PROFILE"

CHROME="$PROFILE/chrome"

# --------------------------------------------------------------------------
# Download the dependencies
# --------------------------------------------------------------------------

fetch() {
  curl -fsSL --retry 3 --max-time 120 "$1" -o "$2" \
    || die "Download failed: $1"
}

step "Downloading Natsumi Browser $NATSUMI_VERSION"
fetch "https://api.github.com/repos/greeeen-dev/natsumi-browser/tarball/$NATSUMI_VERSION" "$TMP/natsumi.tar.gz"
mkdir -p "$TMP/natsumi"
tar -xzf "$TMP/natsumi.tar.gz" -C "$TMP/natsumi" --strip-components=1
[[ -d "$TMP/natsumi/natsumi" ]] || die "Unexpected Natsumi archive layout."

step "Downloading fx-autoconfig ${FXAC_COMMIT:0:10}"
fetch "https://api.github.com/repos/MrOtherGuy/fx-autoconfig/tarball/$FXAC_COMMIT" "$TMP/fxac.tar.gz"
mkdir -p "$TMP/fxac"
tar -xzf "$TMP/fxac.tar.gz" -C "$TMP/fxac" --strip-components=1
[[ -d "$TMP/fxac/profile/chrome" && -f "$TMP/fxac/program/config.js" ]] \
  || die "Unexpected fx-autoconfig archive layout."

# --------------------------------------------------------------------------
# Collect this repository's own files
# --------------------------------------------------------------------------

step "Collecting configuration files"

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"

if [[ -n "$SELF_DIR" && -f "$SELF_DIR/profile/user.js" ]]; then
  info "using the local clone"
  for f in "${REPO_FILES[@]}"; do
    mkdir -p "$TMP/repo/$(dirname "$f")"
    cp "$SELF_DIR/$f" "$TMP/repo/$f"
  done
else
  info "downloading from $REPO_RAW"
  for f in "${REPO_FILES[@]}"; do
    mkdir -p "$TMP/repo/$(dirname "$f")"
    fetch "$REPO_RAW/$f" "$TMP/repo/$f"
  done
fi

# --------------------------------------------------------------------------
# Back up whatever is already there
# --------------------------------------------------------------------------

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$PROFILE/krotic-firefox-setup-backup-$STAMP"

if [[ -d "$CHROME" || -f "$PROFILE/user.js" ]]; then
  step "Backing up the current setup"
  mkdir -p "$BACKUP"
  if [[ -d "$CHROME" ]]; then
    cp -R "$CHROME" "$BACKUP/chrome"
  fi
  if [[ -f "$PROFILE/user.js" ]]; then
    cp "$PROFILE/user.js" "$BACKUP/user.js"
  fi
  if [[ -f "$RESOURCES/config.js" ]]; then
    cp "$RESOURCES/config.js" "$BACKUP/config.js"
  fi
  info "$BACKUP"
fi

# --------------------------------------------------------------------------
# Install
# --------------------------------------------------------------------------

step "Installing fx-autoconfig into the application bundle"

if [[ ! -w "$RESOURCES" ]]; then
  die "No write access to $RESOURCES. Re-run with sudo, or fix the bundle's permissions."
fi

cp "$TMP/fxac/program/config.js" "$RESOURCES/config.js"
mkdir -p "$RESOURCES/defaults/pref"
cp "$TMP/fxac/program/defaults/pref/config-prefs.js" "$RESOURCES/defaults/pref/config-prefs.js"
note "a Firefox update replaces these files — re-run this installer afterwards"

step "Installing fx-autoconfig into the profile"
mkdir -p "$CHROME"
for d in utils JS CSS resources; do
  if [[ -d "$TMP/fxac/profile/chrome/$d" ]]; then
    rm -rf "${CHROME:?}/$d"
    cp -R "$TMP/fxac/profile/chrome/$d" "$CHROME/$d"
  fi
done
[[ -f "$CHROME/utils/module_loader.mjs" ]] \
  || warn "module_loader.mjs is missing — Natsumi's scripts will be listed but never loaded."

step "Installing Natsumi Browser"
rm -rf "${CHROME:?}/natsumi"
cp -R "$TMP/natsumi/natsumi" "$CHROME/natsumi"

step "Installing the configuration"
cp "$TMP/repo/profile/chrome/userChrome.css"     "$CHROME/userChrome.css"
cp "$TMP/repo/profile/chrome/userContent.css"    "$CHROME/userContent.css"
cp "$TMP/repo/profile/chrome/natsumi-config.css" "$CHROME/natsumi-config.css"
cp "$TMP/repo/profile/user.js"                   "$PROFILE/user.js"

rm -rf "${CHROME:?}/assets"
cp -R "$TMP/repo/profile/chrome/assets" "$CHROME/assets"

# --------------------------------------------------------------------------
# Done
# --------------------------------------------------------------------------

step "Done"
cat <<EOF

    Start Firefox to apply the setup.

    Notes:
      - user.js is reapplied on every start, so about:config edits to the
        preferences it sets will not stick. Edit user.js instead.
      - Always quit with Cmd+Q. Closing the window on macOS does not quit
        Firefox, and tab groups from that window end up under "saved groups"
        instead of being restored.
      - A Firefox update overwrites config.js inside the app bundle. Re-run
        this installer after updating.
EOF

if [[ -d "${BACKUP:-}" ]]; then
  printf '      - Previous setup saved to:\n        %s\n\n' "$BACKUP"
fi
