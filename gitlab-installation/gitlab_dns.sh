#!/bin/bash

# Function to display messages
echo_message() {
    echo "=============================="
    echo "$1"
    echo "=============================="
}

# Section 1: Check for root user
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Please run with sudo."
    exit 1
fi

# Section 2: Prompt user to enter domain for GitLab
echo_message "Please enter the domain for GitLab (e.g., dev.gitlab.com):"
read -p "Domain: " domain

# Validate if the entered domain is in the correct format
if [[ ! "$domain" =~ ^[a-zA-Z0-9.-]+$ ]]; then
    echo "Invalid entry. Exiting."
    exit 1
fi

# Section 3: Get the full URL (including http/https) from gitlab.rb file
echo_message "Retrieving the current external URL from /etc/gitlab/gitlab.rb..."

# Extract the external URL from gitlab.rb
external_url=$(grep -oP "external_url\s+'http[s]?://\K[a-zA-Z0-9.-]+" /etc/gitlab/gitlab.rb)

if [ -z "$external_url" ]; then
    echo "Unable to retrieve external URL from gitlab.rb. Exiting."
    exit 1
fi

# Display the detected external URL
echo_message "Detected external URL: $external_url"

# Section 4: Update /etc/hosts file
echo_message "Updating /etc/hosts file with domain $domain and IP address."

# Retrieve the IP address of the machine
machine_ip=$(hostname -I | awk '{print $1}')

# Add the entry in /etc/hosts
sudo bash -c "echo '$machine_ip    $domain' >> /etc/hosts"

# Section 5: Update GitLab configuration to replace external_url with the new domain
echo_message "Updating GitLab configuration file gitlab.rb with domain."

# Update the external_url in gitlab.rb with the user-entered domain
sudo sed -i "s|external_url 'http[s]*://.*'|external_url 'http://$domain'|g" /etc/gitlab/gitlab.rb

# Section 6: Reconfigure GitLab
echo_message "Reconfiguring GitLab to apply the new DNS settings."
sudo gitlab-ctl reconfigure

# Section 7: Final message
echo_message "GitLab is now configured with the domain $domain."
echo "You can access GitLab via: http://$domain"

# End of script

