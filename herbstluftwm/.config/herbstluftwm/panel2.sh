#!/bin/bash

# Check which monitor this is
monitor=${1:-0}
geometry=( $(herbstclient monitor_rect "$monitor") )

if [ -z "$geometry" ]; then
  echo >&2 "Invalid monitor: $monitor"
  exit 1
fi

# Config stuff
x=${geometry[0]}
y=${geometry[1]}
#panel_width=${geometry[2]}
panel_height=14

font="-*-fixed-medium-*-*-*-13-*-*-*-*-*-*-*"
bgcolor="$HC_BACKGROUND"
fgcolor='#EFEFEF'
selbg="$(herbstclient get window_border_active_color)"
selfg="$fgcolor"


# Output is piped through this function before reaching the panel
function pre_filter {
  cat
}

function uniq_linebuffered() {
  awk '$0 != l { print ; l=$0 ; fflush(); }' "$@"
}

function run_stalonetray {
  stalonetray -bg "$bgcolor" --geometry '1x1-0+0' --grow-gravity E \
              -i 16 --log-level info 2>&1                          \
    | tee /tmp/bleh3 \
    | grep '' \
    | tee /tmp/bleh
   #| sed -nr '/^geometry:/ {s/^geometry:/stalonetray_geometry/; s/[-+x]/ /g; p}' \
}

# Begin actual bar implementation
herbstclient pad $monitor $panel_height
{
  ##-- Event emitters -----------------
  # player (mpd)
  mpc idleloop player &
  mpc_pid=$!

# run_stalonetray &
# stalonetray_pid=$(pidof stalonetray)

  # tick
  while true; do echo tick; sleep 20; done &
  tick_pid=$!

  # date
  while true; do
    date +'date ^fg()%H^fg(#909090):^fg()%M^fg(#909090), %Y-%m-^fg()%d'
    sleep 1 || break
  done > >(uniq_linebuffered) &
  date_pid=$!

  # hlwm events
  herbstclient --idle

  # exiting; kill stray event-emitting processes
  kill $date_pid $mpc_pid $tick_pid $stalonetray_pid

} 2>/dev/null | {
  # Default values for the panel-drawing part
  TAGS=( $(herbstclient tag_status $monitor) )
  visible=true

  windowtitle=""

  Default="^fg()--"
  sep="^bg()^fg($selbg) "

  # fields of the right panel
  date="$Default"
  brightstatus="$Default"
  batstatus="$Default"
  thermstatus="$Default"
  nowplaying="$Default"
  wicdstatus="$Default"

  traypadding=0

  while true; do
    ##-- Draw panel -------------------
    # First, draw tags to left panel
    for i in "${TAGS[@]}"; do
      case ${i:0:1} in
      # '.')                                      ;; # Empty
        ':')  echo -n "^bg()^fg(#ffffff)"         ;; # Not empty
        '+')  echo -n "^bg(#9CA668)^fg(#141414)"  ;; # Viewed on this monitor, not focused
        '#')  echo -n "^bg($selbg)^fg($selfg)"    ;; # Viewed on this monitor, is focused
      # '-')                                      ;; # Viewed on other monitor, not focused
      # '%')                                      ;; # Viewed on other monitor, is focused
        '!')  echo -n "^bg(#FF0675)^fg(#141414)"  ;; # Contains urgent window
         * )  echo -n "^bg()^fg(#ababab)"         ;; # Default
      esac

      echo -n "^ca(1,herbstclient focus_monitor $monitor && "'herbstclient use "'${i:1}'") '"${i:1} ^ca()"
    done

    # Then, draw the rest of the left panel
    echo -n "$sep"
    echo "^bg()^fg() ${windowtitle//^/^^}"

    # Then, the right panel
    echo >&3 -n " $sep $brightstatus"  # ☀
    echo >&3 -n " $sep $thermstatus"   # ♨
    echo >&3 -n " $sep $batstatus"     # ⚡
    echo >&3 -n " $sep $nowplaying"    # ♫
    echo >&3 -n " $sep $wicdstatus"    # ⌬
    echo >&3 -n " $sep $date"          # ⌚
    echo >&3 -n " $sep "
    echo >&3

    ##-- Listen for events ------------
    read line || break
    cmd=( $line )
    # branch on event origin
    case "${cmd[0]}" in
      # First, herbstluft's built-in events...
      tag*)
        #echo "reseting tags" >&2
        TAGS=( $(herbstclient tag_status $monitor) )
        ;;

      quit_panel|reload)
        exit
        ;;

      togglehidepanel)
        echo "^togglehide()"
        if $visible ; then
            visible=false
            herbstclient pad $monitor 0
        else
            visible=true
            herbstclient pad $monitor $panel_height
        fi
        ;;

      focus_changed|window_title_changed)
        windowtitle="${cmd[@]:2}"
        ;;

      # ...then, custom events
      toggle_runner)
        dmenu_run -fn "$font" -nb "$bgcolor" -nf "$fgcolor" \
                  -sb "$selbg" -sf "$selfg"
        ;;

      date)
        #echo "reseting date" >&2
        date="${cmd[@]:1}"
        ;;

      brightness)
        brightstatus="$(printf '^fg()%d^fg(#909090)%%' $(backlight.sh '?'))"
        ;;

      tick)
        batstatus="$( t='/sys/class/power_supply/BAT1/'
                      curr=$(cat $t/charge_now)
                      full=$(cat $t/charge_full_design)
                      status=$(cat $t/status)
                      percent=$(printf '100 * %d / %d\n' $curr $full | bc)

                      color=$( ([ "$percent" -le 10 ] && echo '^bg(#CC3333)') ||
                               ([ "$percent" -le 25 ] && echo '^bg(#AA8800)') ||
                               (true                  && echo '^bg()') )

                      case $status in
                        Full|Unknown)  printf '^fg(#909090)%s' $status ;;
                        *)  printf '^fg(#909090)%s:^fg()%s %d%% ^bg()' $status $color $percent ;;
                      esac )"

        thermstatus="$( t='/sys/class/thermal/thermal_zone0'
                        curr=$(cat $t/temp)
                        degrees=$(printf '%d / 1000\n' $curr | bc)
                        printf '^fg()%d^fg(#909090)°C' $degrees )"

        wicdstatus="$( essid=$(wicd-cli -d --wireless \
                             | grep Essid | cut -d' ' -f2-)
                       [ -z "$essid" ] && essid='--'
                       printf '^fg()%s' $essid )"
        ;;

      mpd_player|player)
        nowplaying="$(mpc current -f '^fg()[%artist% - ][%title%|%file%]')"
        ;;

      stalonetray_geometry)
        traypadding="${cmd[@]:1}"
        ;;
    esac
  done
} 2>/dev/null \
  1> >(pre_filter | dzen2  -fn "$font"  -y $y  -h $panel_height  -expand right \
          -fg "$fgcolor" -bg "$bgcolor") \
  3> >(pre_filter | dzen2  -fn "$font"  -y $y  -h $panel_height  -expand left \
          -fg "$fgcolor" -bg "$bgcolor")