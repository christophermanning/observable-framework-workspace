FROM node:22-bookworm-slim

RUN apt update

# install git for deploy messages
RUN apt install -y git

# install psql to query the database from the observable-framework container
RUN apt install -y postgresql-client

# install duckdb for parquet export
RUN apt install -y wget unzip
RUN wget https://github.com/duckdb/duckdb/releases/download/v0.10.3/duckdb_cli-linux-aarch64.zip \
    && unzip duckdb_cli-linux-aarch64.zip \
    && mv duckdb /usr/local/bin/
RUN duckdb -c "install postgres"

WORKDIR /app
COPY package.json package-lock.json .
RUN npm install
