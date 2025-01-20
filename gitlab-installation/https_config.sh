#!/bin/bash

set -e  # Exit immediately on error
trap 'echo "An error occurred. Exiting..."; exit 1;' ERR

# GitLab SSL Directory and gitlab.rb file path
GITLAB_SSL_DIR="/etc/gitlab/ssl"
GITLAB_CONFIG="/etc/gitlab/gitlab.rb"

# Extract external_url from gitlab.rb
if [[ ! -f $GITLAB_CONFIG ]]; then
    echo "Error: GitLab configuration file not found at $GITLAB_CONFIG."
    exit 1
fi

DNS_NAME=$(grep -E "^external_url" "$GITLAB_CONFIG" | sed -E "s/^external_url[[:space:]]+['\"](.*)['\"]/\1/" | sed -E "s~https?://~~")

if [[ -z $DNS_NAME ]]; then
    echo "Error: Could not find a valid external_url in $GITLAB_CONFIG."
    exit 1
fi

echo "Detected external_url: $DNS_NAME"

# Ensure SSL directory exists
if [[ ! -d $GITLAB_SSL_DIR ]]; then
    echo "Creating GitLab SSL directory at $GITLAB_SSL_DIR..."
    sudo mkdir -p $GITLAB_SSL_DIR
    sudo chmod 700 $GITLAB_SSL_DIR
fi

echo "Do you want to:
1) Generate New Certificates 
2) Use Existing Certificates 
3) Use Certificates Already in Default GitLab SSL Directory ($GITLAB_SSL_DIR)?"
read -p "Enter 1, 2, or 3: " choice

case $choice in
1)
    echo "Generating new certificates..."
    CRT_PATH="$GITLAB_SSL_DIR/$DNS_NAME.crt"
    KEY_PATH="$GITLAB_SSL_DIR/$DNS_NAME.key"

    # Generate new certificate and key
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$KEY_PATH" \
        -out "$CRT_PATH" \
        -subj "/CN=$DNS_NAME"

    sudo chmod 600 "$CRT_PATH" "$KEY_PATH"
    echo "New certificates generated."

    # Copy the newly generated certificates to the GitLab SSL directory
    sudo cp "$CRT_PATH" "$GITLAB_SSL_DIR/"
    sudo cp "$KEY_PATH" "$GITLAB_SSL_DIR/"
    echo "New certificates copied to $GITLAB_SSL_DIR."

    CERT_STATUS="newly generated certificates"
    ;;
2)
    read -p "Enter the full path to your certificate file: " user_crt
    read -p "Enter the full path to your key file: " user_key

    # Validate paths
    if [[ ! -f $user_crt ]]; then
        echo "Error: Certificate file not found at $user_crt."
        exit 1
    fi

    if [[ ! -f $user_key ]]; then
        echo "Error: Key file not found at $user_key."
        exit 1
    fi

    # Copy the certificates
    sudo cp "$user_crt" "$GITLAB_SSL_DIR/$DNS_NAME.crt"
    sudo cp "$user_key" "$GITLAB_SSL_DIR/$DNS_NAME.key"
    sudo chmod 600 "$GITLAB_SSL_DIR/$DNS_NAME.crt" "$GITLAB_SSL_DIR/$DNS_NAME.key"
    echo "Certificates copied to $GITLAB_SSL_DIR."
    CERT_STATUS="existing certificates"
    ;;
3)
    CRT_PATH="$GITLAB_SSL_DIR/$DNS_NAME.crt"
    KEY_PATH="$GITLAB_SSL_DIR/$DNS_NAME.key"

    if [[ ! -f $CRT_PATH || ! -f $KEY_PATH ]]; then
        echo "Error: Certificates not found in $GITLAB_SSL_DIR for DNS: $DNS_NAME."
        exit 1
    fi

    echo "Using certificates already in $GITLAB_SSL_DIR."
    CERT_STATUS="default SSL directory certificates"
    ;;
*)
    echo "Invalid choice. Exiting..."
    exit 1
    ;;
esac

# Update gitlab.rb with SSL certificate paths
echo "Updating $GITLAB_CONFIG..."
sudo sed -i "/^external_url/a \
nginx['ssl_certificate'] = \"$GITLAB_SSL_DIR/$DNS_NAME.crt\"\\
nginx['ssl_certificate_key'] = \"$GITLAB_SSL_DIR/$DNS_NAME.key\"\\
nginx['redirect_http_to_https'] = true" $GITLAB_CONFIG

# Replace http with https in external_url (this step is done last)
echo "Replacing http with https in external_url..."
sudo sed -i "s|^external_url[[:space:]]\+['\"]http://|external_url 'https://|" "$GITLAB_CONFIG"
echo "external_url updated to use https."

# Reconfigure GitLab
echo "Reconfiguring GitLab..."
sudo gitlab-ctl reconfigure

# Success message
echo "HTTPS has been configured with $CERT_STATUS."
echo "Access GitLab via: https://$DNS_NAME"

