#!/bin/bash

set -e

print_style () {
    local message="$1"
    local color_code="$2"

    case "$color_code" in
        "info") COLOR="96m" ;;
        "success") COLOR="92m" ;;
        "warning") COLOR="93m" ;;
        "danger") COLOR="91m" ;;
        "blue") COLOR="94m" ;;
        "purple") COLOR="95m" ;;
        "gray") COLOR="37m" ;;
        *) COLOR="0m" ;; # Default color
    esac

    STARTCOLOR="\e[$COLOR"
    ENDCOLOR="\e[0m"

    printf "$STARTCOLOR%b$ENDCOLOR" "$message"
}
display_error() {
    print_style "Error: $1" "danger" >&2
    echo
    exit 1
}
display_success() {
    print_style "$1" "success"
    echo
}
display_info() {
    print_style "$1" "info"
    echo
}
display_warning() {
    print_style "$1" "warning"
    echo
}
display_gray() {
    print_style "$1" "gray"
}
generate_strong_password() {
    local length="$1"
    local characters='A-Za-z0-9@#$)(&^'
    local password=$(tr -dc "$characters" < /dev/urandom | head -c"$length")
    echo "$password"
}

my_ipv4=$(ip addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
generated_password_default=$(generate_strong_password 16)
generated_password_root=$(generate_strong_password 16)
display_warning "Store your database information in a safe place."
display_success "-------------------------------------------------"
display_info "phpmyadmin link: $my_ipv4:8081"
display_info "DB Host: mysql"
display_success "-------------------------------------------------"
display_info "User Root: root"
display_info "Password Root: $generated_password_root"
display_success "-------------------------------------------------"
display_info "User Default: default"
display_info "Password Default: $generated_password_default"
display_success "-------------------------------------------------"
display_gray "Have you saved your database information? (yes/no): ";read save_info_db
if [ "$save_info_db" == "yes" ]; then
  display_gray "Select a PHP version of the Workspace and PHP-FPM containers? (Accepted values: 8.2 - 8.1 - 8.0 - 7.4 - 7.3 - 7.2 - 7.1 - 7.0 - 5.6): ";read php_version
  cd /root
  git clone https://github.com/Laradock/laradock.git
  cd /root/laradock
  cp .env.example .env
  sed -i "s/PHP_VERSION=.*/PHP_VERSION=$php_version/g" .env
  sed -i 's/APP_CODE_PATH_HOST=..\/$/APP_CODE_PATH_HOST=..\/sites\//' .env
  sed -i "s/MYSQL_PASSWORD=secret/MYSQL_PASSWORD=$generated_password_default/g" .env
  sed -i "s/MYSQL_ROOT_PASSWORD=root/MYSQL_ROOT_PASSWORD=$generated_password_root/g" .env
  echo "MYSQL_ROOT_DEFAULT=$generated_password_root" >> .env_package
  echo "MYSQL_ROOT_PASSWORD=$generated_password_root" >> .env_package
  display_info "Note the root password of your database: $generated_password_root"
  display_warning "The database root password is no longer displayed"
  docker-compose up -d nginx mysql phpmyadmin workspace
else
   bash <(curl -Ls https://raw.githubusercontent.com/fallahalireza/automatically-deploy-laravel-ubuntu/main/install.sh)
fi










