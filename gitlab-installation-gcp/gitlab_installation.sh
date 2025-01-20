#!/bin/bash

# Section 1: Update system packages and install necessary tools
# echo "Updating system packages and installing essential tools..."
# sudo dnf install -y curl policycoreutils openssh-server perl
# echo "Installed curl, policycoreutils, openssh-server, and perl."

sudo apt-get update
sudo apt-get install -y curl openssh-server ca-certificates tzdata perl

# Section 4: Install and start the Postfix mail server
echo "Installing the Postfix mail server..."
sudo apt-get install -y postfix
echo "Postfix installation completed."

echo "Enabling and starting the Postfix service..."
sudo systemctl status postfix
echo "Postfix service is already enabled and started."

# Section 5: Add GitLab repository and install GitLab EE
echo "Adding GitLab repository to your system..."
curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh | sudo bash
echo "GitLab repository added successfully."

echo "Installing GitLab Enterprise Edition (EE)..."
sudo apt-get install -y gitlab-ee
#OR
#sudo apt-get install gitlab-ee=16.2.3-ee.0
echo "GitLab EE installed successfully."



#We need to add the external IP Address of the VM assigned asking from user

echo gitlab-external-ip 

# Section 6: Function to edit the GitLab configuration file using sed it will replace the external_url with the static ip you shared of GCP

#######TEST BELOW##############
sudo sed -i 's/^external_url 'https://www.gitlab.com';/external_url 'http"$external_url"';/' /etc/gitlab/gitlab.rb


# Section 8: Reconfigure GitLab to apply changes
echo "Reconfiguring GitLab to apply the new settings..."
sudo gitlab-ctl reconfigure

echo "You didn't opt-in to print initial root password "
 sudo cat /etc/gitlab/initial_root_password

# Section 9: Final message
echo "Reconfiguration completed. GitLab is now set up with the new external URL."
echo "Access your GitLab instance via the configured external URL."

