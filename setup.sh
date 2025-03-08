# Define script categories and their script URLs
declare -A script_folders
script_folders["linux"]="Update ubuntu apt;ubuntu_update.sh;Docker install;docker_install.sh;Create User;create_user.sh;Setup GitHub;setup_github.sh"
script_folders["networking"]="Setup Static IP;static_ip_setup.sh;Update Hostname;update_hostname.sh"
script_folders["kubernetes"]="Setup Kubernetes;setup_k8s.sh"

GITHUB_BASE_URL="https://raw.githubusercontent.com/Axande/Scripting/refs/heads/main"

# Function to select a folder
select_folder() {
    local folder_options=()
    for folder in "${!script_folders[@]}"; do
        folder_options+=("$folder")
    done

    local selected_folder=""
    select selected_folder in "${folder_options[@]}"; do
        if [[ -n "$selected_folder" ]]; then
            echo "$selected_folder"
            return
        fi
    done
}

# Function to select scripts within a folder
select_scripts() {
    local selected_folder="$1"
    local script_options=()
    declare -A script_map
    
    IFS=';' read -ra script_entries <<< "${script_folders[$selected_folder]}"
    for ((i = 0; i < ${#script_entries[@]}; i += 2)); do
        script_name="${script_entries[i]}"
        script_file="${script_entries[i+1]}"
        script_options+=("$script_name")
        script_map["$script_name"]="$selected_folder/$script_file"
    done

    local selected_scripts=()
    select script_choice in "${script_options[@]}"; do
        if [[ -n "$script_choice" ]]; then
            selected_scripts+=("${script_map[$script_choice]}")
        fi
        if [[ "${#selected_scripts[@]}" -gt 0 ]]; then
            echo "${selected_scripts[@]}"
            return
        fi
    done
}

# Function to download and execute scripts
download_and_execute() {
    local script_paths=($@)
    for script_path in "${script_paths[@]}"; do
        local folder_path="$(dirname "$script_path")"
        local script_name="$(basename "$script_path")"

        mkdir -p "$folder_path"
        echo "Downloading: $script_path"
        wget -O "$script_path" "$GITHUB_BASE_URL/$script_name"
        chmod +x "$script_path"
        echo "Running: $script_path"
        sudo "$script_path"
    done
}

# Main execution
selected_folder=$(select_folder)
script_paths=($(select_scripts "$selected_folder"))
download_and_execute "${script_paths[@]}"
