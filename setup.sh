#!/bin/bash

source ./scripts/multiselectMenu.sh

# Define scripts and their display names
declare -A scripts
scripts["Update ubuntu apt"]="linux/ubuntu_update.sh"
scripts["Docker install"]="linux/docker_install.sh"
scripts["Create User"]="linux/create_user.sh"
scripts["Setup GitHub"]="linux/setup_github.sh"
scripts["Setup Kubernetes"]="linux/setup_k8s.sh"
scripts["Setup Static IP"]="linux/static_ip_setup.sh"
scripts["Update Hostname"]="linux/update_hostname.sh"

# Prepare multiselect menu options
options=("All")
paths=("All")
for name in "${!scripts[@]}"; do
    options+=("$name")
    paths+=("${scripts[$name]}")
done

# Default preselection array
preselection=("false" "false" "false" "false" "false" "false")

# Store results in an array
result=()

# Use multiselect function
multiselect result options preselection

# Run selected scripts
idx=0
for option in "${options[@]}"; do
    if [ "${result[idx]}" == "true" ] || [ "${result[0]}" == "true" ]; then
        if [ "$option" == "All" ]; then
            for script in "${scripts[@]}"; do
                echo "Running: $script"
                bash "$script"
            done
            break
        else
            script_path="${scripts[$option]}"
            echo "Running: $script_path"
            bash "$script_path"
        fi
    fi
    ((idx++))
done
