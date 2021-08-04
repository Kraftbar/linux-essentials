# Things i do with a fresh linux install (mainly for xps15 9560)
Todo: find a way to exract bash code from markdown and run it

---
### 1. get the applets
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

---
### 2. fix windows clock
>   ```sh
>    timedatectl set-local-rtc 1
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

---
### 4. Set up git ssh

>   ```sh
>
>echo "Installing git and git utils, installation will clear  clipboard "
>read -p "Continue? (y/n): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
>
>
># install chrome spotify 
>wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
># sudo apt install ./google-chrome*.deb
>sudo dpkg -i google-chrome-stable_current_amd64.deb
>rm google-chrome-stable_current_amd64.deb
>
>#install git 
>sudo apt-get install git 
>
># install git icons for nemo 
>sudo apt-get install pip3
>sudo apt-get  install python3-gi python3-{nautilus,nemo,caja} python3-pip
>pip3 install --user git-nautilus-icons
>
>
> # ssh config 
>git config --global user.name "Kraftbar"
>git config --global user.email "gautenybo@gmail.com"
>git config --global color.ui true
>git config --global core.editor emacs
>
>ssh-keygen -t rsa -C "gautenybo@gmail.com"
>
>sudo apt install xclip
>alias xclip="xclip -selection c" 
>cat ~/.ssh/id_rsa.pub | tr -d '\n'  | xclip -sel clip
>
>echo "Clipboard contains now id_rsa.pub, please input it to browser. "
>echo "When done, close broser to continue!! "
>google-chrome "https://github.com/settings/ssh/new"
>
>read -p "please confirm with enter when done:" confirm 
>ssh -T git@github.com
>
> git clone git@github.com:Kraftbar/linuxessentials.git ~/Documents/linuxessentials
>
>   ```





---
### 5. Get scripts
###
>   ```sh
>    # Get shell dependencies
>    sudo apt-get install gnuplot
>    sudo apt-get install translate-shell      
>    # symbolic link scripts
>    abspaths=$(readlink -f "$HOME/Documents/linuxessentials/scripts/my*") && sudo ln  -s $abspaths /usr/local/bin/
>
>   ```




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
### 7. Get programs
get albert [link](install_Albert.sh)       
latex       
disc       
spotify       
gnuplot     
youtube-dl         
imagemagick        

#### 7.4  ohmyzsh with history enabled 


>   ```sh
>   sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
>   cd ~/.oh-my-zsh/custom/plugins
>   git clone git@github.com:zdharma/history-search-multi-word.git
>   sed -i 's/plugins=(/ history-search-multi-word & /' ~/.zshrc
>   echo 'exec /usr/bin/zsh' >>~/.bashrc
>   ```

---
### 8. get emacs [todo: needs script]        

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


#### 8.1 mod .desktop entry

>   ```sh
>   # needs  testing!"!!
>   emacsnm=$( ls /usr/share/applications/ | grep emacs)
>   sudo sed  -i "s/Exec.*/Exec=mystartEmacs %F/g" "/usr/share/applications/$emacsnm"
> 
>   ```



#### 8.2 consider to make defualt text editor




do something in ~/.config/mimeapps.list i think     (copy xed settings, replace with emacs) 


#### 8.3 get files:       

>   ```sh
>    mkdir ~/.emacs.d/
>    abspaths=$(readlink -f "linuxessentials/config&docs/dots/*.el") && ln -s $abspaths ~/.emacs.d/
>    abspaths=$(readlink -f "dots/*.el")                           && ln -s $abspaths ~/.emacs.d/ 
>   ```


(for windows)
>   ```CMD
> REM; symbolic link
> FOR %G IN ("C:\Users\nybo\Documents\GitHub\linuxessentials\config&docs\dots\*" ) ^
> DO mklink C:\Users\nybo\AppData\Roaming\.emacs.d\%~nxG %G
>   ```
>   ```CMD
> REM; start emacs
>tasklist | FIND "emacs" >nul
>if errorlevel 1 (start /B C:\ProgramData\chocolatey\lib\Emacs\tools\emacs\bin\runemacs.exe --daemon) ^
> else (start /B C:\ProgramData\chocolatey\lib\Emacs\tools\emacs\bin\emacsclient.exe -n -c -a "")
>   ```











<br/><br/><br/><br/><br/><br/>

---


### 0. install nvidia drivers so no cpu lockup at shutdown
also, select intel as gpu so power consumption is not acting degenerate       
and, fiddle around with versions, since some are bugged (makes for freeze behavior etc.)         



### 9. Add things to xinitrc  [todo: needs script]               

```bash

chassis=$(sudo dmidecode --string chassis-type)

# used by dwm
if [ "$GDMSESSION" != "cinnamon" ] && [ "$chassis" == "Notebook" ]; then
    xrandr --output eDP-1 --mode 1920x1080
    xinput --set-prop "DLL07BE:01 06CB:7A13 Touchpad" "libinput Natural Scrolling Enabled" 1
    gnome-terminal &
fi

# Fix max mousespeed for cinnamon
# and tap to click
if [ "$GDMSESSION" == "cinnamon" ] && [ "$chassis" == "Notebook" ]; then
     var=$(xinput list --id-only 'DLL07BE:01 06CB:7A13 Touchpad') && xinput --set-prop $var "Coordinate Transformation Matrix" 1.8 0 0 0 1.8 0 0 0 0.8
     xinput --set-prop $var 323 1
fi
```
---

todo:
- keyboard shortcut
    -unbind show desklets            
    -bind gsettings set org.gnome.settings-daemon.plugins.media-keys area-screenshot-clip "['<Super><Shift>s']"             
- theme - consider dotfile
- disable sound   - consider dotfile
- latex and sagetex setup        


















<br/><br/><br/><br/><br/><br/>

---

### 10 get repositories (in the works)
```bash
curl -H “Authorization: token MYTOKEN” https://api.github.com/search/repositories?q=user:MYUSERNAME 35
```






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
