# Things i do with a fresh linux install (mainly for xps15 9760)



### 0. install nvidia drivers so no cpu lockup at shutdown
also, select intel as gpu so power consumption is not degenerate       
and, fiddle around with versions, since some are bugged (makes for freeze behavior etc.)         
### 0.1 connect to eduroam
run script - eduroam-linux-Ntu-N.sh

### 1. get the applet that allows for automatic sleep when low battery
>  [BAMS](https://cinnamon-spices.linuxmint.com/applets/view/255)      
>  or do a simple script (havent had the time)      

### 2. fix windows clock, so that it is correct
>   ```sh
>    timedatectl set-local-rtc 1
>   ```
### 3. configure mouse speed (not acc) beyond the gui setting limit
see manual  config - [link](trackpad.md)        


### 4. Set up git ssh
[link](shh_git.md)

### 5. Get scripts
###
>   ```sh
>    sudo mv ../global/* /usr/local/bin
>   ```

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


#### 7.3  ohmyzsh       



### 8. get emacs        

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




### Other install things
[zen_installer](https://github.com/spookykidmm/zen_installer)      



