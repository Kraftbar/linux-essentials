```bash
#!/bin/bash

# Update package lists and install git
sudo apt update
sudo apt upgrade

sudo apt install -y git
sudo apt install openssh-server
sudo systemctl start ssh
sudo systemctl enable ssh
sudo systemctl status ssh




#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Update package list and install Samba
echo "Installing Samba..."
sudo apt update
sudo apt install -y samba

# Backup the original Samba configuration file
SAMBA_CONF="/etc/samba/smb.conf"
echo "Backing up the original Samba configuration file..."
sudo cp "$SAMBA_CONF" "${SAMBA_CONF}.bak"

# Configure Samba to share the root directory
echo "Configuring Samba to share the root directory..."
sudo bash -c "cat >> $SAMBA_CONF <<EOF

[Root]
   path = /
   browseable = yes
   read only = no
   guest ok = yes
   force user = root
EOF"

# Restart Samba services
echo "Restarting Samba service..."
sudo systemctl restart smbd

# Allow Samba through the firewall (if applicable)
echo "Configuring firewall to allow Samba..."
sudo ufw allow samba

echo "Samba has been configured to share the root directory '/' over the network."
echo "WARNING: Sharing the root directory is extremely risky. Ensure your system is secure."
echo "You can access the share from another machine using the path: \\\\your-server-ip\\Root"









# Exit if running over SSH
if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_TTY" ]; then
  echo "You are on an SSH session - so you are probably setting up a server, exiting."
  exit 1
fi

echo "Setting up Linux for desktop"

# Install required packages
sudo apt install -y python3-pip python3-gi python3-{nautilus,nemo,caja} xclip \
software-properties-common translate-shell gnuplot texlive-full jq

# Install git-nautilus-icons
pip3 install --user git-nautilus-icons

# Ensure ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    export PATH="$HOME/.local/bin:$PATH"
fi

# Install Google Chrome
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor > /tmp/google.gpg
sudo install -o root -g root -m 644 /tmp/google.gpg /etc/apt/trusted.gpg.d/google.gpg
sudo sh -c 'echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/google.gpg] \
http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list'

# Install VSCode
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/microsoft.gpg
sudo install -o root -g root -m 644 /tmp/microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/microsoft.gpg] \
https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'

# Install Spotify
curl -sS https://download.spotify.com/debian/pubkey.gpg | gpg --dearmor > /tmp/spotify.gpg
sudo install -o root -g root -m 644 /tmp/spotify.gpg /etc/apt/trusted.gpg.d/spotify.gpg
echo "deb [signed-by=/etc/apt/trusted.gpg.d/spotify.gpg] \
http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list

# Update package lists and install applications
sudo apt update
sudo apt install -y google-chrome-stable code spotify-client

# Set VSCode keybindings
mkdir -p "$HOME/.config/Code/User"
cat <<EOF > "$HOME/.config/Code/User/keybindings.json"
[
  {
      "key": "ctrl+tab",
      "command": "workbench.action.nextEditorInGroup"
  },
  {
      "key": "ctrl+shift+tab",
      "command": "workbench.action.previousEditorInGroup"
  }
]
EOF

# Install Emacs
sudo add-apt-repository -y ppa:kelleyk/emacs
sudo apt update
sudo apt install -y emacs29

# Configure Git and SSH
echo "Running this (configuring ssh) will clear the clipboard"
read -p "Continue? (y/n): " confirm && [[ $confirm =~ ^[Yy](es)?$ ]] || exit 1

git config --global user.name "Kraftbar"
git config --global user.email "gautenybo@gmail.com"
git config --global color.ui true
git config --global core.editor emacs

# Generate SSH key
ssh-keygen -t ed25519 -C "gautenybo@gmail.com"

# Copy SSH key to clipboard
xclip -selection clipboard < ~/.ssh/id_ed25519.pub

echo "Your SSH public key has been copied to the clipboard."
echo "Please add it to your GitHub account."
xdg-open "https://github.com/settings/ssh/new"

read -p "Press Enter after adding the SSH key to GitHub..." confirm

# Test SSH connection
ssh -T git@github.com

# Configure Git to use SSH instead of HTTPS
git config --global url."git@github.com:".insteadOf "https://github.com/"

echo "--------------------------------------------"
echo "---------------ssh setup done---------------"
echo "--------------------------------------------"
echo "GitHub access token"
echo "Only select repo scope"
echo "After generating the token, copy it and then close the browser"

xdg-open "https://github.com/settings/tokens/new"
read -p "Paste token: " github_token

echo "Please be aware that storing tokens in plaintext is insecure."
echo "It's recommended to use SSH keys or environment variables."

# Create Code directory
mkdir -p "$HOME/Code"

# Add Code directory to GTK bookmarks
if ! grep -q "file://$HOME/Code" "$HOME/.config/gtk-3.0/bookmarks"; then
    echo "file://$HOME/Code" >> "$HOME/.config/gtk-3.0/bookmarks"
fi

# Fetch repository list using GitHub API
repoList=$(curl -s -H "Authorization: token $github_token" \
"https://api.github.com/user/repos?per_page=100" | \
jq -r '.[] | select(.size <= 100000) | .ssh_url')

# Clone repositories
for repo in $repoList; do
  git clone "$repo" "$HOME/Code/"
done

# Symlink scripts to /usr/local/bin
for script in "$HOME/Code/linux-essentials/scripts/my"*; do
  sudo ln -sf "$(readlink -f "$script")" /usr/local/bin/
done

# Symlink Emacs configuration files
mkdir -p "$HOME/.emacs.d/"
for el_file in "$HOME/Code/linux-essentials/config&docs/dots/"*.el; do
  ln -sf "$(readlink -f "$el_file")" "$HOME/.emacs.d/"
done

# Create .latexmkrc
cat <<'EOF' > "$HOME/.latexmkrc"
# LaTeX
$latex = 'latex -synctex=1 -halt-on-error -file-line-error %O %S';
$max_repeat = 5;

# BibTeX
$bibtex = 'pbibtex %O %S';
$biber = 'biber --bblencoding=utf8 -u -U --output_safechars %O %S';

# Index
$makeindex = 'mendex %O -o %D %S';

# DVI / PDF
$dvipdf = 'dvipdfmx %O -o %D %S';
$pdf_mode = 3;

# Output directory
$out_dir = 'build_latex';

# Remove pdfsync files on clean
$clean_ext = 'pdfsync synctex.gz';

# Preview
$pvc_view_file_via_temporary = 0;
if ($^O eq 'linux') {
    $dvi_previewer = "xdg-open %S";
    $pdf_previewer = "xdg-open %S";
} elsif ($^O eq 'darwin') {
    $dvi_previewer = "open %S";
    $pdf_previewer = "open %S";
} else {
    $dvi_previewer = "start %S";
    $pdf_previewer = "start %S";
}

# Clean up
$clean_full_ext = "%R.synctex.gz";
EOF

# Unbind existing keybinding for sound settings
gsettings set org.cinnamon.desktop.keybindings.media-keys.sound-settings "['']"

# Set screenshot key
gsettings set org.cinnamon.desktop.keybindings.media-keys.area-screenshot-clip "['<Super><Shift>s']"

# Define custom keybindings
gsettings set org.cinnamon.desktop.keybindings custom-list "['custom0', 'custom1']"

# Custom keybinding 0: ocrclip (see ../ocr/ - replaced myocrclip 2026-08-24)
gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/\
keybindings/custom-keybindings/custom0/ name 'ocrclip'
gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/\
keybindings/custom-keybindings/custom0/ command 'ocrclip'
gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/\
keybindings/custom-keybindings/custom0/ binding "['<Super><Shift>c']"

# Custom keybinding 1: my text2speech
gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/\
keybindings/custom-keybindings/custom1/ name 'my text2speech'
gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/\
keybindings/custom-keybindings/custom1/ command "sh -c 'xclip -o | python3 $HOME/Code/aws-r/aws_txt2speech.py'"
gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/\
keybindings/custom-keybindings/custom1/ binding "['<Super><Shift>r']"

# Restart Cinnamon
cinnamon --replace &

# Apply patch to appSwitcher.js
echo "Applying patch to appSwitcher.js"

# Backup original file
sudo cp /usr/share/cinnamon/js/ui/appSwitcher/appSwitcher.js \
        /usr/share/cinnamon/js/ui/appSwitcher/appSwitcher.js.bak

# Create patch file
patch_content=$(cat <<'EOF'
--- /home/nybo/appSwitcher.js.bak	2023-02-04 13:13:37.481962509 +0100
+++ /usr/share/cinnamon/js/ui/appSwitcher/appSwitcher.js	2023-02-04 13:15:47.797504081 +0100
@@ -9,6 +9,8 @@
 const Main = imports.ui.main;
 const Cinnamon = imports.gi.Cinnamon;

+
+const CHECK_DESTROYED_TIMEOUT = 100;
 const DISABLE_HOVER_TIMEOUT = 500; // milliseconds

 function sortWindowsByUserTime(win1, win2) {
@@ -106,6 +108,7 @@
         this._haveModal = false;
         this._destroyed = false;
         this._motionTimeoutId = 0;
+        this._checkDestroyedTimeoutId = 0;
         this._currentIndex = this._windows.indexOf(global.display.focus_window);
         if (this._currentIndex < 0) {
             this._currentIndex = 0;
@@ -279,6 +282,14 @@
                 this._showDesktop();
                 return true;

+            case Clutter.KEY_q:
+                case Clutter.KEY_Q:
+                    // Q -> Close window
+                    this._windows[this._currentIndex].delete(global.get_current_time());
+                    this._checkDestroyedTimeoutId = Mainloop.timeout_add(CHECK_DESTROYED_TIMEOUT,
+                            Lang.bind(this, this._checkDestroyed, this._windows[this._currentIndex]));
+                    return true;
+
             case Clutter.KEY_Right:
             case Clutter.KEY_Down:
                 // Right/Down -> navigate to next preview
@@ -388,7 +399,10 @@
     _windowDestroyed: function(wm, actor) {
         this._removeDestroyedWindow(actor.meta_window);
     },
-
+    _checkDestroyed: function(window) {
+        this._checkDestroyedTimeoutId = 0;
+        this._removeDestroyedWindow(window);
+    },
     _removeDestroyedWindow: function(window) {
         for (let i in this._windows) {
             if (window == this._windows[i]) {
@@ -449,7 +463,10 @@
             Mainloop.source_remove(this._motionTimeoutId);
             this._motionTimeoutId = 0;
         }
-
+        if (this._checkDestroyedTimeoutId != 0) {
+            Mainloop.source_remove(this._checkDestroyedTimeoutId);
+            this._checkDestroyedTimeoutId = 0;
+        }
         this._windowManager.disconnect(this._dcid);
         this._windowManager.disconnect(this._mcid);
     }
EOF
)

# Apply the patch
echo "$patch_content" | sudo patch /usr/share/cinnamon/js/ui/appSwitcher/appSwitcher.js

# Restart Cinnamon to apply changes
echo "Restarting Cinnamon to apply changes..."
cinnamon --replace &

echo "Setup complete!"

```

