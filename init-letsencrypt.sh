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

# Test the HTTP endpoint with verbose output
echo "### Testing HTTP endpoint..."
curl -v http://localhost:80

# Check if nginx is running
echo "### Checking nginx status..."
docker compose ps nginx
docker compose logs nginx

# Request staging certificate
echo "### Requesting staging certificate..."
docker compose run --rm --entrypoint "\
  certbot certonly --webroot -w /var/www/certbot \
  --staging \
  -v \
  --email $email \
  --agree-tos \
  --no-eff-email \
  --force-renewal \
  -d solforge.live -d www.solforge.live" certbot

# Only proceed to production if staging was successful
if [ $? -eq 0 ]; then
  echo "### Requesting production certificate..."
  docker compose run --rm --entrypoint "\
    certbot certonly --webroot -w /var/www/certbot \
    -v \
    --email $email \
    --agree-tos \
    --no-eff-email \
    --force-renewal \
    -d solforge.live -d www.solforge.live" certbot
else
  echo "### Staging certificate request failed. Please fix issues before requesting production certificate."
  exit 1
fi

# Restart nginx
docker compose restart nginx
