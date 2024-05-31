# Observable Framework Workspace

A local development workspace for processing and visualizing data.

## Usage

- Run `make dev` to open a tmux session with a vi editor and to start the services.

## Tools

- Docker Compose is used to containerize the services and to simplify environment setup.
- DuckDB is used for in-memory analytical data processing queries and Parquet export.

## Containerized Services

- PostgreSQL is used to store data that is exchanged between services.
- Jupyter is for local data exploration and processing.
- Observable Framework is the frontend for data visualization and for generating the static data app.