## Cinnamon extensions

Two extensions in `cinnamon-extensions/`. Install both:

```bash
for e in windows-snap@nybo smart-close@nybo; do
    ln -sfn "$PWD/config&docs/cinnamon-extensions/$e" \
            ~/.local/share/cinnamon/extensions/$e
done
gsettings set org.cinnamon enabled-extensions "['windows-snap@nybo', 'smart-close@nybo']"
# windows-snap owns Super+arrows, so clear muffin's own grabs on them
for k in push-tile-left push-tile-right push-tile-up push-tile-down; do
    gsettings set org.cinnamon.desktop.keybindings.wm "$k" "[]"
done
cinnamon --replace &
```

Both are pure Meta/muffin API - no `xdotool`, no XTEST key injection, and no
`sleep` to dodge a modifier race. Earlier script-based attempts at both
features needed all three and were unreliable; the git history around
`smart-tile.sh` / `smart-close.sh` has the details.

### windows-snap@nybo - Super+arrow window snapping

Halves run a 3-step cycle: Super+Left gives
floating -> left half -> right half -> floating. Super+Up or Super+Down from a
half gives the quarter on that side.

Quarters follow Windows and never float - a horizontal arrow flips to the
other quarter in the same row, and the way out is the vertical arrow pointing
back at the half the quarter came from. Super+Up from a top quarter, already
against the top edge, maximizes. Snapping from floating therefore
always lands on a half, never a quarter. The arrow pointing back at the half a quarter came from
returns to it, so Super+Up then Super+Down is reversible.

