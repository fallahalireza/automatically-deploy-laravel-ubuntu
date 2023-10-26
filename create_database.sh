#!/bin/bash

#set -e

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
check_database_existence() {
  local database_name="$1"
  local MYSQL_ROOT_PASSWORD="$2"
  local sql_query="SHOW DATABASES LIKE '$database_name';"
  local result=$(docker-compose exec mysql mysql -uroot -p$MYSQL_ROOT_PASSWORD -se "$sql_query")

  if [ "$result" = "$database_name" ]; then
    echo "Database '$database_name' already exists."
    return 0
  else
    echo "Database '$database_name' does not exist."
    return 1
  fi
}
check_user_existence() {
  local username="$1"
  local MYSQL_ROOT_PASSWORD="$2"
  local sql_query="SHOW GRANTS FOR '$username'@'%';"
  local result=$(docker-compose exec mysql mysql -uroot -p$MYSQL_ROOT_PASSWORD -se "$sql_query")

  if [[ "$result" == *"GRANT USAGE ON *.* TO '$username'@'%'"* ]]; then
    echo "User '$username' exists."
    return 0
  else
    echo "User '$username' does not exist."
    return 1
  fi
}

cd /root/laradock || exit
export $(cat .env_package | xargs)

display_gray "name database: ";read db_database

if check_database_existence "$db_database" "$MYSQL_ROOT_PASSWORD"; then
  display_error "The database already exists. Please choose a different name."
fi

display_gray "name db user: ";read db_user

if check_user_existence "$db_user" "$MYSQL_ROOT_PASSWORD"; then
  display_success "The user exists."
else
  display_error "The user does not exist."
fi


db_password=$(generate_strong_password 16)

display_warning "Store your database information in a safe place."
display_success "-------------------------------------------------"
display_info "DB Host: mysql"
display_info "Database: $db_database"
display_info "User: $db_user"
display_info "Password: $db_password"
display_success "-------------------------------------------------"
display_gray "Have you saved your database information? (yes/no): ";read save_info_db

if [ "$save_info_db" == "yes" ]; then
  cd /root/laradock
  sql_command1="CREATE DATABASE IF NOT EXISTS $db_database COLLATE utf8mb4_general_ci;"
  sql_command2="CREATE USER '$db_user'@'%' IDENTIFIED WITH mysql_native_password BY '$db_password';GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, FILE, INDEX, ALTER, CREATE TEMPORARY TABLES, CREATE VIEW, EVENT, TRIGGER, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE, EXECUTE ON *.* TO '$db_user'@'%';ALTER USER '$db_user'@'%' REQUIRE NONE WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;"
  sql_command3="GRANT ALL PRIVILEGES ON $db_database.* TO '$db_user'@'%'; ALTER USER '$db_user'@'%' ;"

  docker-compose exec mysql mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "$sql_command1" || display_error "sql_command1"
  docker-compose exec mysql mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "$sql_command2" || display_error "sql_command2"
  docker-compose exec mysql mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "$sql_command3" || display_error "sql_command3"
else
   bash <(curl -Ls https://raw.githubusercontent.com/fallahalireza/automatically-deploy-laravel-ubuntu/main/install.sh)
fi












#-------------------------------------------

# ایجاد تنظیمات محرمانگی در داخل کانتینر MySQL
#docker-compose exec mysql mysql_config_editor set --login-path=local --host=localhost --user=root --password=root

# اجرای دستور SQL برای ایجاد دیتابیس
#docker-compose exec mysql mysql --login-path=local -e "CREATE DATABASE IF NOT EXISTS $db_database COLLATE utf8mb4_general_ci;"


