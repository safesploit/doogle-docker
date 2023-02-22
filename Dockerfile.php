FROM php:8.1-apache
WORKDIR /var/www/html
RUN docker-php-ext-install mysqli pdo pdo_mysql
RUN docker-php-ext-enable mysqli
RUN a2enmod rewrite
ADD /src/doogle/ /var/www/html/