The vertical arrows are deliberately not mirror images, matching Windows.
Super+Up climbs floating -> maximized -> top half and stops there. Super+Down
does not walk back down that ladder: from any expanded state it drops straight
to floating, and from floating it minimizes.

Dragging a snapped window with the mouse hands back its floating size, again
like Windows. muffin does this for windows it tiled itself, but these zones are
applied with `move_resize_frame()`, so muffin sees ordinary half-screen-sized
windows with no pre-snap geometry and would otherwise drag them at full
snapped size.

A **custom keybinding** (`org.cinnamon.desktop.keybindings custom-list`)
running a script cannot hold Super+arrow at all - it loses the bare-Super grab
to the "Super alone opens the menu" overlay key, so Super+Left just opened the
menu. `Main.keybindingManager.addHotKey()` registers through muffin like a
native WM binding and works.

The extension never assumes its own bookkeeping is intact - that state lives
on the window object and is lost every time Cinnamon reloads. It works out
where a window really is from three sources in order: muffin's `tile_mode` and
`get_maximized()`, then its own record (only if the window is still where it
was put), then the raw geometry, so a window sitting on a zone counts as being
in that zone however it got there.

That last step also stops a float rect being poisoned. A window already parked
on a zone the first time an arrow is pressed would otherwise have the zone
geometry recorded as "floating", and restoring would put it straight back on
the zone it was trying to leave. A stored float rect that is itself a zone is
discarded, and the window is centred at 60% of the work area instead.

