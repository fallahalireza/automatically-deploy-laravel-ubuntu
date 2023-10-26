#!/bin/bash

cd /root/laradock || exit
export $(cat .env_package | xargs)

echo "name db user: ";read DESIRED_USERNAME

result=$(echo "SELECT user FROM mysql.user WHERE user = '$DESIRED_USERNAME';" | docker-compose exec -T mysql mysql -uroot | grep -c .)


if [ "$result" -gt 0 ]; then
  echo "User '$DESIRED_USERNAME' exists in the database."
else
  echo "User '$DESIRED_USERNAME' does not exist in the database."
fi

echo "test 9"

#result=$(echo "SELECT user FROM mysql.user WHERE user = '$DESIRED_USERNAME';" | docker-compose exec -T mysql mysql -uroot -p$MYSQL_ROOT_PASSWORD | grep -c .)

