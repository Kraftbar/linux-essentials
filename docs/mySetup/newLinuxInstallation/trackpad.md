# Ubuntu 16.04 xinput
Setup Mouse/Touchpad speed and configure tap-to-click on the touch pad

## display all input devices
```bash
xinput --list
⎡ Virtual core pointer                    	id=2	[master pointer  (3)]
⎜   ↳ Virtual core XTEST pointer              	id=4	[slave  pointer  (2)]
⎜   ↳ USBest Technology SiS HID Touch Controller	id=11	[slave  pointer  (2)]
⎜   ↳ Elan Touchpad                           	id=14	[slave  pointer  (2)]
⎣ Virtual core keyboard                   	id=3	[master keyboard (2)]
    ↳ Virtual core XTEST keyboard             	id=5	[slave  keyboard (3)]
    ↳ Power Button                            	id=6	[slave  keyboard (3)]
    ↳ Asus Wireless Radio Control             	id=7	[slave  keyboard (3)]
    ↳ Video Bus                               	id=8	[slave  keyboard (3)]
    ↳ Video Bus                               	id=9	[slave  keyboard (3)]
    ↳ Sleep Button                            	id=10	[slave  keyboard (3)]
    ↳ USB2.0 HD UVC WebCam                    	id=12	[slave  keyboard (3)]
    ↳ Asus WMI hotkeys                        	id=15	[slave  keyboard (3)]
    ↳ AT Translated Set 2 keyboard            	id=16	[slave  keyboard (3)]
```

## list details for a specific device
```bash
xinput --list-props 14
Device 'Elan Touchpad':
	Device Enabled (169):	1
	Coordinate Transformation Matrix (171):	1.000000, 0.000000, 0.000000, 0.000000, 1.000000, 0.000000, 0.000000, 0.000000, 1.000000
	libinput Tapping Enabled (323):	1
	libinput Tapping Enabled Default (324):	0
	libinput Tapping Drag Enabled (325):	1
	libinput Tapping Drag Enabled Default (326):	1
	libinput Tapping Drag Lock Enabled (327):	0
	libinput Tapping Drag Lock Enabled Default (328):	0
	libinput Accel Speed (306):	0.000000
	libinput Accel Speed Default (307):	0.000000
	libinput Natural Scrolling Enabled (311):	0
	libinput Natural Scrolling Enabled Default (312):	0
	libinput Send Events Modes Available (286):	1, 1
	libinput Send Events Mode Enabled (287):	0, 0
	libinput Send Events Mode Enabled Default (288):	0, 0
	libinput Left Handed Enabled (313):	0
	libinput Left Handed Enabled Default (314):	0
	libinput Scroll Methods Available (315):	1, 1, 0
	libinput Scroll Method Enabled (316):	1, 0, 0
	libinput Scroll Method Enabled Default (317):	1, 0, 0
	libinput Click Methods Available (329):	1, 1
	libinput Click Method Enabled (330):	1, 0
	libinput Click Method Enabled Default (331):	1, 0
	libinput Disable While Typing Enabled (332):	1
	libinput Disable While Typing Enabled Default (333):	1
	Device Node (289):	"/dev/input/event14"
	Device Product ID (290):	1267, 5
	libinput Drag Lock Buttons (322):	<no items>
	libinput Horizonal Scroll Enabled (291):	1
```

## increase the trackpad tracking speed ( increase it by 4 times )
```bash
xinput --set-prop 14 171 4.000000, 0.000000, 0.000000, 0.000000, 4.000000, 0.000000, 0.000000, 0.000000, 1.000000
```
## enable tap-to-click
```bash
xinput --set-prop 14 323 1
```
