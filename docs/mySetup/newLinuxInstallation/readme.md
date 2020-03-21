# Things i do with a fresh linux install (mainly xps15 9760)



### 0. install nvidia drivers so no cpu lockup at shutdown

### 0.1 connect to eduroam
run script - eduroam-linux-Ntu-N.sh

### 1. get the applet that allows for automatic sleep when low battery
>  [BAMS](https://cinnamon-spices.linuxmint.com/applets/view/255)      

### 2. config so that windows clock is correct
dont remember, adding later

### 3. configure mouse speed (not acc) beyond the gui setting limit
see manual  config - trackpad.txt



### 4. Set up ssh


### 5. Get scripts
###
>   ```sh
>    sudo mv ../global/* /usr/local/bin
>   ```

### 6. Get dot files

### 6. Set aliases
see file

### 7. Get programs

<br>
<br>
<br>
<br>


### 8. Get emacs        

Set emacsclient as your default editor, and add (server-start) somewere in your emacs config.

There needs to be a running Emacs instance for emacsclient to work, but if it's a hassle it's possible to have a headless Emacs launched at login.

### Other install things
[zen_installer](https://github.com/spookykidmm/zen_installer)      
