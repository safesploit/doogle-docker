

## Table of Contents


## MySQL Credentials

The credentials are stored in `.env` file.

```
user@vm(~/doogle-docker) $ cat .env
# APACHE-PHP-ENV
APACHE_PORT="8010"

# PHP
PHP_PORT="7000"

# MYSQL
MYSQL_PORT="9906"
MYSQL_DB_HOST="mysql_db"
MYSQL_DB_NAME="doogle"
MYSQL_DB_USER="doogle"
MYSQL_DB_PASSWORD=""

# MYSQL ROOT USER
MYSQL_ROOT_USER="root"
MYSQL_ROOT_PASSWORD=""

# GIT REPO
GIT_REPO_URL="https://github.com/safesploit/doogle.git"
```

## Build.sh script

### Function Loading Order Explanation

In the bash script `build.sh`, the critical order is ensuring that passwords are generated and updated before loading environment variables from the `.env` file using the `load_env` function. This sequence ensures that the newly generated passwords are available for subsequent operations that depend on them, like updating configuration files and SQL scripts. By following this order, the script avoids issues related to missing or outdated passwords when modifying sensitive configurations.

1. **`clone_app_repo ${GIT_REPO_URL}`**: This function clones a Git repository into a specified directory. It should be executed early in your script to ensure that the application source code is available before any other operations are performed on it.

2. **`update_mysql_password_env $(generate_password 20)`**: This function generates a random password and updates the environment variable `MYSQL_DB_PASSWORD` in the `.env` file. It should come after cloning the repository because it needs the repository's files (like `.env`) to operate on.

3. **`update_mysql_root_password_env $(generate_password 20)`**: Similar to the previous function, this one generates a random password and updates the environment variable `MYSQL_ROOT_PASSWORD` in the `.env` file. It also requires the repository's files to be in place.

4. **`load_env ".env"`**: This function loads environment variables from the `.env` file. It should be called after updating environment variables in steps 2 and 3 to ensure that the newly generated passwords are available for subsequent operations.

5. **`update_config_php "config.php"`**: This function updates the `config.php` file, replacing placeholders with actual environment variables. It relies on the loaded environment variables from step 4 to perform the replacements correctly.

6. **`update_create_user_sql "sql-user.sql"`**: This function updates the SQL script file `sql-user.sql`. Like the previous function, it relies on the loaded environment variables to update the script correctly.

7. **`cleanup_backup_files`**: This function is executed at the end to clean up any backup or temporary files created during the script's execution. It can be placed at the end because it doesn't depend on other functions' results.

8. **`start_containers`**: If uncommented, this function starts Docker containers. Its position at the end of the script indicates that it should be the last step in the process, after all other preparations have been completed.

By following this order, you ensure that each function has the necessary information and resources available to perform its specific task correctly, leading to a smooth and error-free execution of your script.

## Explanation: The Need for the `ALTER USER` Command

In the SQL script, an issue arises when creating a user with an initial empty password:

```sql
CREATE USER IF NOT EXISTS 'doogle'@'%' IDENTIFIED WITH 'caching_sha2_password' BY '';
```

While this approach is acceptable in some cases, it may lead to authentication issues, especially when using certain authentication methods like 'caching_sha2_password'.


Here's why the `ALTER USER` command is necessary:

- **Proper Password Assignment**: The `CREATE USER` statement sets an empty password initially. This can cause problems with authentication because many authentication methods, including 'caching_sha2_password', require a non-empty password for security reasons.

- **Updating Password**: The `ALTER USER` statement is used to update the user's password to a secure and non-empty value, such as 'o2zE7yfG9zPCU0gMt4Un'. This ensures that the 'doogle' user has a valid password that can be used for authentication.

- **Preventing Authentication Errors**: By updating the password with `ALTER USER`, you prevent authentication errors that could occur when attempting to log in with an empty password. It ensures that the user can authenticate successfully.

In summary, the `ALTER USER` command is needed to correct the initial empty password and assign a secure password to the user, ensuring proper authentication and preventing potential issues related to empty passwords.