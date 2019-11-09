#!/bin/sh

userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap
sysresources=/etc/X11/xinit/.Xresources
sysmodmap=/etc/X11/xinit/.Xmodmap

DEFAULT_SESSION='i3 --shmlog-size 0'

# merge in defaults and keymaps

if [ -f $sysresources ]; then
    xrdb -merge $sysresources
fi

if [ -f $sysmodmap ]; then
    xmodmap $sysmodmap
fi

if [ -f "$userresources" ]; then
    xrdb -merge "$userresources"
fi

if [ -f "$usermodmap" ]; then
    xmodmap "$usermodmap"
fi

# start some nice programs

if [ -d /etc/X11/xinit/xinitrc.d ] ; then
 for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
  [ -x "$f" ] && . "$f"
 done
 unset f
fi

#wmname LG3D
#nvidia-settings -a [gpu:0]/GPUPowerMizerMode=1 &

IN=$(xrandr | grep "LVDS-0" | grep " connected" | sed -e "s/\([A-Z0-9]\+\) connected.*/\1/")
EXT=$(xrandr | grep "DP-5" | grep " connected" | sed -e "s/\([A-Z0-9]\+\) connected.*/\1/")

if (xrandr | grep "$EXT disconnected"); then
    xrandr --output $EXT --off --output $IN --auto
else
    xrandr --output $IN --off --output $EXT --auto
fi

xrandr --dpi 96
xset b off
ibus-daemon -drx &
nvidia-settings -a [gpu:0]/GPUPowerMizerMode=1 &
#source ~/bin/autorun.sh

get_session(){
	local dbus_args=(--sh-syntax --exit-with-session)
	case $1 in
		awesome) dbus_args+=(awesome) ;;
		bspwm) dbus_args+=(bspwm-session) ;;
		budgie) dbus_args+=(budgie-desktop) ;;
		cinnamon) dbus_args+=(cinnamon-session) ;;
		deepin) dbus_args+=(startdde) ;;
		enlightenment) dbus_args+=(enlightenment_start) ;;
		fluxbox) dbus_args+=(startfluxbox) ;;
		gnome) dbus_args+=(gnome-session) ;;
		i3|i3wm) dbus_args+=(i3 --shmlog-size 0) ;;
		jwm) dbus_args+=(jwm) ;;
		kde) dbus_args+=(startkde) ;;
		lxde) dbus_args+=(startlxde) ;;
		lxqt) dbus_args+=(lxqt-session) ;;
		mate) dbus_args+=(mate-session) ;;
		xfce) dbus_args+=(xfce4-session) ;;
		openbox) dbus_args+=(openbox-session) ;;
		*) dbus_args+=($DEFAULT_SESSION) ;;
	esac

	echo "dbus-launch ${dbus_args[*]}"
}


#exec $(get_session)
#exec awesome
#exec ~/.config/dwm/startdwm
#exec bspwm
exec startxfce4
#exec herbstluftwm
#exec spectrwm
#exec /usr/bin/ratpoison
#exec ion3
#exec openbox-session
#exec notion
#exec xmonad
#exec 2bwm
#exec startfluxbox
