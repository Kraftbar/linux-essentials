# Things i do with a fresh linux install (mainly xps15 9760)



### 0. install nvidia drivers so no cpu lockup at shutdown
also, select intel as gpu so power consumption is not degenerate
### 0.1 connect to eduroam
run script - eduroam-linux-Ntu-N.sh

### 1. get the applet that allows for automatic sleep when low battery
>  [BAMS](https://cinnamon-spices.linuxmint.com/applets/view/255)      

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

get albert [link](install_Albert.sh)
<br>
<br>
#### 7.1


<br>
>   ```sh
> # start emacs server
> if [ -z "$(/usr/bin/pgrep -u $USER -x -f '/usr/bin/emacs --daemon')" ] ; then
>     /usr/bin/emacs --daemon 2> /dev/null
> fi
> 
> EDITOR="/usr/bin/emacsclient --quiet --create-frame"
> VISUAL=$EDITOR
> export EDITOR VISUAL
>   ```


~/.config/mimeapps.list     (copy xed settings, replace with emacs) then make default           

get init files         
<br>
#### 7.2

### 8. Get emacs        

Set emacsclient as your default editor, and add (server-start) somewere in your emacs config.

There needs to be a running Emacs instance for emacsclient to work, but if it's a hassle it's possible to have a headless Emacs launched at login.

### Other install things
[zen_installer](https://github.com/spookykidmm/zen_installer)      
