FROM mysql:8.0
WORKDIR /etc/mysql
RUN chown -R mysql:root /var/lib/mysql/
ARG MYSQL_ROOT_PASSWORD
ENV MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD
COPY /config/doogle-user.sql /etc/mysql/doogle-user.sql
COPY /src/doogle/doogle-tables-no-data.sql /etc/mysql/doogle-tables-no-data.sql
RUN cp /etc/mysql/doogle-user.sql /docker-entrypoint-initdb.d
RUN cp /etc/mysql/doogle-tables-no-data.sql /docker-entrypoint-initdb.d