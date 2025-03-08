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

# Define script categories and their script URLs
declare -A script_folders
script_folders["Linux"]=(
    "Update ubuntu apt:ubuntu_update.sh"
    "Docker install:docker_install.sh"
    "Create User:create_user.sh"
    "Setup GitHub:setup_github.sh"
    "Setup K8S:setup_k8s.sh"
)

script_folders["Networking"]=(
    "Setup Static IP:static_ip_setup.sh"
    "Update Hostname:update_hostname.sh"
)

script_folders["Kubernetes"]=(
    "Setup Kubernetes:setup_k8s.sh"
)

GITHUB_BASE_URL="https://raw.githubusercontent.com/Axande/Scripting/refs/heads/main"

# Select folder first
folder_options=("All")
for folder in "${!script_folders[@]}"; do
    folder_options+=("$folder")
done

selected_folder=""
select selected_folder in "${folder_options[@]}"; do
    if [[ -n "$selected_folder" ]]; then
        break
    fi
done

# If "All" is selected, run all scripts from all folders
if [[ "$selected_folder" == "All" ]]; then
    for folder in "${!script_folders[@]}"; do
        mkdir -p "$folder"
        for script_entry in "${script_folders[$folder][@]}"; do
            script_name="${script_entry#*:}"
            script_path="$folder/$script_name"
            echo "Downloading: $script_path"
            wget -O "$script_path" "$GITHUB_BASE_URL/$script_name"
            chmod +x "$script_path"
            echo "Running: $script_path"
            sudo "$script_path"
        done
    done
    exit 0
fi

# Prepare script options for the selected folder
script_options=("All")
declare -A script_map
for script_entry in "${script_folders[$selected_folder][@]}"; do
    script_name="${script_entry#*:}"
    script_options+=("$script_name")
    script_map["$script_name"]="$selected_folder/$script_name"
done

# Select script(s) to run
selected_scripts=()
select script_choice in "${script_options[@]}"; do
    if [[ -n "$script_choice" ]]; then
        if [[ "$script_choice" == "All" ]]; then
            mkdir -p "$selected_folder"
            for script_name in "${script_map[@]}"; do
                script_path="$selected_folder/$script_name"
                echo "Downloading: $script_path"
                wget -O "$script_path" "$GITHUB_BASE_URL/$script_name"
                chmod +x "$script_path"
                echo "Running: $script_path"
                sudo "$script_path"
            done
            exit 0
        else
            selected_scripts+=("$script_choice")
        fi
    fi
    [[ "${#selected_scripts[@]}" -gt 0 ]] && break
done

# Execute selected scripts
mkdir -p "$selected_folder"
for script in "${selected_scripts[@]}"; do
    script_path="$selected_folder/$script"
    echo "Downloading: $script_path"
    wget -O "$script_path" "$GITHUB_BASE_URL/$script"
    chmod +x "$script_path"
    echo "Running: $script_path"
    sudo "$script_path"
done
