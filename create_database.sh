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
#check_database_existence() {
#  local database_name="$1"
#  local MYSQL_ROOT_PASSWORD="$2"
#  local sql_query="SHOW DATABASES LIKE '$database_name';"
#  local result=$(docker-compose exec mysql mysql -uroot -p$MYSQL_ROOT_PASSWORD -se "$sql_query")
#
#  if [ "$result" = "$database_name" ]; then
#    echo "Database '$database_name' already exists."
#    return 0
#  else
#    echo "Database '$database_name' does not exist."
#    return 1
#  fi
#}
check_user_existence() {
  local DESIRED_USERNAME="$1"
  local MYSQL_ROOT_PASSWORD="$2"
  result=$(echo "SELECT user FROM mysql.user WHERE user = '$DESIRED_USERNAME';" | docker-compose exec -T mysql mysql -uroot -p$MYSQL_ROOT_PASSWORD | grep -c .)

  if [ "$result" -gt 0 ]; then
    echo "User '$DESIRED_USERNAME' exists in the database."
    return 1
  else
    echo "User '$DESIRED_USERNAME' does not exist in the database."
    return 0
  fi
}

cd /root/laradock || exit
export $(cat .env_package | xargs)

display_gray "name db user: ";read db_user

if  check_database_existence "$db_user" "$MYSQL_ROOT_PASSWORD" ; then
  display_error "User '$db_user' exists in the database."
else
  display_error "User '$db_user' does not exist in the database."
fi

display_gray "name database: ";read db_database

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
  sql_command="CREATE DATABASE IF NOT EXISTS $db_database COLLATE utf8mb4_general_ci;"
  sql_command+="CREATE USER '$db_user'@'%' IDENTIFIED WITH mysql_native_password BY '$db_password';GRANT USAGE ON *.* TO '$db_user'@'%';ALTER USER '$db_user'@'%' REQUIRE NONE WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;"
  sql_command+="GRANT ALL PRIVILEGES ON $db_database.* TO '$db_user'@'%'; ALTER USER '$db_user'@'%' ;"

  docker-compose exec mysql mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "$sql_command"
  display_success "Database and user created successfully"
else
   bash <(curl -Ls https://raw.githubusercontent.com/fallahalireza/automatically-deploy-laravel-ubuntu/main/install.sh)
fi

#sql_command+="CREATE USER '$db_user'@'%' IDENTIFIED WITH mysql_native_password BY '$db_password';GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, FILE, INDEX, ALTER, CREATE TEMPORARY TABLES, CREATE VIEW, EVENT, TRIGGER, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE, EXECUTE ON *.* TO '$db_user'@'%';ALTER USER '$db_user'@'%' REQUIRE NONE WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;"
