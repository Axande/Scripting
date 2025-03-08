#!/bin/bash

function multiselect {
    # Little helpers for terminal print control and key input
    ESC=$(printf "\033")
    cursor_blink_on() { printf "$ESC[?25h"; }
    cursor_blink_off() { printf "$ESC[?25l"; }
    cursor_to() { printf "$ESC[$1;${2:-1}H"; }
    print_inactive() { printf "$2   $1 "; }
    print_active() { printf "$2  $ESC[7m $1 $ESC[27m"; }
    get_cursor_row() {
        IFS=';' read -sdR -p $'\E[6n' ROW COL
        echo ${ROW#*[}
    }

    log_info "Press Space to select options and Enter to continue"

    # Inputs
    local return_value=$1
    local -n options=$2
    local -n defaults=$3

    local selected=()
    # Initialize selected options based on defaults
    for ((i = 0; i < ${#options[@]}; i++)); do
        selected+=("${defaults[i]:-false}")
        printf "\n"
    done

    # Determine current screen position for overwriting the options
    local lastrow=$(get_cursor_row)
    local startrow=$((lastrow - ${#options[@]}))

    # Ensure cursor and input echoing back on upon Ctrl+C
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    # Handle key input
    key_input() {
        local key
        IFS= read -rsn1 key 2>/dev/null >&2
        case "$key" in
        "") echo "enter" ;;
        $'\x20') echo "space" ;;
        "k") echo "up" ;;
        "j") echo "down" ;;
        $'\x1b')
            read -rsn2 key
            case "$key" in
            "[A") echo "up" ;;
            "[B") echo "down" ;;
            esac
            ;;
        esac
    }

    # Toggle the selected state of an option
    toggle_option() {
        local option=$1
        if [[ ${selected[option]} == "true" ]]; then
            selected[option]="false"
        else
            selected[option]="true"
        fi
    }

    # Print all options
    print_options() {
        local idx=0
        for option in "${options[@]}"; do
            local prefix="[ ]"
            if [[ ${selected[idx]} == "true" ]]; then
                prefix="[\e[38;5;46m✔\e[0m]"
            fi

            cursor_to $((startrow + idx))
            if [[ $idx -eq $1 ]]; then
                print_active "$option" "$prefix"
            else
                print_inactive "$option" "$prefix"
            fi
            ((idx++))
        done
    }

    # Main logic
    local active=0
    while true; do
        print_options $active

        # User key control
        case "$(key_input)" in
        "space") toggle_option $active ;;
        "enter")
            print_options -1
            break
            ;;
        "up")
            ((active--))
            if [[ $active -lt 0 ]]; then active=$((${#options[@]} - 1)); fi
            ;;
        "down")
            ((active++))
            if [[ $active -ge ${#options[@]} ]]; then active=0; fi
            ;;
        esac
    done

    # Restore cursor and print new line
    cursor_to $lastrow
    printf "\n"
    cursor_blink_on

    # Return the selected options
    eval $return_value='("${selected[@]}")'
}
