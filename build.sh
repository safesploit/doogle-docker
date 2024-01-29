#!/bin/bash

# Define ANSI escape codes for color formatting globally
# GREEN='\e[32m'
# RED='\e[31m'
# RESET='\e[0m'

# macOS
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
RESET=$(tput sgr0)

generate_password() {
  local length="$1"
  local characters="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
  local password=""

  if [ -z "$length" ]; then
    length=12  # Default password length
  fi

  for i in $(seq 1 "$length"); do
    random_char="${characters:RANDOM % ${#characters}:1}"
    password="${password}${random_char}"
  done

  echo "$password"
}

# Function to load environment variables from .env file
load_env() {
  local script_dir="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
  local env_file="${script_dir}/.env"

  if [ -f "$env_file" ]; then
    source "$env_file"
  else
    echo "Error: The .env file is missing. Please create it and define the required environment variables."
    exit 1
  fi
}

# Function to clone the PHP application repository
clone_app_repo() {
  local repo_url="https://github.com/safesploit/doogle.git"
  local target_dir="src"

  if [ -d "$target_dir" ]; then
    echo "Directory '$target_dir' already exists. Skipping clone operation."
  else
    git clone "$repo_url" "$target_dir" || { echo "Error: Cloning the repository failed."; exit 1; }
  fi
}

update_config_php() {
  local target_dir="src"
  local config_php_file="${target_dir}/config.php"
  local backup_config_php_file="${config_php_file}-e" # Created by sed -e

  if [ -f "$config_php_file" ]; then
    sed -i -e "s/\(\$dbname =\) \".*\";/\1 \"\${MYSQL_DB_NAME}\";/" "$config_php_file"
    sed -i -e "s/\(\$dbhost =\) \".*\";/\1 \"\${MYSQL_DB_HOST}\";/" "$config_php_file"
    sed -i -e "s/\(\$dbuser =\) \".*\";/\1 \"\${MYSQL_DB_USER}\";/" "$config_php_file"
    sed -i -e "s/\(\$dbpass =\) \".*\";/\1 \"\${MYSQL_DB_PASSWORD}\";/" "$config_php_file"
    
    echo "Updated $config_php_file with environment variable references."
  else
    echo "Error: $config_php_file not found. Please check your repository structure."
    exit 1
  fi
}

update_create_user_sql() {
  local sql_file="config/doogle-user.sql"
  local mysql_db_password="$MYSQL_DB_PASSWORD"

  if [ -f "$sql_file" ]; then
    sed -i -e "s#IDENTIFIED BY '[^']*'#IDENTIFIED BY '$mysql_db_password'#g" "$sql_file" || {
      echo "Error: Failed to update the MySQL user password in the SQL script."
      exit 1
    }
    echo "Updated the MySQL user password in $sql_file."
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
      echo "Error: Failed to update MYSQL_ROOT_PASSWORD in $env_file."
      exit 1
    }
    echo "MYSQL_ROOT_PASSWORD updated successfully in $env_file."
  else
    echo "Error: $env_file not found. Please check your repository structure."
    exit 1
  fi
}

# Updates the .env password for database user
update_mysql_password_env() {
  local new_mysql_password="$1"
  local env_file=".env"

  if [ -f "$env_file" ]; then
    sed -i -e "s/^MYSQL_DB_PASSWORD=.*/MYSQL_DB_PASSWORD=\"$new_mysql_password\"/" "$env_file" || {
      echo "Error: Failed to update MYSQL_DB_PASSWORD in $env_file."
      exit 1
    }
    echo "MYSQL_DB_PASSWORD updated successfully in $env_file."
  else
    echo "Error: $env_file not found. Please check your repository structure."
    exit 1
  fi
}

cleanup_backup_files() {
  find . -type f -name '*-e' -exec rm -f {} +
  echo "Cleanup completed. Removed files ending with '-e'"
}


start_containers() {
  docker-compose up -d --build || { echo "Error: Failed to start Docker containers."; exit 1; }
}

# Main function that orchestrates the build process
main() {
  load_env
  clone_app_repo
  update_config_php
  update_create_user_sql
  update_mysql_password_env $(generate_password 20)
  update_mysql_root_password_env $(generate_password 20)
  cleanup_backup_files
  # start_containers
}

main