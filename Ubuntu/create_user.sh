#!/bin/bash

# Function to generate a random password
generate_password() {
    tr -dc 'A-Za-z0-9@#$%^&*' < /dev/urandom | head -c 12
}

# Ask for the username
read -p "Enter the new username: " username

# Check if the user already exists
if id "$username" &>/dev/null; then
    echo "Error: User '$username' already exists."
    exit 1
fi

# Ask if the user should be an admin
read -p "Should this user be an admin? (yes/no): " is_admin

# Generate a random password
password=$(generate_password)

# Create the user and set the password
sudo useradd -m -s /bin/bash "$username"
echo "$username:$password" | sudo chpasswd

# Add the user to sudo (admins) group if selected
if [[ "$is_admin" == "yes" ]]; then
    sudo usermod -aG sudo "$username"
    echo "User '$username' has been added to the sudo (admin) group."
fi

# Force password change on first login
sudo passwd --expire "$username"

# Display the created username and password
echo "User '$username' has been created."
echo "Generated password: $password"
