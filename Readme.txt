Run in following order:

1) gitlab_installation.sh
2) gitlab_dns.sh
3) https_config.sh
4) gitlab_registry_setup.sh


To gernate run the generate-ssl.sh

then update the rb file with
-----
#external_url 'https://0.1.1.109/'
external_url 'https://gitlab.com/'
nginx['ssl_certificate'] = "/etc/gitlab/ssl/gitlab.com.crt"
nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/gitlab.com.key"
nginx['redirect_http_to_https'] = true


#### FOR REGISTRY SETUP
gitlab_rails['registry_enabled'] = true
gitlab_rails['registry_storage_path'] = "/var/opt/gitlab/gitlab-rails/shared/registry"
gitlab_rails['registry_external_url'] = 'http://0.1.1.109:5000'

//////////////////////

To Setup the Runner 
mkdir /etc/gitlab-runner/certs

Then Copy the Certs directly from the Server

Now Copy the Certificates from the Instance
openssl s_client -showcerts -connect gitlab.com:443 -servername gitlab.com < /dev/null 2>/dev/null | openssl x509 -outform PEM > /etc/gitlab-runner/certs/gitlab.com.crt


Test the Cert

echo | openssl s_client -CAfile /etc/gitlab-runner/certs/gitlab.com.crt -connect gitlab.com:443 -servername gitlab.com

///////////////////////////////

Now Join the Runner 
gitlab-runner register  --url https://gitlab.com  --token xxxxxxxx --tls-ca-file=/etc/gitlab-runner/certs/.gitlab.com.crt
