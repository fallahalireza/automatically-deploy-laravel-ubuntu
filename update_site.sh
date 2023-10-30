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
display_info() {
    print_style "$1" "info"
    echo
}
display_gray() {
    print_style "$1" "gray"
}
git_clone() {
    cd /root/laradock || exit
    local link="$1"
    local name="$2""_clone"
    local token="$3"
    local full_link="$link"
    if [ -n "$token" ]; then
        full_link="${link:0:8}$token@${link:8}"
    fi
    display_info "The full Git link is: $full_link"
    docker-compose exec workspace git clone $full_link $name || display_error "Failed to clone the Git repository. ($full_link)"
    display_success "Your custom project has been successfully copied to the server"
    docker-compose exec workspace bash -c "cp $2/.env $name/"
    docker-compose exec workspace bash -c "rm -rf $2"
    docker-compose exec workspace bash -c "mv $name $2"
}

set_permissions_and_restart_nginx() {
    cd /root/laradock || exit
    docker-compose exec workspace chmod -R 777 "$1/storage"
    display_success "Access permissions for the $1/storage folder have been successfully set to 777"
    docker-compose restart nginx
    display_success "Nginx has been successfully restarted"
}
run_migrate() {
    cd /root/laradock || exit
    docker-compose exec workspace bash -c "cd $1 && php artisan migrate"
    display_success "Your database tables have been created successfully"
}

echo "test 6"

cd /root/laradock || exit
display_gray "Choose a name for your Laravel project: "; read  name_laravel
display_gray "Please enter the URL of your Laravel project's Git repository (https://github.com/...): "; read link_git
display_gray "Is your Git project private? If so, enter your access token. Otherwise, press Enter: "; read token_git
git_clone "$link_git" "$name_laravel" "$token_git"
docker-compose exec workspace bash -c "cd $name_laravel && composer install"
display_success "composer install successfully"
set_permissions_and_restart_nginx "$name_laravel"
display_gray "Do you want to create your own database tables? (yes/no):"; read ask_migrate
if [ "$ask_migrate" == "yes" ]; then
  run_migrate "$name_laravel"
fi

