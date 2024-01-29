FROM mysql:8.0
WORKDIR /docker-entrypoint-initdb.d
COPY config/sql-user.sql .
COPY src/doogle-tables-no-data.sql .
ARG MYSQL_ROOT_PASSWORD
ENV MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD
RUN chown -R mysql:root /var/lib/mysql/