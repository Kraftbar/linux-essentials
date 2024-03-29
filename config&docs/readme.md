# Things i do with a fresh linux install (mainly for xps15 9560)
Todo: find a way to exract bash code from markdown and run it
```sh
 # extract the code
 sed -n '/^>.*```/,/^>.*```/ p' < readme.md | sed '/^```/ d'    
 # todo: cut out "```bash", ">" etc.
```
docs: https://unix.stackexchange.com/questions/61139/extract-triple-backtick-fenced-code-block-excerpts-from-markdown-file

---
### 2. fix windows clock
>   ```sh
>    timedatectl set-local-rtc 1
>   ```

---
### 2. clean install first run

when doing "cp" xinitrc, ". /etc/X11/Xsession" exits script



---
### 2. fix windows clock
>   ```sh
>    timedatectl set-local-rtc 1
>   ```


---
### 4. Install prerequisite packages 


>   ```sh
> # install git 
> sudo apt-get install git 
>
> # install git icons for nemo 
> sudo apt-get install python3-pip
> sudo apt-get  install python3-gi python3-{nautilus,nemo,caja} python3-pip
> pip3 install --user git-nautilus-icons
>
> # used for ssh config script
> sudo apt install xclip
>
> # used for ssh vscode install
> sudo apt install software-properties-common apt-transport-https
>
> # custom shell script dependencies
> sudo apt-get install translate-shell 
> sudo apt-get install gnuplot
> sudo apt-get install tesseract-ocr
>
># get zsh
> sudo apt-get install zsh
>
># get latex
> sudo apt-get install texlive-full
>
>```


>   ```sh
>
> # used in aws script
> sudo pip3 install boto3
>
>
>```


---
### 4. Install programs 


>   ```sh
>  # install chrome  #
>  ###################
> wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
> sudo dpkg -i google-chrome-stable_current_amd64.deb
> rm google-chrome-stable_current_amd64.deb
>
> # install  spotify #
> ####################
> sudo apt-get install spotify-client
>
> # install chrome  #
> ###################
> wget -O vscode.deb https://go.microsoft.com/fwlink/?LinkID=760868 
> sudo dpkg -i vscode.deb
> rm vscode.deb
>
> data=$(cat <<EOF
> [
>     {
>         "key": "ctrl+tab",
>         "command": "workbench.action.nextEditorInGroup"
>     },
>     {
>         "key": "ctrl+shift+tab",
>         "command": "workbench.action.previousEditorInGroup"
>     }
> ]
> EOF
> )
> echo "$data" > /home/nybo/.config/Code/User/keybindings.json
>       
>
>
>
> # install emacs   ٩(⁎❛ᴗ❛⁎)۶  #
> ##############################
> sudo add-apt-repository ppa:kelleyk/emacs
> sudo apt update
> sudo apt install emacs27
>```

---

### 6 Set aliases

>   ```sh
> alias youtube-dl-480='youtube-dl -f "bestvideo[height<=480][ext=mp4]+bestaudio[ext=m4a]" '
> alias youtube-dl-720='youtube-dl -f "bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]" '
> alias youtube-dl-best='youtube-dl -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio" '
> alias youtube-dl-mp3='youtube-dl --extract-audio -f bestaudio[ext=mp3] --no-playlist '
> alias myredshift='pgrep redshift | xargs -n1 kill -9 && redshift -l 59.904379299999995:10.7004307 1800'
> 
> 
> # todo: Make this an alias     
> # youtube-dl-best --output "%(upload_date)s%(title)s.%(ext)s"
>   ```

---
### 4. Set up git ssh and download repository

>   ```sh
>
> echo "Running this (configuring ssh) will clear the clipboard "
> read -p "Continue? (y/n): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
> 
> git config --global user.name "Kraftbar"
> git config --global user.email "gautenybo@gmail.com"
> git config --global color.ui true
> git config --global core.editor emacs
> 
>
> ssh-keygen -t rsa -C "gautenybo@gmail.com"
> cat ~/.ssh/id_rsa.pub | xclip -selection clipboard -r
> 
> echo "Clipboard contains now id_rsa.pub, please input it to browser. "
> echo "When done, close broser to continue!! "
> google-chrome "https://github.com/settings/ssh/new"
> 
> read -p "please confirm with enter when done:" confirm 
> ssh -T git@github.com
> 
> git config --global url."git@github.com:".insteadOf "https://github.com/"
>
> echo "--------------------------------------------"
> echo "---------------ssh setup done---------------"
> echo "--------------------------------------------"
> echo "Github access tolken "
> echo "Only select repo scope"
> echo "After generating the tolken, copying it and then close the browser"
>
>
> google-chrome "https://github.com/settings/tokens/new"
> read -p "Paste token " github_token 
> echo  "export github_token=$github_token" >> ~/.bashrc
> echo ""
> echo "----------- Github config done ------------"
> echo ""
>   ```



---



### 9. Get git repos
>```bash
> 
> mkdir  ~/Code
> sed -i 's/Music/&\nfile:\/\/\/home\/'"${USER}"'\/Code/g' ~/.config/gtk-3.0/bookmarks
>
> ##
> # $ repoList=$(curl -sH "Authorization: token $github_token" \
> # $          https://api.github.com/search/repositories\?q\=user:kraftbar\&per_page=100 \
> # $          | grep -oP '"ssh_url":\s*"\K[^"]+')
>
> ##### work in progress,         #####
> ##### ask user if he wants to   #####
> ##### download the biggest ones #####
> curl -sH "Authorization: token $github_token" \
>         https://api.github.com/search/repositories\?q\=user:kraftbar\&per_page=100 | \
>      sed -e 's/[ \t]*"size": \(.*\),,\?/\1/p'   \
>          -e 's/[ \t]*"ssh_url": "\(.*\)",\?/\1/p' -e d |  \
>      sed 'N;s/\n/\t/' | \
>      sort -t$'\t' -k2 -nr  | \
>      awk ' $2 <= 100000 ' \
>      >> ~/Code/tmp.txt
> repoList=$(awk '{print $1}' ~/Code/tmp.txt)
>
> for i in $repoList; do
>   git -C ~/Code clone "$i" 
> done
>```




---
### 5. Create symbolic links
###
>   ```sh
> 
>    # symbolic link scripts
>    abspaths=$(readlink -f "$HOME/Code/linux-essentials/scripts/my*") && sudo ln  -s $abspaths /usr/local/bin/
> 
> 
>    mkdir ~/.emacs.d/
>    abspaths=$(readlink -f "$HOME/Code/linux-essentials/config&docs/dots/*.el") && ln -s $abspaths ~/.emacs.d/
> 
> 
>   ```


(for windows)
>   ```CMD
> REM; symbolic link
> FOR %G IN ("C:\Users\nybo\Documents\GitHub\linux-essentials\config&docs\dots\*" ) ^
> DO mklink C:\Users\nybo\AppData\Roaming\.emacs.d\%~nxG %G
>   ```
>   ```CMD
> REM; start emacs
>tasklist | FIND "emacs" >nul
>if errorlevel 1 (start /B C:\ProgramData\chocolatey\lib\Emacs\tools\emacs\bin\runemacs.exe --daemon) ^
> else (start /B C:\ProgramData\chocolatey\lib\Emacs\tools\emacs\bin\emacsclient.exe -n -c -a "")
>   ```




---

### 8  Configure zsh

>```sh
> # needs testing
> echo "exit" | sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
> cd ~/.oh-my-zsh/custom/plugins
> git clone git@github.com:zdharma/history-search-multi-word.git
> sed -i 's/plugins=(/ & history-search-multi-word  /' ~/.zshrc
> # change shell
> chsh -s $(which zsh)
>```

---

### 8  Configure latex
todo: find out why some latexmkrc's can have "#!/bin/bash" 
>```bash
>
>
> IFS='' read -r -d '' VAR <<'EOF'
>
> #!/usr/bin/env perl
> 
> # LaTeX
> $latex = 'latex -synctex=1 -halt-on-error -file-line-error %O %S';
> $max_repeat = 5;
> 
> # BibTeX
> $bibtex = 'pbibtex %O %S';
> $biber = 'biber --bblencoding=utf8 -u -U --output_safechars %O %S';
> 
> # index
> $makeindex = 'mendex %O -o %D %S';
> 
> # DVI / PDF
> $dvipdf = 'dvipdfmx %O -o %D %S';
> $pdf_mode = 3;
> 
> # output directory
> $out_dir = 'build_latex';
> 
> # Remove pdfsync files on clean
> $clean_ext = 'pdfsync synctex.gz';
> 
> 
> 
> # preview
> $pvc_view_file_via_temporary = 0;
> if ($^O eq 'linux') {
>     $dvi_previewer = "xdg-open %S";
>     $pdf_previewer = "xdg-open %S";
> } elsif ($^O eq 'darwin') {
>     $dvi_previewer = "open %S";
>     $pdf_previewer = "open %S";
> } else {
>     $dvi_previewer = "start %S";
>     $pdf_previewer = "start %S";
> }
> 
> # clean up
> $clean_full_ext = "%R.synctex.gz"
> 
> EOF
>
> touch ~/.latexmkrc
> echo "$VAR" > ~/.latexmkrc
>
>```

---
### 8. Emacs     

>```sh
>  # needs  testing!"!!
>  sudo sed  -i "s/^Exec.*/Exec=mystartEmacs %F/g" /usr/share/applications/emacs*.desktop
>
>```


### 8. Firefox     

Go to "about:config", in the address bar.
Search for "browser.tabs.inTitlebar". Set it to 1.




consider to make defualt text editor       

do something in ~/.config/mimeapps.list i think     (copy xed settings, replace with emacs)       
need to configure 


dconf write /org/cinnamon/desktop/keybindings/wm/'switch-to-workspace-1' "['<Shift><Alt>exclam']"      
dconf write /org/cinnamon/desktop/keybindings/wm/'switch-to-workspace-2' "['<Shift><Alt>quotedbl']"       
 dconf write /org/cinnamon/desktop/keybindings/wm/'switch-to-workspace-3' "['<Shift><Alt>numbersign']"      








---



### 9. Add things to xinitrc  

Can consider to make a script and put run it by making a entry in "/home/nybo/.config/autostart"      
docs: https://unix.stackexchange.com/questions/274656/how-to-manually-add-startup-applications-on-mint-17-3
docs: https://developer.toradex.com/knowledge-base/how-to-autorun-application-at-the-start-up-in-linux
xserver-xorg-input-all
DEVICE=11
xinput --set-prop "$DEVICE" "Synaptics Noise Cancellation" 0 0
xinput --set-prop "$DEVICE" "Device Accel Profile" 6
xinput --set-prop "$DEVICE" "Device Accel Velocity Scaling" 50
xinput --set-prop "$DEVICE" "Device Accel Constant Deceleration" 12


>```bash
> #!/bin/bash
>
> 
> IFS='' read -r -d '' VAR <<'EOF'
> ### Increase the size of the history    ###
> ###########################################
> export HISTSIZE=10000
> export HISTFILESIZE=20000
>
> ### Start emacs deamon                  ###
> ###########################################
> emacs --daemon
>
>
> ### trackpad sensitivity and dwm config ###
> ###########################################
> chassis=$(sudo dmidecode --string chassis-type)
> 
> # Fix max mousespeed for cinnamon
> # and tap to click
> if [ "$GDMSESSION" == "cinnamon" ] && [ "$chassis" == "Notebook" ]; then
>      var=$(xinput list --id-only 'DLL07BE:01 06CB:7A13 Touchpad') 
>      xinput --set-prop $var "Coordinate Transformation Matrix" 1.8 0 0 0 1.8 0 0 0 0.8
>      xinput --set-prop $var 323 1 
> fi
> 
> # used by dwm
> if [ "$GDMSESSION" != "cinnamon" ] && [ "$chassis" == "Notebook" ]; then
>     xrandr --output eDP-1 --mode 1920x1080
>     xinput --set-prop "DLL07BE:01 06CB:7A13 Touchpad" "libinput Natural Scrolling Enabled" 1
>     gnome-terminal &
> fi
>
> EOF
>
> touch ~/.xinitrc
> echo "$VAR" > ~/.xinitrc
>
>```



### 9. set key bindings
>```bash
>
> # search for key bindings in this way:
> # $ gsettings list-recursively | grep keybindings 
>
> # unbind applet key
> # bug: does not work, check before running 
> # sed -i 's/sound applet menu.\x22/& , \n        \x22value\x22: \x22::\x22/' \
> #         ~/.cinnamon/configs/sound@cinnamon.org/sound@cinnamon.org.json
> sed -i 's/<Shift><Super>s/::/' ~/.cinnamon/configs/sound@cinnamon.org/sound@cinnamon.org.json
>
>
> # set screenshot key,  need testing!!
> gsettings set org.cinnamon.desktop.keybindings.media-keys area-screenshot-clip "['<Super><Shift>s']"
>
>  # set custom keys
>  gsettings set org.cinnamon.desktop.keybindings custom-list \
>   "['custom0', 'custom1', 'custom2', 'custom3', 'custom4', '__dummy__']"
>  dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom2/command "'myocrclip'"
>  dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom2/name "'myocrclip'"
>  dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom2/binding "['<Super><Shift>c']"
>
>  dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom2/command "' sh -c \' xclip -o | python3 ~/Code/aws-r/aws_txt2speech.py \' '"
>  dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom2/name "' my text2speech '"
>  dconf write /org/cinnamon/desktop/keybindings/custom-keybindings/custom2/binding "['<Super><Shift>r']"
> # update (restart cinnamon from bash)
> cinnamon --replace 2>&1 >/dev/null & disown
> # find ~/Code/ | rofi "${ROFI_OPTIONS[@]}" -threads 0 -dmenu -i -p 'locate:' | xargs -r -0 code;
> # ls ~/Code/ | rofi "${ROFI_OPTIONS[@]}" -threads 0 -dmenu -i -p 'locate:' | xargs code;
>```

---



### 10. Patch Ctrl+Q back in to cinnamon
 
find the revert_10031_pull_crlq.diff in the repo.     
 patch it into /usr/share/cinnamon/js/ui/appSwitcher/appSwitcher.js

 
 
---

 
 
 
<br/><br/><br/><br/><br/><br/>

---


### todo:
- ~~keyboard shortcut~~             
    -~~unbind show desklets~~             
    -~~bind gsettings set org.gnome.settings-daemon.plugins.media-keys area-screenshot-clip "['<Super><Shift>s']"~~               
- theme - consider dotfile
- disable sound   - consider dotfile
- latex and sagetex setup        
- use zenity or xdialog     
- power managment      

---
### 7. Get programs
get albert [link](install_Albert.sh)       
latex       
disc       
youtube-dl         
imagemagick        


---
### 7. Manual stuff
#### 1. get the applets
#### 1.1  that allows for automatic sleep when low battery [todo: needs script]
 [BAMS](https://cinnamon-spices.linuxmint.com/applets/view/255)      
 OR do a simple script (havent had the time)      
OR set cinnamon settings see web-r for script to modify
#### 1.2 add some cmd output to make it look fancy
getting wifi card, untested [ifconfig | grep wlp | awk '{ print $1}' | sed 's/:$//'  ]
>   ```sh
>   rpm
>    sensors | awk '/^Processor Fan:/ {print $3 }'  
>   local ip
>    ip -4 -o addr show wlp2s0: | awk '{print $4}'
>   mem
>    free -g | awk '/^Mem:/{print $3 "/" $2}'
>   ```
there are custom applets mode for weather and cpu temp. Note nvidia gpu temp is bugged np


#### 0. install nvidia drivers so no cpu lockup at shutdown
also, select intel as gpu so power consumption is not acting degenerate       
and, fiddle around with versions, since some are bugged (makes for freeze behavior etc.)         


---

### 10 configure linux mint 
dump a config that is good:        
dconf dump /org/cinnamon/ > dconf.org.cinnamon           









---
### 11. If on gnome and not using cinnamon, set  keys (todo: fix relative paths)
```bash
# used by dwm
cd "install resources"
# import keys
./keybindings.pl -i /tmp/keys.csv
# use "./keybindings.pl -e /tmp/keys.csv" to export
cd ..
```




---
### Other install things
[zen_installer](https://github.com/spookykidmm/zen_installer)      
##### seems like a good setup 
```bash
nybo@pop-os:~$ lsmod | grep -iE "apple|cyapa|sermouse|synap|psmouse|vsxx|bcm"
btbcm                  16384  1 btusb
bluetooth             577536  31 btrtl,btintel,btbcm,bnep,btusb,rfcomm
psmouse               155648  0
```
### seems like a good thing to add 
touchegg                  


consider to get 
 - ROFI (missing config file)
 - sxhkd (missing config file)


##### notes on emacs

Some temp notes on possible approach on beeing able to start emacs in deamon mode without personal starting script :
>   ```sh
>   # dont use this with  current config
>   # needs more testing
>   if [ -z "$(/usr/bin/pgrep -u $USER -x -f '/usr/bin/emacs --daemon')" ] ; then
>     /usr/bin/emacs --daemon 2> /dev/null
>   fi
> 
>   EDITOR="/usr/bin/emacsclient --quiet --create-frame"
>   VISUAL=$EDITOR
>   export EDITOR VISUAL
>   ```





---
### 3. fix mouse bugginess ,configure scrolling speed (todo: autoadd [imwheel -b "4 5"] to startup)
 this is a workaround solution. It does still makes for somewhat buggy behavior, this workaround increases the scroll ticks and not the length of the scrolling

>``` bash
>  sudo apt update
>  sudo apt install imwheel
>```

>``` bash
>  ## add scrolling speed to imwheelrc
>  USER_HOME=$(eval echo ~${SUDO_USER})
>  
>  # config
>  rm ${USER_HOME}/.imwheelrc
>  touch ${USER_HOME}/.imwheelrc
>  
>  cat <<EOT >> ${USER_HOME}/.imwheelrc
>  ".*-chrome*"
>  None,      Up,   Button4, 5
>  None,      Down, Button5, 5
>  EOT
>  
>  # add to startup
>  rm ${USER_HOME}/.config/autostart/scrollfix-imwheel.desktop
>  touch ${USER_HOME}/.config/autostart/scrollfix-imwheel.desktop
>
>  cat <<EOT >> ${USER_HOME}/.config/autostart/scrollfix-imwheel.desktop
>  [Desktop Entry]
>  Type=Application
>  Exec=imwheel -b "4 5"
>  X-GNOME-Autostart-enabled=true
>  NoDisplay=false
>  Hidden=false
>  Name[en_US]=scrollfix-(imwheel)
>  Comment[en_US]=No description
>  X-GNOME-Autostart-Delay=0
>  EOT
>```

 
 
#### 3.2 bugges up mouse scroll - fix 
We can do the following to start imwheel when the mouse is plugged in, and stopped when the mouse is unplugged.
I'm on Fedora 33, but a similar solution should work on other distributions.
This method is assuming you have an imwheel service running on your machine.
$HOME/xinputwatcher.sh (remember to chmod +x this file)

>``` bash
> #!/bin/bash
> while true
> do
>   if [[ $(xinput list --name-only | grep 'Logitech USB-PS/2 Optical Mouse') ]];
>   then
>     if [[ $(systemctl --user is-active imwheel) == inactive ]];
>     then
>       systemctl --user start --now imwheel
>       echo "starting imwheel"
>     else
>       echo "imwheel already running"
>     fi
>   else
>     if [[ $(systemctl --user is-active imwheel) == active ]];
>     then
>       systemctl --user stop --now imwheel
>       echo "stopping imwheel"
>     else
>       echo "imwheel already stopped"
>     fi
>   fi
>   sleep 3
> done
>```
Note, you should replace 'Logical .. Mouse' string with whatever your mouse name is (type xinput to get the list of devices).
If you have multiple mice, then you want to add an elseif block.
Note the sleep command; if we unplug the mouse it should take effect within 3 seconds.
Go ahead and test this script by running ./xinputwatcher.sh. It should start imwheel when you plug in your mouse in, and stop imwheel when you unplug it.
Now create the service that runs that script automatically at system start.

$HOME/.config/systemd/user/xinputwatcher.service

>```  bash
>mkdir ~/.config/systemd/
>mkdir ~/.config/systemd/user
>touch ~/.config/systemd/user/xinputwatcher.service
>cat <<EOT >> ~/.config/systemd/user/xinputwatcher.service
>[Unit]
>Description=xinputwatcher
>
>[Service]
>Type=simple
>ExecStart=$HOME/xinputwatcher.sh
>KillMode=process
>
>[Install]
>WantedBy=graphical-session.target
>EOT
>``` 

Finally, enable the service so it starts automatically on reboot.
>``` bash
> systemctl --user daemon-reload
> systemctl --user enable xinputwatcher.sh
>```