Windows snapped with the **mouse** (dragged to a screen edge) are tiled by
muffin, not by this extension, so it reads muffin's `tile_mode` rather than
only its own record. Super+Left on a mouse-snapped window therefore continues
the cycle instead of re-snapping it to the side it is already on. muffin also
keeps the pre-snap geometry for those windows, and `unmaximize()` restores it
exactly - so such a window still floats back to its original size even though
this extension never saw it float.

Four muffin quirks the extension works around, verified on Cinnamon 6.4.14 and
commented in `extension.js`:

- `move_resize_frame(x, y, w, h)` applies the size but **ignores x/y**; the
  position needs a separate `move_frame(x, y)` call afterwards.
- `allows_resize()` returns **false while a window is maximized**, so using it
  as a guard silently disables Super+Down (unmaximize) - the one case it is
  most needed. The `resizeable` property is state-independent and is used
  instead.
- The drag anchor is captured when a grab begins, **before** `grab-op-begin`
  runs, so resizing a window there leaves the pointer tracking the old frame -
  grabbing a left-snapped window near its right edge dragged it several hundred
  px away from the cursor, entirely out from under it. Ending and immediately
  restarting the grab re-anchors it.
- `Meta.Window.begin_grab_op()` **always anchors at the window centre**,
  whatever the window's actual position, so the cursor ends up holding the
  middle of the window instead of its title bar. `Meta.Display.begin_grab_op()`
  is the same operation but takes an explicit anchor point, which is what the
  extension uses to keep the title bar under the pointer.

### smart-close@nybo - Ctrl+Shift+W closes any window

Ctrl+Shift+W normally only works in apps that implement it, so a settings
dialog ignores it entirely. Binding it globally fixes the dialogs but breaks
terminals: an X grab goes to whoever takes it, so the WM wins and the terminal
never sees the key - it would close the whole window instead of one tab.

Rather than grabbing the key and re-injecting a different accelerator for the
terminal (the usual trick, and what the old `smart-close.sh` did), the grab
itself is made conditional. muffin keybindings can be added and removed at
runtime, so on every focus change the extension either takes the grab or
releases it:

- focused app handles Ctrl+Shift+W itself (terminals - see
  `PASSTHROUGH_CLASSES` in `extension.js`) -> grab released, key reaches the
  app untouched
