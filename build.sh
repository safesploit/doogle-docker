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

# Function to generate and move the config.php file
generate_config_php() {
  local target_dir="src/doogle"
  local config_php_file="${target_dir}/config.php"

  # Create the config.php file with environment variables
  echo "<?php
  ob_start();

  \$dbname = 'doogle';
  \$dbhost = 'mysql_db'; // Docker image hostname
  \$dbuser = 'doogle';
  \$dbpass = '${MYSQL_ROOT_PASSWORD}'; // Use the MYSQL_ROOT_PASSWORD from .env

  try 
  {
    \$con = new PDO('mysql:dbname=' . \$dbname . ';host=' . \$dbhost, \$dbuser, \$dbpass);
    \$con->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_WARNING);
  }
  catch(PDOException \$e) 
  {
    echo 'Connection failed: ' . \$e->getMessage();
  }
  ?>" > "$config_php_file"

  echo "Generated config.php file."

  # Move the config.php file to the target directory
  mv "$config_php_file" "$target_dir/"
  echo "Moved config.php file to $target_dir/"
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
main
