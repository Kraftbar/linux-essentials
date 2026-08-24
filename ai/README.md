# Ask Claude about the selection

Highlight text anywhere, press `Super+Shift+A`, read the answer.

    askclaude                       # "Summarize this briefly."
    askclaude "Explain this code"   # any prompt
    askclaude -                     # prompt on stdin

## How it gets the text

Takes the X **PRIMARY** selection, which any highlight sets - so there is no
need to press Ctrl+C first. Falls back to the clipboard if PRIMARY is empty,
which happens in some apps and some terminal configurations.

That is the whole reason this feels quick: select an article, press the key.

## Output

A `zenity` window, scrollable and selectable. **Copy** puts the answer on the
clipboard; **Close** discards it. Without zenity it degrades to a notification
with the first 400 characters.

A progress notification shows the character count while Claude is working, so a
long article does not look like a dead hotkey. Typical latency is 3-6s.

## If the hotkey seems dead

`askclaude` logs one line per invocation to
`$XDG_RUNTIME_DIR/askclaude.log`. That separates the two failure modes, which
need looking at in completely different places:

- **A line appears** - the key fired and the problem is inside the script.
- **No line** - the keypress never arrived. Almost always this is
  `csd-media-keys` not having seen the binding: it installs its passive grabs at
  startup and does not pick up ids added to `custom-list` afterwards, so a new
  hotkey does nothing until it restarts. `apply-custom-keybindings.sh` now
  nudges it automatically. If that is not it, run
  `../config&docs/check-keybinding.sh` on the key - an applet may hold it.

The first bug here was PATH. A desktop keybinding does not inherit the login
shell's environment, so `~/.local/bin` is missing and `claude` - which lives
there - is not found. The script now prepends it. Anything else invoked from a
keybinding needs the same treatment if it is not in `/usr/bin`.

## Limits

- Input is capped at 60,000 characters (`ASKCLAUDE_MAX_CHARS`), and truncation
  is reported in the progress notification. Without a cap, selecting a whole
  documentation site sends a book and waits minutes for it.
- The call has a 180s timeout.
- It uses your normal Claude Code auth and counts against the same usage.

## More prompts

`askclaude` takes the prompt as its argument, so a second binding is just
another row in `../config&docs/custom-keybindings.tsv` pointing at the same
script:

    custom2  explain-code  ai/askclaude "Explain this code"  <Super><Shift>e

Check a candidate key is actually free first - both gsettings *and* applet
config, since applets grab keys invisibly to gsettings:

    ../config&docs/check-keybinding.sh '<Super><Shift>e'
