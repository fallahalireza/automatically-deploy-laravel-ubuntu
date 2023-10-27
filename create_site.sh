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
    local link="$1"
    local name="$2"
    local token="$3"
    local full_link="$link"
    if [ -n "$token" ]; then
        full_link="${link:0:8}$token@${link:8}"
    fi
    display_info "The full Git link is: $full_link"
    docker-compose exec workspace git clone $full_link $name || display_error "Failed to clone the Git repository. ($full_link)"
    display_success "Your custom project has been successfully copied to the server"
}
set_permissions_and_restart_nginx() {
    cd /root/laradock || exit
    docker-compose exec workspace chmod -R 777 "$1/storage"
    display_success "Access permissions for the $1/storage folder have been successfully set to 777"
    docker-compose restart nginx
    display_success "Nginx has been successfully restarted"
}
ask_to_try_again() {
    display_gray "Invalid choice. Do you want to try again? (yes/no): "; read again
    if [ "$again" == "yes" ]; then
        bash <(curl -Ls https://raw.githubusercontent.com/fallahalireza/automatically-deploy-laravel-ubuntu/main/install_site.sh)
    fi
}
create_laravel_config_nginx() {
    cd /root/laradock/nginx/sites || exit
    cp laravel.conf.example "$1.conf"
    sed -i "s/server_name laravel.test;/server_name $1;/" "$1.conf"
    sed -i "s/root \/var\/www\/laravel\/public;/root \/var\/www\/$2\/public;/" "$1.conf"
    display_success "The $1.conf file has been successfully created in /root/laradock/nginx/sites"
}
set_database() {
    cd /root/sites/$1 || exit
    sed -i "s/DB_HOST=127.0.0.1/DB_HOST=mysql/" ".env"
    sed -i "s/DB_DATABASE=laravel/DB_DATABASE=$2/" ".env"
    sed -i "s/DB_USERNAME=root/DB_USERNAME=$3/" ".env"
    sed -i "s/DB_PASSWORD=/DB_PASSWORD=$4/" ".env"
    display_success "Your site's database has been set up successfully"
}
run_migrate() {
    cd /root/laradock || exit
    docker-compose exec workspace bash -c "cd $1 && php artisan migrate"
    display_success "Your database tables have been created successfully"
}

display_gray "Please enter the desired domain for your site: "; read domain
display_gray "Choose a name for your Laravel project: "; read  name_laravel

print_style "(optional) " "warning"
display_gray "Your database name: "; read  database_name
print_style "(optional) " "warning"
display_gray "Your database username: "; read  database_username
print_style "(optional) " "warning"
display_gray "Your database user password: "; read  database_password

display_gray "Do you want to install the basic Laravel project or a customized project from a Git repository? (basic/git): "; read  type_project


if [ "$type_project" == "git" ] || [ "$type_project" == "basic" ]; then
    if [ -d "/root/laradock/nginx/sites/$domain.conf" ] || [ -d "/root/$name_laravel" ]; then
        if [ -d "/root/laradock/nginx/sites/$domain.conf" ]; then
            display_error "This domain is already used ($domain)"
        fi
        if [ -d "/root/$name_laravel" ]; then
          display_error "This project name is already used ($name_laravel)"
        fi
        ask_to_try_again
    else
        cd /root/laradock || exit
        if [ "$type_project" == "basic" ]; then
          docker-compose exec workspace composer create-project laravel/laravel "$name_laravel"
          display_success "Your Laravel project has been successfully installed"
          set_database "$name_laravel" "$database_name" "$database_username" "$database_password"
          create_laravel_config_nginx "$domain" "$name_laravel"
          set_permissions_and_restart_nginx "$name_laravel"
          display_gray "Do you want to create your own database tables? (yes/no):"; read ask_migrate
          if [ "$ask_migrate" == "yes" ]; then
            run_migrate "$name_laravel"
          fi
        fi

        if [ "$type_project" == "git" ]; then
          display_gray "Please enter the URL of your Laravel project's Git repository (https://github.com/...): "; read link_git
          display_gray "Is your Git project private? If so, enter your access token. Otherwise, press Enter: "; read token_git
          git_clone "$link_git" "$name_laravel" "$token_git"
          docker-compose exec workspace bash -c "cd $name_laravel && composer install && cp .env.example .env && php artisan key:generate"
          display_success "composer install successfully"
          set_database "$name_laravel" "$database_name" "$database_username" "$database_password"
          create_laravel_config_nginx "$domain" "$name_laravel"
          set_permissions_and_restart_nginx "$name_laravel"
          display_gray "Do you want to create your own database tables? (yes/no):"; read ask_migrate
          if [ "$ask_migrate" == "yes" ]; then
            run_migrate "$name_laravel"
          fi
        fi
    fi
else
	  ask_to_try_again
fi
