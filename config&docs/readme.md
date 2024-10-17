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


# ------------------------------------





fuzzy_command_search() {
    # ---------- Configuration ----------
    HISTORY_FILE="$HOME/.bash_history"
    current_cmd_index=0
    cmd_matches=''
    declare -a current_cursor_position

    # ---------- Cursor Management Functions ----------

    extract_current_cursor_position() {
        # Capture the cursor position after printing the prompt
        IFS=';' read -sdR -p $'\E[6n' row col
        current_cursor_position[0]=$(( ${row#*[} - 1 ))
        current_cursor_position[1]=$(( col - 1 ))
    }

    reposition_cursor() {
        # Move the cursor back to the input line
        tput cup "${current_cursor_position[0]}" "$(( current_cursor_position[1] + ${#search_string} ))"
    }

    # ---------- User Interface Functions ----------

    flush_screen() {
        # Clear from cursor to end of screen
        tput ed
    }

    capture_user_input() {
        # Clear any pending input
        read -t 0 -n 1000 discard

        while IFS= read -rsn1 char; do
            if [ "$char" = $'\x7f' ]; then  # Backspace
                if [ -n "$search_string" ]; then
                    tput cub1
                    echo -n ' '
                    tput cub1
                    search_string="${search_string%?}"
                fi
            elif [ "$char" = $'\n' ]; then  # Enter
                selected_line=$(echo "$cmd_matches" | sed -n "$(( current_cmd_index + 1 ))p")
                # Move cursor below the suggestions before executing
                tput cup $(( current_cursor_position[0] + 5 )) 0
                echo
                eval "$selected_line"
                return
            elif [ "$char" = $'\x1b' ]; then  # Escape character
                read -rsn2 next_chars
                escape_sequence="$char$next_chars"
                if [ "$escape_sequence" = $'\x1b[A' ]; then  # Up arrow
                    if [ $current_cmd_index -gt 0 ]; then
                        current_cmd_index=$(( current_cmd_index - 1 ))
                    fi
                elif [ "$escape_sequence" = $'\x1b[B' ]; then  # Down arrow
                    max_index=$(( $(echo "$cmd_matches" | wc -l) - 1 ))
                    if [ $current_cmd_index -lt $max_index ]; then
                        current_cmd_index=$(( current_cmd_index + 1 ))
                    fi
                fi
            else
                search_string="$search_string$char"
                echo -n "$char"
            fi

            display_search_results
            reposition_cursor
        done
    }

    # ---------- Search Logic ----------

    print_matches() {
        local count=0
        while IFS= read -r line; do
            # Move cursor to the correct line
            tput cup $(( current_cursor_position[0] + 1 + count )) 0
            # Clear the line
            tput el
            # Display the line
            if [ "$current_cmd_index" -eq "$count" ]; then
                echo -e "> $line"
            else
                echo "  $line"
            fi
            count=$(( count + 1 ))
            [ "$count" -ge 5 ] && break
        done <<< "$cmd_matches"
    }

    fuzzy_search() {
        if [ -z "$search_string" ]; then
            cmd_matches=$(tac "$HISTORY_FILE" | awk '!seen[$0]++' | head -5)
        else
            cmd_matches=$(grep -i "$search_string" "$HISTORY_FILE" | tac | awk '!seen[$0]++' | head -5)
        fi
    }

    display_search_results() {
        fuzzy_search
        flush_screen
        print_matches
    }

    # ---------- Main Function Execution ----------

    history -a "$HISTORY_FILE"
    search_string=""

    # Ensure PS1 is available
    [ -z "$PS1" ] && export PS1='\u@\h:\w\$ '

    # Expand and print the prompt correctly
    if [ "${BASH_VERSINFO:-0}" -ge 5 ] || { [ "${BASH_VERSINFO:-0}" -eq 4 ] && [ "${BASH_VERSINFO[1]:-0}" -ge 4 ]; }; then
        printf "%s" "${PS1@P}"
    else
        CLEAN_PS1=$(sed 's/\\\[\(.*\)\\\]//g' <<< "$PS1")
        eval "printf '%b' \"$CLEAN_PS1\""
    fi

    # Capture the initial cursor position after printing the prompt
    extract_current_cursor_position

    # Start capturing user input
    capture_user_input
}


bind -x '"\C-r":fuzzy_command_search'
# ------------------------------------










# Exit if running over SSH
if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_TTY" ]; then
  echo "You are on an SSH session - so you are probably setting up a server, exiting."
  exit 1
fi

echo "Setting up Linux for desktop"

# Install required packages
sudo apt install -y python3-pip python3-gi python3-{nautilus,nemo,caja} xclip \
software-properties-common translate-shell gnuplot tesseract-ocr texlive-full jq

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

# Custom keybinding 0: myocrclip
gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/\
keybindings/custom-keybindings/custom0/ name 'myocrclip'
gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/\
keybindings/custom-keybindings/custom0/ command 'myocrclip'
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
