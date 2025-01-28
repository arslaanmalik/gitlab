echo "Generating the SSL"
sudo openssl genrsa -out ca.key 2048
sudo openssl req -new -x509 -days 365 -key ca.key -subj "/C=SA/ST=Riyadh/L=Riyadh/O=MIM/CN=dev.gitlab.com Root CA" -out ca.crt
sudo openssl req -newkey rsa:2048 -nodes -keyout dev.gitlab.com.key -subj "/C=SA/ST=Riyadh/L=Riyadh/O=MIM/CN=dev.gitlab.com" -out dev.gitlab.com.csr
sudo su -c "openssl x509 -req -extfile <(printf "subjectAltName=DNS:dev.gitlab.com") -days 365 -in dev.gitlab.com.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out dev.gitlab.com.crt"