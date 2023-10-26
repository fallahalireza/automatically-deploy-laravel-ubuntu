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