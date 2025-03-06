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

# Ask for the role (group)
read -p "Enter the role (group) for the user: " role

# Create the group if it doesn't exist
if ! getent group "$role" > /dev/null; then
    echo "Group '$role' does not exist. Creating it now..."
    sudo groupadd "$role"
fi

# Generate a random password
password=$(generate_password)

# Create the user with the specified group and set the password
sudo useradd -m -g "$role" -s /bin/bash "$username"
echo "$username:$password" | sudo chpasswd

# Force password change on first login
sudo passwd --expire "$username"

# Display the created username and password
echo "User '$username' has been created with the role '$role'."
echo "Generated password: $password"

