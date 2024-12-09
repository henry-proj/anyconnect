#!/usr/bin/env bash

ANYCONNECT_CMD=/opt/cisco/anyconnect/bin/vpn
CONN_INFO=(
"VPN_ADDRESS USERNAME PASSWORD"
"vpn.github.com:8843 zhangsan 123456"
"Exit"
)

_exists() {
    cmd="$1"
    if [ -z "$cmd" ]; then
        _usage "Usage: _exists cmd"
        return 1
    fi

    if eval type type >/dev/null 2>&1; then
        eval type "$cmd" >/dev/null 2>&1
    elif command >/dev/null 2>&1; then
        command -v "$cmd" >/dev/null 2>&1
    else
        which "$cmd" >/dev/null 2>&1
    fi
    ret="$?"
    return $ret
}

_contains() {
    _str="$1"
    _sub="$2"
    echo "$_str" | grep -- "$_sub" >/dev/null 2>&1
}

check_and_stop_anyconnect() {
    if ! _exists pgrep ;then
        echo "prgep command does not exist."
        exit 1
    fi

    if ! _exists pkill ;then
        echo "pkill command does not exist."
        exit 1
    fi

	if pgrep -f "AnyConnect" > /dev/null; then
		read -r -p "The AnyConnect Secure Mobility Client is running. Do you want to stop the desktop client? (y/N): "  response
		if [[ "$response" == "y" || "$response" == "Y" ]]; then
			pkill -f "AnyConnect"
			echo "The desktop client has stopped."
		else
			echo "Please exit the desktop client before running this script"
			exit 1
		fi
	fi
}

select_option() {

    # little helpers for terminal print control and key input
    ESC=$( printf "\033")
    cursor_blink_on()  { printf "$ESC[?25h"; }
    cursor_blink_off() { printf "$ESC[?25l"; }
    cursor_to()        { printf "$ESC[$1;${2:-1}H"; }
    print_option()     { printf " $1 "; }
    print_selected()   { printf "$ESC[7m $1 $ESC[27m"; }
    get_cursor_row()   { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${ROW#*[}; }
    key_input()        { read -s -n3 key 2>/dev/null >&2
                         if [[ $key = $ESC[A ]]; then echo up;    fi
                         if [[ $key = $ESC[B ]]; then echo down;  fi
                         if [[ $key = ""     ]]; then echo enter; fi; }

    # initially print empty new lines (scroll down if at bottom of screen)
    for opt; do printf "\n"; done

    # determine current screen position for overwriting the options
    local lastrow=`get_cursor_row`
    local startrow=$(($lastrow - $#))

    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    local selected=0
    while true; do
        # print options by overwriting the last lines
        local idx=0
        for opt; do
            cursor_to $(($startrow + $idx))
            if [ $idx -eq $selected ]; then
                print_selected "$opt"
            else
                print_option "$opt"
            fi
            ((idx++))
        done

        # user key control
        case `key_input` in
            enter) break;;
            up)    ((selected--));
                   if [ $selected -lt 0 ]; then selected=$(($# - 1)); fi;;
            down)  ((selected++));
                   if [ $selected -ge $# ]; then selected=0; fi;;
        esac
    done

    # cursor position back to normal
    cursor_to $lastrow
    printf "\n"
    cursor_blink_on

    return $selected

    #echo "Select one option using up/down keys and enter to confirm:"
    #echo
    #
    #options=("one" "two" "three")
    #
    #select_option "${options[@]}"
    #choice=$?
    #
    #echo "Choosen index = $choice"
    #echo "        value = ${options[$choice]}"

    #case `select_opt "Yes" "No" "Cancel"` in
    #    0) echo "selected Yes";;
    #    1) echo "selected No";;
    #    2) echo "selected Cancel";;
    #esac
}


select_opt() {
    select_option "$@" 1>&2
    local result=$?
    echo $result
    return $result
}

connect() {
    options=($(echo ${CONN_INFO[@]%% *}))
    case `select_opt "${options[@]}"` in
      *)
        host=${options[$?]}
        if [ "$host" == "Exit" ];then
            echo "Exiting..."
            exit 0
        fi
        echo "connect $host"
        ;;
    esac

    for ((i=0;i<${#CONN_INFO[*]};i++))
    do
       if [[ "`echo ${CONN_INFO[i]}|awk '{print $1}'`" == "$host" ]];then
           user=`echo ${CONN_INFO[i]}|awk '{print $2}'`
           pass=`echo ${CONN_INFO[i]}|awk '{print $3}'`
       fi
    done
	$ANYCONNECT_CMD -s connect $host <<-EOF
	$user
	$pass
	y
	EOF
}

disconnect() {
    $ANYCONNECT_CMD disconnect
}

state() {
    $ANYCONNECT_CMD state
}

stats() {
    $ANYCONNECT_CMD stats
}

showhelp() {
    echo "Usage: $0 [command]

Commands:
  -h, --help                                                        Show this help message.
  -c|-con|-conn|-connect, --c|--con|--conn|--connect                Connect VPN Server.
  -d|-dis|-disconn|-disconnect, --d|--dis|--disconn|--disconnect    DisConnect VPN Server.
  -r, --r|--reconn|--reconnect                                      Reconnect VPN Server.
  -s|-state|-status, --s|--state|--status                           View VPN connection status.
  -stats, --stats                                                   View VPN Statistics.
"
}

main() {
    check_and_stop_anyconnect

    if ! _exists "$ANYCONNECT_CMD";then
        echo "$ANYCONNECT_CMD not exist."
        exit 1
    fi
    args=$1
    case $args in
      -c|-con|-conn|-connect|--c|--con|--conn|--connect)
        connect
        state
        ;;
      -d|-dis|-disconn|-disconnect|--d|--dis|--disconn|--disconnect)
        disconnect
        state
        ;;
      -r|--r|--reconn|--reconnect)
        disconnect
        connect
        state
        ;;
      -s|-state|-status|--s|--state|--status)
        state
        ;;
      -stats|--stats)
        stats
        ;;
      *|-h|--help)
        showhelp
    esac
}

main $@
