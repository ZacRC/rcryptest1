#!/bin/bash

domains=(solforge.live www.solforge.live)
rsa_key_size=4096
data_path="./certbot"
email="zacharyrcherny@gmail.com"

# Stop and remove everything
docker compose down -v
rm -rf "$data_path"

# Create directories
mkdir -p "$data_path/conf/live/solforge.live"
mkdir -p "$data_path/www"

# Start nginx without SSL
docker compose up -d nginx

# Wait for nginx
echo "### Waiting for nginx to start..."
sleep 10

# Request staging certificate
echo "### Requesting staging certificate..."
docker compose run --rm --entrypoint "\
  certbot certonly --webroot -w /var/www/certbot \
  --staging \
  --email $email \
  --agree-tos \
  --no-eff-email \
  -d solforge.live -d www.solforge.live" certbot

# Request real certificate
echo "### Requesting production certificate..."
docker compose run --rm --entrypoint "\
  certbot certonly --webroot -w /var/www/certbot \
  --email $email \
  --agree-tos \
  --no-eff-email \
  -d solforge.live -d www.solforge.live" certbot

# Restart nginx
docker compose restart nginx
