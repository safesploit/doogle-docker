#!/bin/bash
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# 
if [ -d "$SCRIPT_DIR/doogle"]
then
	echo "Doogle Directory exists, exiting!"
	exit 1
fi
# if [ -d "$SCRIPT_DIR/src"]
# 	echo "src Directory exists, exiting!"
# 	exit 1

git clone https://github.com/safesploit/doogle.git
mkdir src
mv ./doogle ./src/

echo '<?php
ob_start();

$dbname = "doogle";
$dbhost = "mysql_db"; //Docker image hostname
$dbuser = "doogle";
$dbpass = "PASSWORD_HERE";

try 
{
	$con = new PDO("mysql:dbname=$dbname;host=$dbhost", "$dbuser", "$dbpass");
	$con->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_WARNING);
}
catch(PDOExeption $e) 
{
	echo "Connection failed: " . $e->getMessage();
}
?>
' > config.php

mv ./config.php ./src/doogle/config.php


docker-compose up -d --build
# docker compose build

echo 'Run: $ docker compose up'

exit 1