- anything else -> grab held, `window.delete()` on press

Verified both ways: with the grab held a press ran the extension callback and
the terminal was untouched; with it released the callback did not run and the
terminal closed its tab.

## Cinnamon applets - panel usage readouts

Two applets in `cinnamon-applets/`, backed by three scripts in
`scripts/panel/`. Install the same way as the extensions:

```bash
for a in claude-usage@nybo oslo-weather@nybo; do
    ln -sfn "$PWD/config&docs/cinnamon-applets/$a" \
            ~/.local/share/cinnamon/applets/$a
done
for s in claude-usage codex-usage oslo-weather; do
    ln -sfn "$PWD/scripts/panel/$s" ~/.local/bin/$s
done
```

Then add them to `org.cinnamon enabled-applets` - the key is a flat list of
`panel:side:order:uuid:instance` strings, and Cinnamon hot-loads a change to
it, so no `cinnamon --replace` is needed. Each script also runs standalone
(`--json` for structured output, `--force` to bypass its cache), which is the
fastest way to test one without touching the panel.

`claude-usage@nybo` renders all three numbers - `5h 46% 05:30  wk 15% Sat  cx
37% 22 Sep`. A standalone `codex-usage@nybo` is in the repo but deliberately
**not** enabled; it exists only if the combined label is ever worth splitting.

### Reloading and inspecting an applet

Editing `applet.js` does nothing until the applet is reloaded, which is not
obvious and cost a session's confusion - the Codex readout was written, looked
correct on disk, and simply never appeared:

```bash
dbus-send --session --dest=org.Cinnamon /org/Cinnamon \
  org.Cinnamon.ReloadXlet string:'claude-usage@nybo' string:'APPLET'
```

Live applet state is reachable through `Eval`, which is far better than
guessing from a screenshot. `appletManager.appletObj` is empty - the instance
hangs off the definition instead:

```bash
dbus-send --session --print-reply --dest=org.Cinnamon /org/Cinnamon \
  org.Cinnamon.Eval string:'
(function(){
  let d = imports.ui.appletManager.definitions
            .filter(x => x.uuid == "claude-usage@nybo")[0];
  return d.applet._applet_label.get_text();
})()'
```

That same trick reads the real filesystem from outside a sandboxed shell, which
is how a "the files are gone" scare was settled - `GLib.file_test()` from the
Cinnamon process showed all of them present.

Panel labels are plain text by default. Colour needs
`_applet_label.get_clutter_text().set_markup()` *after* `set_applet_label()`,
and the plain call is kept as the fallback because invalid markup throws.

### claude-usage - 5-hour and weekly limits

Reads `GET https://api.anthropic.com/api/oauth/usage` with the OAuth token
Claude Code stores in `~/.claude/.credentials.json`. Same endpoint the
`/usage` slash command uses; `anthropic-beta: oauth-2025-04-20` is required.

Do not hardcode colour thresholds. The response carries a `limits[]` array with
a server-side `severity` per window plus an `is_active` flag marking whichever
window is currently binding, and severity escalates past `warning` to
`critical` on its own. The applet renders the active window bold and takes its
colour from `severity`, treating any unrecognised value as critical.

Each poll appends a sample to `~/.cache/claude-usage/state.json` (3h rolling).
When the recent slope projects hitting 100% *before* the window resets, the
segment goes red and the dropdown names the projected time - a percentage alone
does not tell you whether you will hit the wall. `notify-send` fires at 80% and
95%, keyed to the window's `resets_at` so each new window re-arms exactly once.

**The credentials file is read, never written.** Claude Code owns the refresh,
and a background poller racing it over token rotation could break the login.
The cost is that the token lasts ~8h, so the applet can go stale overnight; it
shows the last values with a `⚠` and says to run any Claude Code command.

`extra_usage` is a trap worth spelling out. `monthly_limit` is a **spend cap,
not a balance**, so rendering `used / limit` implies money on hand that is not
there. `spend_limit_reached: false` alongside `disabled_reason:
"out_of_credits"` means the cap was never hit and the wallet behind it is
simply empty. While `is_enabled` is false nothing can be billed, and that is
what the dropdown says rather than a fraction.

