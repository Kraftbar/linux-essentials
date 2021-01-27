# Things i do with a fresh linux install (mainly for xps15 9560)



### 0. install nvidia drivers so no cpu lockup at shutdown
also, select intel as gpu so power consumption is not degenerate       
and, fiddle around with versions, since some are bugged (makes for freeze behavior etc.)         
### 0.1 connect to eduroam
run script - eduroam-linux-Ntu-N.sh

### 1. get the applet that allows for automatic sleep when low battery (needs script)
>  [BAMS](https://cinnamon-spices.linuxmint.com/applets/view/255)      
>  or do a simple script (havent had the time)      
OR set cinnamon settings see web-r for script to modify


### 2. fix windows clock, so that it is correct
>   ```sh
>    timedatectl set-local-rtc 1
>   ```
### 3. configure mouse speed (not acc) beyond the gui setting limit
see manual  config - [link](trackpad.md)        


### 4. Set up git ssh
scrolling faster     
mouse faster   

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
>cat ~/.ssh/id_rsa.pub | tr -d '\n'  | xclip 
>
>google-chrome "https://github.com/settings/ssh/new"
>
>echo "Clipboard contains now id_rsa.pub, please input it to browser. "
>read -p "please confirm with enter when done:" confirm 
>ssh -T git@github.com
>
>   ```


[link](shh_git.md) (old)

### 5. Get scripts
###
>   ```sh
>    sudo mv ../global/* /usr/local/bin
>   ```
also add     
pgrep redshift | xargs -n1 kill -9 &&  redshift -l 59.904379299999995:10.7004307 2600         

### 6.1 Get dot files

### 6.2 Set aliases
see file

### 6.3 if on pop os fix scrolling speed    (dont do this, bugges forward backward button)
#### Run this
cd ~/; wget https://github.com/Kraftbar/linuxessentials/edit/master/docs/mySetup/newLinuxInstallation/imwheel-script.sh -O imwheel-script.sh; chmod +x imwheel-script.sh; sh imwheel-script.sh; sudo rm imwheel-script.sh; exit
#### startup
Add imwheel to startup applications

### 7. Get programs

#### 7.1 albert
get albert [link](install_Albert.sh)
<br>
<br>


#### 7.3  ohmyzsh (needs script)       



### 8. get emacs (needs script)        

>   ```sh
>   # dont use this with current config 
>   if [ -z "$(/usr/bin/pgrep -u $USER -x -f '/usr/bin/emacs --daemon')" ] ; then
>     /usr/bin/emacs --daemon 2> /dev/null
>   fi
> 
>   EDITOR="/usr/bin/emacsclient --quiet --create-frame"
>   VISUAL=$EDITOR
>   export EDITOR VISUAL
>   ```


OR

#### 8.1 download startEmacs.sh         
#### 8.2 open menu editor and reconfigure emacs app to /home/nybo/Desktop/startEmacs.sh %F            

(~/.config/mimeapps.list     (copy xed settings, replace with emacs) then make default         )


#### 8.3 get files:       

>   ```sh
>    ln -s ~/Documents/github/linuxessentials/docs/mySetup/dots/*.el /home/nybo/.emacs.d/
>    ln -s ~/Documents/github/linuxessentials/docs/mySetup/dots/*.sh /home/nybo/.emacs.d/
>   ```

(for windows)
>   ```CMD
> FOR %G IN ("C:\Users\nybo\Documents\GitHub\linuxessentials\docs\mySetup\dots\*" ) DO mklink C:\Users\nybo\AppData\Roaming\.emacs.d\%~nxG %G
>   ```


#### 8.4 Edit files ctrlf downloaded sourcefiles, get rid of the preset hotkeys     


### 9. Add dwm        

get dwm, maybe with slstatus     


insert the following in .xinitrc
```bash
# used by dwm
if [ "$GDMSESSION" != "cinnamon" ]; then
    xrandr --output eDP-1 --mode 1920x1080
    xinput --set-prop "DLL07BE:01 06CB:7A13 Touchpad" "libinput Natural Scrolling Enabled" 1
    gnome-terminal &
fi
```
consider to get 
 - ROFI (missing config file)
 - sxhkd (missing config file)

### 10 set mouse speed (needs script)
>   ```sh
>  xinput --set-prop 14 "Coordinate Transformation Matrix" 2 0 0 0 2 0 0 0 0.5
>   ```


### get repositories

curl -H “Authorization: token MYTOKEN” https://api.github.com/search/repositories?q=user:MYUSERNAME 35






### 11. If on gnome and not using cinnamon, set  keys        
get file from flie:        
```bash
# used by dwm
cd "install resources"
# import keys
./keybindings.pl -i /tmp/keys.csv
# use "./keybindings.pl -e /tmp/keys.csv" to export
cd ..
```


### Other install things
[zen_installer](https://github.com/spookykidmm/zen_installer)      
##### seems like a good setup 
```bash
nybo@pop-os:~$ lsmod | grep -iE "apple|cyapa|sermouse|synap|psmouse|vsxx|bcm"
btbcm                  16384  1 btusb
bluetooth             577536  31 btrtl,btintel,btbcm,bnep,btusb,rfcomm
psmouse               155648  0
```
##### seems like a good things to add 
touchegg                  

