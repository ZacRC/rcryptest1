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

# Start nginx with HTTP only
docker compose up -d nginx
docker compose up -d web

# Wait longer for services to start
echo "### Waiting for services to start..."
sleep 45

# Test the HTTP endpoint
echo "### Testing HTTP endpoint..."
curl -I http://localhost:80

# Request staging certificate
echo "### Requesting staging certificate..."
docker compose run --rm --entrypoint "\
  certbot certonly --webroot -w /var/www/certbot \
  --staging \
  --email $email \
  --agree-tos \
  --no-eff-email \
  --force-renewal \
  -d solforge.live -d www.solforge.live" certbot

# Request real certificate
echo "### Requesting production certificate..."
docker compose run --rm --entrypoint "\
  certbot certonly --webroot -w /var/www/certbot \
  --email $email \
  --agree-tos \
  --no-eff-email \
  --force-renewal \
  -d solforge.live -d www.solforge.live" certbot

# Restart nginx
docker compose restart nginx
