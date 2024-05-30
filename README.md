# Observable Framework Workspace

A workspace for processing and visualizing data.

## Usage
- Run `make dev` to open a tmux session with a vi editor and to start the services.

## Architecture

docker compose is used to containerize the services and to simplify environment setup.

Jupyter is used for data processing, postgres is used to exchange data between the containers, and Observable Framework is used for data visualization.
