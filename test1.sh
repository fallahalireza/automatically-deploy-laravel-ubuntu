# Define colors for displaying messages
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
ENDCOLOR=$(tput sgr0)

# Function to display an error message and exit
display_error() {
    echo -e "${RED}Error: $1${ENDCOLOR}" >&2
    exit 1
}

# Function to clone a Git repository
git_clone() {
    local link="$1"
    local name="$2"
    local token="$3"
    local full_link="$link"

    if [ -n "$token" ]; then
        full_link="${link:0:8}$token@${link:8}"
    fi

    docker-compose exec workspace git clone $full_link $name || display_error "Failed to clone the Git repository. ($full_link)"
    echo -e "${GREEN}Your custom project has been successfully copied to the server${ENDCOLOR}"
}

# Request user input
read -p "Please enter the desired domain for your site: " domain
read -p "Choose a name for your Laravel project: " name_laravel
read -p "Do you want to install the basic Laravel project or a customized project from a Git repository? (basic/git): " type_project

# Check if the user's choice is valid
if [ "$type_project" != "git" ] && [ "$type_project" != "basic" ]; then
    read -p "Invalid choice. Do you want to try again? (yes/no) " again
    [ "$again" == "yes" ] && bash <(curl -Ls https://raw.githubusercontent.com/fallahalireza/automatically-deploy-laravel-ubuntu/main/install_site.sh)
fi

# Check if the specified domain or project name already exists
if [ -d "/root/laradock/nginx/sites/$domain.conf" ] || [ -d "/root/$name_laravel" ]; then
    [ -d "/root/laradock/nginx/sites/$domain.conf" ] && display_error "This domain is already in use ($domain)"
    [ -d "/root/$name_laravel" ] && display_error "This project name is already in use ($name_laravel)"
    read -p "Do you want to try again? (yes/no) " again
    [ "$again" == "yes" ] && bash <(curl -Ls https://raw.githubusercontent.com/fallahalireza/automatically-deploy-laravel-ubuntu/main/install_site.sh)
fi

# Create the necessary site configuration
cd /root/laradock/nginx/sites
cp laravel.conf.example "$domain.conf"
sed -i "s/server_name laravel.test;/server_name $domain;/" "$domain.conf"
sed -i "s/root \/var\/www\/laravel\/public;/root \/var\/www\/$name_laravel\/public;/" "$domain.conf"
echo -e "${GREEN}The $domain.conf file has been successfully created in /root/laradock/nginx/sites${ENDCOLOR}"
cd /root/laradock

# Handle project installation based on the user's choice
if [ "$type_project" == "basic" ]; then
    docker-compose exec workspace composer create-project laravel/laravel "$name_laravel"
    echo -e "${GREEN}Your Laravel project has been successfully installed${ENDCOLOR}"
    docker-compose exec workspace chmod -R 777 "$name_laravel/storage"
    echo -e "${GREEN}Access permissions for the $name_laravel/storage folder have been successfully set to 777${ENDCOLOR}"
    docker-compose restart nginx
    echo -e "${GREEN}Nginx has been successfully restarted${ENDCOLOR}"
fi

if [ "$type_project" == "git" ]; then
    read -p "Please enter the URL of your Laravel project's Git repository (https://github.com/...): " link_git
    read -p "Is your Git project private? If so, enter your access token. Otherwise, press Enter: " token_git
    git_clone "$link_git" "$name_laravel" "$token_git"

    docker-compose exec workspace bash -c "cd $name_laravel && composer install && cp .env.example .env && php artisan key:generate"
    echo -e "${GREEN}Composer has been successfully run${ENDCOLOR}"
    docker-compose exec workspace chmod -R 777 "$name_laravel/storage"
    echo -e "${GREEN}Access permissions for the $name_laravel/storage folder have been successfully set to 777${ENDCOLOR}"
    docker-compose restart nginx
    echo -e "${GREEN}Nginx has been successfully restarted${ENDCOLOR}"
fi



