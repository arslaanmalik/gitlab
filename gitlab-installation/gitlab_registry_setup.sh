#!/bin/bash

set -e  # Exit on any error
trap 'echo "An error occurred. Exiting..."; exit 1;' ERR

GITLAB_CONFIG="/etc/gitlab/gitlab.rb"

# Function to check if a command exists
check_command() {
    if ! command -v "$1" &>/dev/null; then
        echo "Error: $1 is not installed. Please install it and try again."
        exit 1
    fi
}

# Check for required commands
check_command firewall-cmd
check_command grep
check_command sed
check_command gitlab-ctl

# Ask the user for the registry port
while true; do
    read -p "Enter a port number for the GitLab registry (e.g., 5000): " REGISTRY_PORT

    # Validate the entered port
    if ! [[ "$REGISTRY_PORT" =~ ^[0-9]+$ ]] || ((REGISTRY_PORT < 1 || REGISTRY_PORT > 65535)); then
        echo "Error: Invalid port number. Please enter a valid port (1-65535)."
    elif [[ "$REGISTRY_PORT" -eq 5050 ]]; then
        echo "This is the default port for Container Registry via built-in Let's Encrypt. Choose another port."
    else
        break
    fi
done

echo "Selected port: $REGISTRY_PORT"

# Add the port to the firewall and restart the firewall
echo "Adding port $REGISTRY_PORT to the AlmaLinux firewall..."
sudo firewall-cmd --add-port="$REGISTRY_PORT"/tcp --permanent
sudo firewall-cmd --reload
echo "Port $REGISTRY_PORT added to the firewall."

# Extract the external URL from gitlab.rb
if [[ ! -f $GITLAB_CONFIG ]]; then
    echo "Error: GitLab configuration file not found at $GITLAB_CONFIG."
    exit 1
fi

EXTERNAL_URL=$(grep -E "^external_url" "$GITLAB_CONFIG" | sed -E "s/^external_url[[:space:]]+['\"](.*)['\"]/\1/")

if [[ -z "$EXTERNAL_URL" ]]; then
    echo "Error: Could not find an external_url in $GITLAB_CONFIG."
    exit 1
fi

echo "Detected external_url: $EXTERNAL_URL"

# Add registry configuration to gitlab.rb
echo "Updating $GITLAB_CONFIG with registry configuration..."
sudo sed -i "/^external_url/a \
gitlab_rails['registry_enabled'] = true\n\
gitlab_rails['registry_storage_path'] = \"/var/opt/gitlab/gitlab-rails/shared/registry\"\n\
gitlab_rails['registry_external_url'] = '$EXTERNAL_URL:$REGISTRY_PORT'" "$GITLAB_CONFIG"

echo "Configuration added to $GITLAB_CONFIG."

# Reconfigure GitLab
echo "Reconfiguring GitLab..."
sudo gitlab-ctl reconfigure
echo "GitLab reconfiguration completed."

# Display the registry URL to the user
REGISTRY_URL="$EXTERNAL_URL:$REGISTRY_PORT"
echo "GitLab Container Registry is now set up."
echo "Registry URL: $REGISTRY_URL"