### codex-usage - Codex rate-limit window

There is **no standalone usage endpoint** for Codex. Limits otherwise only ride
on `x-codex-*` headers attached to real inference responses, so polling for
them would burn quota. The way in is Codex's own local app-server protocol:

```bash
codex app-server --stdio   # JSON-RPC: initialize, then account/rateLimits/read
```

It runs against an isolated `CODEX_HOME` at `~/.cache/codex-usage-runtime`
(0700, with `auth.json` copied through a 0600 handle - `shutil.copyfile` does
not set a mode, and a 0002 umask would otherwise leave tokens group-readable)
so it never disturbs live Codex state.

**The sandbox must never be what refreshes the token.** A rotated refresh token
would land in the throwaway copy and be lost, which can invalidate the real
login. The script therefore checks the access token's `exp` and skips the
app-server entirely within an hour of expiry, serving cache and leaving the
refresh to Codex. Codex access tokens last ~10 days, so this is rare but real.

Polling is deliberately slow (30 min). The window is 30 days, and each poll
spawns a ~258 MB app-server. Codex has no server-side severity either, so one
is synthesised - amber at 75%, red at 90% or on `rateLimitReached` - because
the 95% threshold that suits a 5-hour window is far too late for a monthly one.

### oslo-weather - met.no

`locationforecast/2.0/compact` for Oslo (59.9139, 10.7522). No API key. met.no
requires an identifying `User-Agent` and asks clients not to poll harder than
the data changes, so results are cached 15 min and revalidated with
`If-None-Match`; a 304 refreshes the cache timestamp without refetching.

## Bluetooth headphones - do not try to make idle A2DP suspend

Multipoint headphones (Bose QC) grant A2DP to one host at a time and leave the
other on HFP. Windows releases the A2DP stream when nothing is playing so the
phone can take over; Linux holds it open, so the headset stays pinned to the PC.

The obvious fix is to make the node suspend when idle. **It does not work on
bluez 5.72 - do not do it.** Recorded here so it is not attempted twice.

`/usr/share/wireplumber/scripts/monitors/bluez.lua` hardcodes
`node.pause-on-idle = false` on every bluetooth node (lines 99, 110, 116, 126
and 265 on wireplumber 0.4.17). That looks like an oversight and is not - it is
a deliberate workaround. `rulesApplyProperties()` at bluez.lua:299 runs after
the default, so a `bluez_monitor.rules` entry with
`node.pause-on-idle = true` and `session.suspend-timeout-seconds = 5` does
override it, and the node does then suspend when idle. The handoff problem is
still not solved, because on resume:

```
wireplumber: Acquire .../sep1/fd5 returned error: org.bluez.Error.NotAuthorized
wireplumber: (bluez_output...) running -> error (Received error event)
bluetoothd:  avdtp.c:cancel_request() Start: Operation canceled (125)
bluetoothd:  a2dp.c:a2dp_suspend() SEP in bad state for suspend
bluetoothd:  a2dp.c:a2dp_resume() SEP in bad state for resume
bluetoothd:  avdtp.c:session_cb() Transaction label doesn't match
```

bluez 5.72 fails to re-acquire the transport it just released, leaving the SEP
wedged and the transaction labels desynced. A2DP then disappears from the card
entirely - `pactl list cards` shows only `headset-head-unit*` profiles, so
`pactl set-card-profile ... a2dp-sink` fails with `No such entity`, and the
headset is stuck in mono 16 kHz until it is reconnected.

Each suspend/resume cycle is a chance to hit this, which is why upstream never
lets these nodes pause.

**There is no known fix.** blueman issue #2976 reports this exact failure on
this exact stack - pipewire 1.0.5, wireplumber 0.4.17, bluez 5, noble - and was
closed as stale with no patch. The only workaround found there was to keep
audio playing so the transport never idles, which is what
`node.pause-on-idle = false` already achieves. bluez issue #1545 (a related
pipewire/bluez transport race) is still open and unfixed.

