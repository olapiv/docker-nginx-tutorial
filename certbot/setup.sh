#!/bin/bash

# Original script: https://raw.githubusercontent.com/wmnnd/nginx-certbot/master/init-letsencrypt.sh

if [ -z "${DEV}" ]; then
    echo "Environmental variables are missing!"
    exit 1
fi

domains=(your_domain.com www.your_domain.com)
rsa_key_size=4096
conf_path="/etc/letsencrypt"
www_path="/var/www/certbot"
email="my_email@icloud.com"

mkdir -p "$conf_path/live"
domain_path="$conf_path/live/$domains"
mkdir -p "$domain_path"

if [ ! -f "$conf_path/options-ssl-nginx.conf" ] || [ ! -f "$conf_path/ssl-dhparams.pem" ]; then
    echo "### Downloading recommended TLS parameters ..."
    curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "$conf_path/options-ssl-nginx.conf"
    curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "$conf_path/ssl-dhparams.pem"
fi

# Existing data found for $domains. Continuing replaces existing certificate.
if [ ! -z "$(ls -A $domain_path)" ]; then
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

echo "### Requesting Let's Encrypt certificate for $domains ..."
domain_args=""  # --> "-d your_domain.com -d www.your_domain.com"
for domain in "${domains[@]}"; do
  domain_args="$domain_args -d $domain"
done

# Select appropriate email arg
case "$SSL_EMAIL" in
  "") email_arg="--register-unsafely-without-email" ;;
  *) email_arg="--email $SSL_EMAIL" ;;
esac

certbot certonly --webroot -w $www_path \
    $email_arg \
    $domain_args \
    --rsa-key-size $rsa_key_size \
    --agree-tos \
    --force-renewal

trap exit TERM; while :; do certbot renew; sleep 12h & wait $!; done;