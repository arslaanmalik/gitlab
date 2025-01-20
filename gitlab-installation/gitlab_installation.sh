#!/bin/bash

# Section 1: Update system packages and install necessary tools
echo "Updating system packages and installing essential tools..."
sudo dnf install -y curl policycoreutils openssh-server perl
echo "Installed curl, policycoreutils, openssh-server, and perl."

# Section 2: Enable and start the SSH service
echo "Enabling and starting the SSH service..."
sudo systemctl enable sshd
sudo systemctl start sshd
echo "SSH service is now enabled and started."

# Section 3: Configure the firewall to allow HTTP and HTTPS traffic
echo "Configuring the firewall to allow HTTP and HTTPS traffic..."
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo systemctl reload firewalld
echo "Firewall rules updated to allow HTTP and HTTPS traffic."

# Section 4: Install and start the Postfix mail server
echo "Installing the Postfix mail server..."
sudo dnf install -y postfix
echo "Postfix installation completed."

echo "Enabling and starting the Postfix service..."
sudo systemctl enable postfix
sudo systemctl start postfix
echo "Postfix service is now enabled and started."

# Section 5: Add GitLab repository and install GitLab EE
echo "Adding GitLab repository to your system..."
curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.rpm.sh | sudo bash
echo "GitLab repository added successfully."

echo "Installing GitLab Enterprise Edition (EE)..."
sudo dnf install -y gitlab-ee
echo "GitLab EE installed successfully."

# Section 6: Function to edit the GitLab configuration file
edit_gitlab_rb() {
    local ip_address=$1
    local file_path="/etc/gitlab/gitlab.rb"

    # Inform the user
    echo "Updating external_url in $file_path with IP: $ip_address..."

    # Use `sed` to replace the external_url line with the new IP
    sudo sed -i "s|^external_url .*|external_url 'http://$ip_address'|g" "$file_path"

    echo "external_url updated to 'http://$ip_address' successfully!"
}

# Section 7: Detect IP address and configure GitLab external URL
# Get the inet IP address using ifconfig or ip (depending on availability)
if command -v ifconfig > /dev/null; then
    inet_ip=$(ifconfig | grep -oP 'inet \K[\d.]+' | grep -v '127.0.0.1' | head -n 1)
elif command -v ip > /dev/null; then
    inet_ip=$(ip addr show | grep -oP 'inet \K[\d.]+' | grep -v '127.0.0.1' | head -n 1)
else
    echo "Neither ifconfig nor ip command is available. Exiting."
    exit 1
fi

# Display the detected IP address to the user
echo "Detected IP address: $inet_ip"
read -p "Do you want to use this IP address? (y/n): " user_choice

if [[ "$user_choice" == "y" || "$user_choice" == "Y" ]]; then
    # Update the gitlab.rb file with the detected IP
    edit_gitlab_rb "$inet_ip"
elif [[ "$user_choice" == "n" || "$user_choice" == "N" ]]; then
    # Prompt the user to enter an IP address manually
    read -p "Please enter the IP address manually: " manual_ip
    edit_gitlab_rb "$manual_ip"
else
    echo "Invalid choice. Exiting."
    exit 1
fi

# Section 8: Reconfigure GitLab to apply changes
echo "Reconfiguring GitLab to apply the new settings..."
sudo gitlab-ctl reconfigure

# Section 9: Final message
echo "Reconfiguration completed. GitLab is now set up with the new external URL."
echo "Access your GitLab instance via the configured external URL."
