#!/bin/bash

display_gray "Enter email: ";read ssl_email
display_gray "Enter the domain: ";read ssl_domain
docker-compose exec nginx apk add certbot certbot-nginx
docker-compose exec nginx certbot certonly --email $ssl_email --no-eff-email -d $ssl_domain -d www.$ssl_domain

