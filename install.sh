#!/bin/bash

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
display_gray() {
    print_style "$1" "gray"
}
display_info() {
    print_style "$1" "info"
    echo
}

print_style "Automatically deploy the Laravel project to the Ubuntu server\n" "purple"

if dpkg -l | grep -q "docker-ce\|docker-ce-cli\|containerd.io\|docker-buildx-plugin\|docker-compose\|docker-compose-plugin"; then
    display_success "Docker packages are installed"
else
    display_info "Installing Docker..."
    bash <(curl -Ls https://raw.githubusercontent.com/fallahalireza/automatically-deploy-laravel-ubuntu/main/install_docker.sh) || display_error "Failed Installing Docker"
    display_success "Installation and setup completed. (Docker)"
fi

if [ -d "/root/laradock" ]; then
    display_success "There is a 'laradock' directory"
else
    display_info "Installing Laradock..."
    bash <(curl -Ls https://raw.githubusercontent.com/fallahalireza/automatically-deploy-laravel-ubuntu/main/install_laradock.sh) || display_error "Failed Installing Laradock"
    display_success "Installation and setup completed. (Laradock)"
fi

cd /root/laradock || exit
docker-compose up -d nginx mysql phpmyadmin workspace
display_success "The containers are now running."


display_gray "Do you want to create a new user and database? (yes/no): ";read start_database
if [ "$start_database" == "yes" ]; then
  display_info "The start of database construction"
  bash <(curl -Ls https://raw.githubusercontent.com/fallahalireza/automatically-deploy-laravel-ubuntu/main/create_database.sh)
fi

display_gray "Do you want to create and set up a new site? (yes/no): ";read start_site
if [ "$start_site" == "yes" ]; then
  display_info "The start of site construction"
  bash <(curl -Ls https://raw.githubusercontent.com/fallahalireza/automatically-deploy-laravel-ubuntu/main/create_site.sh)
fi

display_gray "Do you want to repeat the steps of building the database and site once again? (yes/no): ";read again_script
if [ "$again_script" == "yes" ]; then
  bash <(curl -Ls https://raw.githubusercontent.com/fallahalireza/automatically-deploy-laravel-ubuntu/main/install.sh)
fi

