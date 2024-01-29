#!/bin/bash
set -e

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

# Function to update the config.php file
update_config_php() {
  local target_dir="src"
  local config_php_file="${target_dir}/config.php"

  # Check if the config.php file exists
  if [ -f "$config_php_file" ]; then
    # Insert environment variable references after the variable names
    sed -i -e "s/\(\$dbname =\) \".*\";/\1 \"\${MYSQL_DB_NAME}\";/" "$config_php_file"
    sed -i -e "s/\(\$dbhost =\) \".*\";/\1 \"\${MYSQL_DB_HOST}\";/" "$config_php_file"
    sed -i -e "s/\(\$dbuser =\) \".*\";/\1 \"\${MYSQL_DB_USER}\";/" "$config_php_file"
    sed -i -e "s/\(\$dbpass =\) \".*\";/\1 \"\${MYSQL_DB_PASSWORD}\";/" "$config_php_file"
    
    # Remove backup files created by sed
    rm -f "${config_php_file}-e"  
    echo "Updated $config_php_file with environment variable references."
  else
    echo "Error: $config_php_file not found. Please check your repository structure."
    exit 1
  fi
}

# Function to replace placeholders in the SQL script
replace_password_placeholder() {
  local password="$1"
  sed -i "s#'PASSWORD_HERE'#'$password'#g" config/doogle-user.sql || { echo "Error: Failed to replace placeholders in the SQL script."; exit 1; }
}

# Function to start Docker containers using Docker Compose
start_containers() {
  docker-compose up -d --build || { echo "Error: Failed to start Docker containers."; exit 1; }
}

# Main function that orchestrates the build process
main() {
  load_env
  clone_app_repo
  replace_password_placeholder "${MYSQL_DOOGLE_PASSWORD}"
  generate_config_php
  start_containers
}

# Call the main function to initiate the build process
# main
update_config_php
