#!/bin/bash

echo "test 4"
echo "Enter email: ";read ssl_email
echo "Enter the domain: ";read ssl_domain
cd /root/laradock || exit


docker-compose exec nginx apk add --no-cache certbot certbot-nginx
echo "1" | docker-compose exec nginx certbot certonly --email $ssl_email --no-eff-email -d $ssl_domain -d www.$ssl_domain


