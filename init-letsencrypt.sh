#!/bin/bash

# Initial setup without SSL
echo "### Setting up initial configuration..."
docker compose down
docker compose up -d

# Wait for services to start
echo "### Waiting for services to start..."
sleep 10

# Test the connection
curl http://167.99.11.192

echo "### Setup complete. Now you need to:"
echo "1. Set up DNS A records for solforge.live and www.solforge.live pointing to 167.99.11.192"
echo "2. Wait for DNS propagation (can take up to 48 hours)"
echo "3. Run: ./init-letsencrypt.sh --with-ssl once DNS is ready"

# Only proceed with SSL if --with-ssl flag is provided
if [ "$1" = "--with-ssl" ]; then
    domains=(solforge.live www.solforge.live)
    rsa_key_size=4096
    data_path="./certbot"
    email="zacharyrcherny@gmail.com"

    if [ -d "$data_path" ]; then
      read -p "Existing data found for $domains. Continue and replace existing certificate? (y/N) " decision
      if [ "$decision" != "Y" ] && [ "$decision" != "y" ]; then
        exit
      fi
    fi

    if [ ! -e "$data_path/conf/options-ssl-nginx.conf" ] || [ ! -e "$data_path/conf/ssl-dhparams.pem" ]; then
      echo "### Downloading recommended TLS parameters ..."
      mkdir -p "$data_path/conf"
      curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "$data_path/conf/options-ssl-nginx.conf"
      curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "$data_path/conf/ssl-dhparams.pem"
      echo
    fi

    echo "### Creating dummy certificate for $domains ..."
    path="/etc/letsencrypt/live/$domains"
    mkdir -p "$data_path/conf/live/$domains"
    docker compose run --rm --entrypoint "\
      openssl req -x509 -nodes -newkey rsa:$rsa_key_size -days 1\
        -keyout '$path/privkey.pem' \
        -out '$path/fullchain.pem' \
        -subj '/CN=localhost'" certbot
    echo

    echo "### Starting nginx ..."
    docker compose up --force-recreate -d nginx
    echo

    echo "### Deleting dummy certificate for $domains ..."
    docker compose run --rm --entrypoint "\
      rm -Rf /etc/letsencrypt/live/$domains && \
      rm -Rf /etc/letsencrypt/archive/$domains && \
      rm -Rf /etc/letsencrypt/renewal/$domains.conf" certbot
    echo

    echo "### Requesting Let's Encrypt certificate for $domains ..."
    domain_args=""
    for domain in "${domains[@]}"; do
      domain_args="$domain_args -d $domain"
    done

    docker compose run --rm --entrypoint "\
      certbot certonly --webroot -w /var/www/certbot \
        $domain_args \
        --email $email \
        --rsa-key-size $rsa_key_size \
        --agree-tos \
        --force-renewal" certbot
    echo

    echo "### Reloading nginx ..."
    docker compose exec nginx nginx -s reload
fi
