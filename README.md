

## Table of Contents


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
