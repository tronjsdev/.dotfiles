#! /bin/bash
killall compton
killall nitrogen
killall alttab
killall dunst
killall ibus-daemon
killall nm-applet
killall pamac-tray
killall polkit-mate-aut
killall stalonetray

#alttab -fg "#9EB7C0" -bg "#222D31" -frame "#1E90FF" -t 128x150 -i 127x64 &
xset b off
nitrogen --restore; sleep 1
compton -bC &
dunst &
#feh --bg-scale ~/wallpaper.jpg &
ibus-daemon -drx &
nvidia-settings -a [gpu:0]/GPUPowerMizerMode=1 &
xinput set-prop 9 'libinput Accel Speed' 0.5 &
/usr/lib/mate-polkit/polkit-mate-authentication-agent-1 &
nm-applet &
pamac-tray &
#stalonetray -c ~/.config/stalonetray/config &
#wmname LG3D &
