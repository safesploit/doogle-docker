#!/bin/bash

# Define ANSI escape codes for color formatting globally
# GREEN='\e[32m'
# RED='\e[31m'
# RESET='\e[0m'

# macOS
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
RESET=$(tput sgr0)

# Function to generate a random password
generate_password() {
  local length="$1"
  local characters="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
  local password=""

  # Set default password length if not provided
  if [ -z "$length" ]; then
    length=12
  fi

  for i in $(seq 1 "$length"); do
    random_char="${characters:RANDOM % ${#characters}:1}"
    password="${password}${random_char}"
  done

  echo "$password"
}

# Function to load environment variables from .env file
load_env() {
  local filename="$1"
  local script_dir="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
  local env_file="${script_dir}/$filename"

  if [ -f "$env_file" ]; then
    source "$env_file"
  else
    echo "${RED}Error${RESET}: The .env file is missing. Please create it and define the required environment variables."
    exit 1
  fi
}

# Function to clone the PHP application repository
clone_app_repo() {
  local repo_url="$1"
  local target_dir="src"

  if [ -d "$target_dir" ]; then
    echo "Directory '$target_dir' already exists. Skipping clone operation."
  else
    git clone "$repo_url" "$target_dir" || { 
      echo "${RED}Error${RESET}: Cloning the repository failed."; exit 1; 
      }
  fi
}

update_config_php() {
  local filename="$1"
  local target_dir="src"
  local config_php_file="${target_dir}/${filename}"

  if [ -f "$config_php_file" ]; then
    sed -i -e "s/\(\$dbname =\) \".*\";/\1 \"\${MYSQL_DB_NAME}\";/" "$config_php_file"
    sed -i -e "s/\(\$dbhost =\) \".*\";/\1 \"\${MYSQL_DB_HOST}\";/" "$config_php_file"
    sed -i -e "s/\(\$dbuser =\) \".*\";/\1 \"\${MYSQL_DB_USER}\";/" "$config_php_file"
    sed -i -e "s/\(\$dbpass =\) \".*\";/\1 \"\${MYSQL_DB_PASSWORD}\";/" "$config_php_file"
    
    echo "${GREEN}Updated${RESET} $config_php_file with environment variable references."
  else
    echo "${RED}Error${RESET}: $config_php_file not found. Please check your repository structure."
    exit 1
  fi
}

update_create_user_sql() {
  local filename="$1"
  local sql_file="config/${filename}"
  local mysql_db_password="$MYSQL_DB_PASSWORD"

  if [ -f "$sql_file" ]; then
    sed -i -e "s#IDENTIFIED BY '[^']*'#IDENTIFIED BY '$mysql_db_password'#g" "$sql_file" || {
      echo "Error: Failed to update the MySQL user password in the SQL script."
      exit 1
    }
    echo "${GREEN}Updated${RESET} $sql_file with environment variable references."
  else
    echo "Error: $sql_file not found. Please check your repository structure."
    exit 1
  fi
}

# Updates the e.nv password for database root user
update_mysql_root_password_env() {
  local new_mysql_root_password="$1"
  local env_file=".env"

  if [ -f "$env_file" ]; then
    sed -i -e "s/^MYSQL_ROOT_PASSWORD=.*/MYSQL_ROOT_PASSWORD=\"$new_mysql_root_password\"/" "$env_file" || {
      echo "${RED}Error${RESET}: Failed to update MYSQL_ROOT_PASSWORD in $env_file"
      exit 1
    }
    echo "${GREEN}Updated${RESET} MYSQL_ROOT_PASSWORD successfully in $env_file"
  else
    echo "${RED}Error${RESET}: $env_file not found. Please check your repository structure."
    exit 1
  fi
}

# Updates the .env password for database user
update_mysql_password_env() {
  local new_mysql_password="$1"
  local env_file=".env"

  if [ -f "$env_file" ]; then
    sed -i -e "s/^MYSQL_DB_PASSWORD=.*/MYSQL_DB_PASSWORD=\"$new_mysql_password\"/" "$env_file" || {
      echo "${RED}Error${RESET}: Failed to update MYSQL_DB_PASSWORD in $env_file."
      exit 1
    }
    echo "${GREEN}Updated${RESET} MYSQL_DB_PASSWORD successfully in $env_file."
  else
    echo "${RED}Error${RESET}: $env_file not found. Please check your repository structure."
    exit 1
  fi
}

cleanup_backup_files() {
  find . -type f -name '*-e' -exec rm -f {} +
  echo "Cleanup completed. Removed files ending with '-e'"
}

echo_passwords() {
  echo "${MYSQL_DB_USER}:${MYSQL_DB_PASSWORD}"
  echo "${MYSQL_ROOT_USER}:${MYSQL_ROOT_PASSWORD}"
}


start_containers() {
  docker-compose up -d --build || { 
    echo "${RED}Error${RESET}: Failed to start Docker containers."; 
    exit 1; 
    }
}

# Main function that orchestrates the build process
main() {
  clone_app_repo ${GIT_REPO_URL}
  update_mysql_password_env $(generate_password 20)
  update_mysql_root_password_env $(generate_password 20)
  load_env ".env"
  update_config_php "config.php"
  update_create_user_sql "sql-user.sql"
  cleanup_backup_files
  # echo_passwords
  start_containers
}

main