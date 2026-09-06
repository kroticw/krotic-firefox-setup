# Hacking on the stylesheets

Notes for editing `userChrome.css` against Natsumi, written after getting the
same two things wrong twice. Verified against Firefox 155 and Natsumi 6.12.2
(clicky); the selectors move between Natsumi releases, the method does not.

## Read the stock rule before you override it

Firefox ships its chrome CSS inside `omni.ja`, which is an ordinary zip archive
despite the extension. There are two of them in the application bundle:

```
<Firefox>.app/Contents/Resources/omni.ja          # toolkit
<Firefox>.app/Contents/Resources/browser/omni.ja  # browser
```

Unpack a copy somewhere scratch and read the rule you are about to fight:

```bash
mkdir -p /tmp/omni && cd /tmp/omni
unzip -o "/Applications/Firefox Developer Edition.app/Contents/Resources/browser/omni.ja"
grep -rn "tab-group" chrome/browser/skin/ | head
```

Then find Natsumi's own rule for the same element. You are writing a third layer
on top of two, and the only way to know which one wins is to have both in front
of you. Guessing at specificity and adding `!important` until something moves is
how you end up with a stylesheet nobody can change later.

## Anchor to the element that carries the margin

Both times a layout fix misbehaved, the cause was the same: the rule was
attached to a nested element while the spacing came from an ancestor's `margin`.
The nested element moved, the box did not, and the gap stayed.

Before writing a position or size rule, find which element actually owns the box
model for that gap — the one with a non-zero `margin` in the computed styles —
and write the rule against that element. The collapsed-group fix turns entirely
on this: the hidden tabs keep their margins, so the margins are what has to be
zeroed, not the visibility of their children.

## Use the Browser Toolbox, not restarts

`userChrome.css` is read at startup, so a restart per iteration is slow and
hides mistakes. Enable `devtools.chrome.enabled` and
`devtools.debugger.remote-enabled` in `about:config`, open the Browser Toolbox,
and edit the live rules there first. Move a change into `userChrome.css` only
once it does what you want in the inspector.
