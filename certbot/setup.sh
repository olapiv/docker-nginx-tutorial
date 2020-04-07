#!/bin/bash

# Original script: https://raw.githubusercontent.com/wmnnd/nginx-certbot/master/init-letsencrypt.sh

domains=(hello_django.de www.hello_django.de)
rsa_key_size=4096
conf_path="/etc/letsencrypt"
www_path="/var/www/certbot"
email="my_email@icloud.com"

domain_path="$conf_path/live/$domains"
mkdir -p "$domain_path"

if [ ! -f "$conf_path/options-ssl-nginx.conf" ] || [ ! -f "$conf_path/ssl-dhparams.pem" ]; then
    echo "### Downloading recommended TLS parameters ..."
    curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "$conf_path/options-ssl-nginx.conf"
    curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "$conf_path/ssl-dhparams.pem"
fi

# Existing data found for $domains. Continuing replaces existing certificate.
if [ -d "$domain_path" ]; then
    echo "### Existing data found for $domains. Not replacing certificates."
    trap exit TERM; while :; do certbot renew; sleep 12h & wait $!; done;
fi

if [ $DEV == true ]; then
    echo "### Creating dummy certificate for $domains ..."
    openssl req -x509 -nodes -newkey rsa:1024 -days 1\
        -keyout "$domain_path/privkey.pem" \
        -out "$domain_path/fullchain.pem" \
        -subj "/CN=localhost"

    trap exit TERM; while :; do certbot renew; sleep 12h & wait $!; done;
fi

# echo "### Deleting dummy certificate for $domains ..."
# rm -Rf /etc/letsencrypt/live/$domains && \
#     rm -Rf /etc/letsencrypt/archive/$domains && \
#     rm -Rf /etc/letsencrypt/renewal/$domains.conf

echo "### Requesting Let's Encrypt certificate for $domains ..."
domain_args=""
for domain in "${domains[@]}"; do
  domain_args="$domain_args -d $domain"
done

# Select appropriate email arg
case "$email" in
  "") email_arg="--register-unsafely-without-email" ;;
  *) email_arg="--email $email" ;;
esac

# Enable staging mode if needed
if [ $DEV == true ]; then staging_arg="--staging"; fi

certbot certonly --webroot -w $www_path \
    $staging_arg \
    $email_arg \
    $domain_args \
    --rsa-key-size $rsa_key_size \
    --agree-tos \
    --force-renewal

trap exit TERM; while :; do certbot renew; sleep 12h & wait $!; done;