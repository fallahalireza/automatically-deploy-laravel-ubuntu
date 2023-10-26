#!/bin/bash

cd /root/laradock || exit
export $(cat .env_package | xargs)

echo "name db user: ";read DESIRED_USERNAME


# Execute a query to check the existence of the user
result=$(docker-compose exec mysql mysql -uroot -p$MYSQL_ROOT_PASSWORD -se "SELECT COUNT(*) FROM mysql.user WHERE user = '$DESIRED_USERNAME'")

if [ "$result" -gt 0 ]; then
  echo "User '$DESIRED_USERNAME' exists in the database."
else
  echo "User '$DESIRED_USERNAME' does not exist in the database."
fi




