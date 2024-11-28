#!/bin/bash

domains=(solforge.live www.solforge.live)
rsa_key_size=4096
data_path="./certbot"
email="zacharyrcherny@gmail.com"

# Stop existing containers and clean up
docker compose down
rm -rf "$data_path"

# Create required directories
mkdir -p "$data_path/conf/live/solforge.live"
mkdir -p "$data_path/www"

# Download TLS parameters
echo "### Downloading recommended TLS parameters ..."
curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "$data_path/conf/options-ssl-nginx.conf"
curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "$data_path/conf/ssl-dhparams.pem"

# Start services
echo "### Starting services ..."
docker compose up -d

# Wait for services to start
echo "### Waiting for services to start ..."
sleep 30

# Request certificate
echo "### Requesting Let's Encrypt certificate ..."
docker compose run --rm --entrypoint "\
    certbot certonly --webroot -w /var/www/certbot \
    --email $email \
    --rsa-key-size $rsa_key_size \
    --agree-tos \
    --force-renewal \
    --non-interactive \
    -d solforge.live -d www.solforge.live \
    --staging" certbot

# If staging was successful, get real certificate
if [ $? -eq 0 ]; then
    echo "### Staging successful, getting real certificate ..."
    docker compose run --rm --entrypoint "\
        certbot certonly --webroot -w /var/www/certbot \
        --email $email \
        --rsa-key-size $rsa_key_size \
        --agree-tos \
        --force-renewal \
        --non-interactive \
        -d solforge.live -d www.solforge.live" certbot
fi

# Reload nginx
echo "### Reloading nginx ..."
docker compose exec nginx nginx -s reload
