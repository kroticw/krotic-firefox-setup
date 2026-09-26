# krotic-firefox-setup

My Firefox customization layer: [Natsumi Browser](https://github.com/greeeen-dev/natsumi-browser)
on vertical tabs, plus a set of fixes and tweaks for tab groups.

This is **not** a browser profile. No history, bookmarks, cookies, passwords or
extension data are published here — only stylesheets and preferences.

## What you get

- **Tab groups that read as groups.** Each group header is a pill with an accent
  stripe in the group's own colour, and the stripe runs unbroken down the side of
  every tab in an expanded group.
- **A fix for collapsed-group spacing.** Natsumi keeps the tabs of a collapsed
  group in the layout flow to animate the collapse, but leaves their vertical
  margins in place, so the gap under a collapsed group grows with the number of
  tabs it holds. This zeroes the box model of those hidden tabs and keeps the
  animation.
- **A persistent accent outline on the address bar.**
- **Saner session settings.** Restore the previous session, and keep 10 closed
  windows and 50 closed tabs instead of the stock 3 and 25.

## Requirements

- macOS
- Firefox, Firefox Developer Edition or Firefox Nightly
- `curl` and `tar`

Linux is not wired up yet: fx-autoconfig puts its program files next to the
`firefox` binary there rather than inside an `.app` bundle. Everything else
would work unchanged.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/kroticw/krotic-firefox-setup/master/install.sh | bash
```

The script writes into your Firefox application bundle and profile. If you would
rather read it before running it — which is the sensible thing to do with any
installer — clone and run it from there:

```bash
git clone https://github.com/kroticw/krotic-firefox-setup.git
cd krotic-firefox-setup
./install.sh
```

**Quit Firefox with Cmd+Q first.** A running Firefox rewrites `prefs.js` when it
exits and will undo the install.

Start Firefox afterwards and the setup is live.

## What the installer actually does

1. Finds your Firefox bundle and your profile. Profiles come from the
   `[Install*]` sections of `profiles.ini`, which name the profile each
   installation really uses; if there is more than one you are asked to pick.
2. Downloads [fx-autoconfig](https://github.com/MrOtherGuy/fx-autoconfig) at a
   pinned commit and [Natsumi Browser](https://github.com/greeeen-dev/natsumi-browser)
   at a pinned tag. Neither is vendored into this repository.
3. Backs up your current `chrome/`, `user.js` and `config.js` into
   `<profile>/krotic-firefox-setup-backup-<timestamp>/`.
4. Copies `config.js` and `defaults/pref/config-prefs.js` into the application
   bundle, and `utils/`, `JS/`, `CSS/`, `resources/` into the profile's `chrome/`.
   `utils/chrome.manifest` is then replaced with the one from Natsumi's install
   instructions, which points fx-autoconfig at Natsumi's scripts.
5. Copies Natsumi into `chrome/natsumi/`.
6. Copies this repository's `userChrome.css`, `userContent.css`,
   `natsumi-config.css`, `assets/` and `user.js`.

Re-running is safe and expected.

### Environment overrides

| Variable | Purpose |
| --- | --- |
| `FIREFOX_APP` | Path to the `.app` bundle |
| `FIREFOX_PROFILE` | Path to the profile directory |
| `NATSUMI_VERSION` | Natsumi git tag |
| `FXAC_COMMIT` | fx-autoconfig commit SHA |
| `ASSUME_YES` | Set to `1` to skip every prompt |

## Configuration

### Accent colour and new tab background

`profile/chrome/natsumi-config.css`:

```css
--natsumi-accent-color: #7b5cff;
--home-background-url: url("assets/home-background.jpg");
```

The background ships with the repository and is installed next to the
stylesheet, so it works offline. Point the variable at a URL to use your own
image, or comment the line out to keep the stock Natsumi background. The
`natsumi.home.custom-background` preference in `user.js` controls whether a
custom background is used at all.

### Tab group stripe

`profile/chrome/userChrome.css`:

```css
:root {
  --fx-group-line-width: 3px;
  --fx-group-line-inset: 2px;
}
```

The stripe is positioned relative to the tab element, offset by
`--tab-inner-inline-margin + --fx-group-line-inset - 15px`. The `15px` mirrors
the `margin-left` Natsumi applies to tabs inside a group in
`modules/folders.css`. If a future Natsumi release changes that value, the
stripe will drift and this is the number to update.

### Preferences

`profile/user.js` is reapplied on every start. That is what makes it survive
Firefox rewriting `prefs.js` on exit, and it also means edits made through
`about:config` to these particular preferences will not stick — edit the file.

## Updating

A Firefox update replaces the files inside the application bundle, including
`config.js`. When Natsumi stops loading after a browser update, re-run the
installer.

## Uninstall

Restore the backup the installer made:

```bash
PROFILE="$HOME/Library/Application Support/Firefox/Profiles/<your-profile>"
BACKUP="$PROFILE/krotic-firefox-setup-backup-<timestamp>"

rm -rf "$PROFILE/chrome"
cp -R "$BACKUP/chrome" "$PROFILE/chrome"
cp "$BACKUP/user.js" "$PROFILE/user.js"
```

For a clean Firefox, remove `chrome/`, `user.js`, and `config.js` plus
`defaults/pref/config-prefs.js` from the application bundle.

## A note on tab groups

Closing a window on macOS does not quit Firefox. Tab groups from a window closed
that way are not lost, but they move to the saved groups list instead of being
restored with the session, which looks a lot like losing them. Quit with Cmd+Q.

### Getting a session back

If the groups are not in the saved list either, they are still in the session
store — until they age out. The store lives in the profile:

```
<profile>/sessionstore-backups/recovery.jsonlz4
```

It is not JSON. The format is mozlz4: a `mozLz40` magic followed by an LZ4
block, so it has to be decompressed before anything can read it. Once decoded,
two separate top-level keys matter, and confusing them is what makes a session
look lost:

- `savedGroups` — groups that were saved rather than restored, which is where a
  window closed with Cmd+W puts them;
- `_closedWindows` — recently closed windows, capped by
  `browser.sessionstore.max_windows_undo`.

That cap is why the preferences here raise the undo limits from the stock 3
windows and 25 tabs to 10 and 50. It is not a convenience setting: once a closed
window falls off the end of `_closedWindows` it is genuinely gone, and the length
of that list is the length of the safety net.

## Hacking

Notes on editing the stylesheets — how to read the stock rules that Natsumi and
this repo override, and the two layout mistakes worth not repeating — are in
[docs/hacking.md](docs/hacking.md).

## Credits

- [Natsumi Browser](https://github.com/greeeen-dev/natsumi-browser) by
  Green (@greeeen-dev) — MIT
- [fx-autoconfig](https://github.com/MrOtherGuy/fx-autoconfig) by
  MrOtherGuy — MIT

Both are downloaded from their own repositories at install time. This repository
contains only its own stylesheets, preferences and installer.

## License

MIT. See [LICENSE](LICENSE).
