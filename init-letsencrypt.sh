#!/bin/bash

domains=(solforge.live www.solforge.live)
rsa_key_size=4096
data_path="./certbot"
email="zacharyrcherny@gmail.com"

# Stop existing containers
docker compose down

# Create required directories
mkdir -p "$data_path/conf/live/solforge.live"
mkdir -p "$data_path/www"

if [ ! -e "$data_path/conf/options-ssl-nginx.conf" ] || [ ! -e "$data_path/conf/ssl-dhparams.pem" ]; then
    echo "### Downloading recommended TLS parameters ..."
    curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "$data_path/conf/options-ssl-nginx.conf"
    curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "$data_path/conf/ssl-dhparams.pem"
fi

# Create dummy certificate
echo "### Creating dummy certificate ..."
openssl req -x509 -nodes -newkey rsa:$rsa_key_size -days 1 \
    -keyout "$data_path/conf/live/solforge.live/privkey.pem" \
    -out "$data_path/conf/live/solforge.live/fullchain.pem" \
    -subj '/CN=localhost'

# Start nginx
echo "### Starting nginx ..."
docker compose up -d nginx

# Wait for nginx to start
echo "### Waiting for nginx to start ..."
sleep 10

# Request Let's Encrypt certificate
echo "### Requesting Let's Encrypt certificate ..."
docker compose run --rm --entrypoint "\
    certbot certonly --webroot -w /var/www/certbot \
    --email $email \
    --rsa-key-size $rsa_key_size \
    --agree-tos \
    --force-renewal \
    --non-interactive \
    -d solforge.live -d www.solforge.live" certbot

# Reload nginx
echo "### Reloading nginx ..."
docker compose exec nginx nginx -s reload