So the default is not a placeholder waiting on an upstream fix; it is the best
anyone has. Upgrading pipewire is a guess, not a known cure - do not assume
`ppa:aglasgall/pipewire-extra-bt-codecs` (1.2.7 for noble, also carries
AAC/aptX that the distro build lacks because `fdk-aac` is in multiverse) will
help. It might; nobody has shown that it does.

### Living with it

To hand the headset to the phone, disconnect it explicitly:

```bash
bluetoothctl disconnect E4:58:BC:C4:73:85
```

**Do not open Cinnamon Sound settings while the headset is connected.** The
Input tab runs a `Peak detect` stream on the selected source; if that source is
the headset mic it forces the card to `headset-head-unit-msbc` - mono 16 kHz,
sounds like a phone call. Closing the window frees the mic but the switch back
to A2DP is exactly the transition that wedges, so it usually needs a reconnect
anyway. Use `pactl` instead of the GUI.

Anything else that opens the bluetooth mic does the same thing. Check with:

```bash
pactl list source-outputs | grep -E "Source Output|application.name|media.name"
```

Recovering a wedged session, cheapest first - power-cycle the headset, then:

```bash
bluetoothctl disconnect E4:58:BC:C4:73:85 && bluetoothctl connect E4:58:BC:C4:73:85
sudo systemctl restart bluetooth   # fallback
```

Do not upgrade bluez to chase this. 5.83/5.84 have a separate regression where
A2DP fails to connect at startup (bluez issue #1570); 5.72 is the better of the
two problems.

## Keyboard volume wheel changes the wrong output

Symptom: the keyboard volume wheel moves some other sink - the HDMI/monitor
output - while sound plays over the device you are actually using. The on
screen volume overlay animates normally, so it looks like volume is simply
broken.

The panel applet is **not** involved. `sound@cinnamon.org` handles the mouse
wheel over the panel; the keyboard wheel goes to `csd-media-keys`, a separate
daemon started by `cinnamon-session` from
`/etc/xdg/autostart/cinnamon-settings-daemon-media-keys.desktop`. It holds its
own mixer connection, so reloading the applet, `cinnamon --replace`, and even
restarting wireplumber all leave it untouched.

Check the applet is innocent before chasing it - this drives its real volume
path and reports which sink it hit:

```bash
dbus-send --session --print-reply --dest=org.Cinnamon /org/Cinnamon \
  org.Cinnamon.Eval string:'
(function(){
  let a = imports.ui.appletManager.getRunningInstancesForUuid("sound@cinnamon.org")[0];
  let o = a._output;
  o.volume = Math.min(a._volumeMax, o.volume + a._volumeNorm * 0.20);
  o.push_volume();
  return "pushed to " + o.get_name() + " idx=" + o.get_index();
})()'
```

Fix - restart the daemon. `cinnamon-session` respawns it, so do not launch it
by hand unless it fails to come back; two instances make every keypress step
twice:

```bash
kill $(pgrep -x csd-media-keys)
pgrep -c -x csd-media-keys    # must be 1
```

**Cause not yet established.** It may bind its output once at startup and never
follow later default-sink changes, or it may have desynced because the sink was
destroyed and renumbered a dozen times in one session while chasing an
unrelated bluetooth problem. Those call for different fixes, so nothing is
patched yet.

To find out, change the default sink and press the keyboard wheel:

```bash
pactl set-default-sink alsa_output.usb-TOPPING_DX1_II-00.analog-stereo
# press the wheel, then check which sink moved:
pactl list short sinks
```

Follows the new default -> one-off desync, leave it alone. Keeps driving the
old sink -> deterministic, and a small script to restart the daemon is the
proportionate fix. Patching `cinnamon-settings-daemon` from source is not -
package updates would revert it.

Useful when diagnosing anything in this area, because the numbers move:

```bash
# which sink is each app on, and is anything holding the mic
pactl list short sink-inputs
pactl list source-outputs | grep -E "Source Output|application.name|media.name"
# fallback order when a device disappears - first entry that still exists wins
cat ~/.local/state/wireplumber/default-nodes
```

That last file is worth knowing about. It is a ranked list, not a priority
calculation, and a disappearing device falls through to the next entry that
exists. Ranking a silent HDMI monitor second means every dropout lands on
silence; selecting a device in the applet promotes it, so put something audible
there.
