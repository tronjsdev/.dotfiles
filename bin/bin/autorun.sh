#! /bin/bash
killall compton
killall nitrogen
killall alttab
killall dunst
killall ibus-daemon
killall nm-applet
killall pamac-tray
killall polkit-mate-aut
killall volumeicon
killall stalonetray

alttab -fg "#9EB7C0" -bg "#222D31" -frame "#0049FF" -t 128x150 -i 127x64 &
xset b off
ibus-daemon -drx &
nvidia-settings -a [gpu:0]/GPUPowerMizerMode=1 &
nitrogen --restore; sleep 1
#feh --bg-scale ~/wallpaper.jpg &
compton -bC &
dunst &
xinput set-prop 9 'libinput Accel Speed' 0.5 &
/usr/lib/mate-polkit/polkit-mate-authentication-agent-1 &
nm-applet &
pamac-tray &
volumeicon &
wmname LG3D &
sleep 5
stalonetray -c ~/.config/stalonetray/config &
