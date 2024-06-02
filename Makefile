NAME=observable-framework

# track the build timestamp in Dockerfile.build so the images are rebuilt when dependencies change
Dockerfile.build: Dockerfile package.json
	@docker-compose build ${NAME}
	@docker-compose build jupyter
	touch $@

clean:
	rm Dockerfile.build

purgecache:
	rm -rf src/.observablehq/cache

build:
	docker-compose run ${NAME} /bin/bash --login -c "\
		 npm run build; \
	"

deploy:
	docker-compose run ${NAME} /bin/bash --login -c "\
		cat /run/secrets/observable_token | { read -r OBSERVABLE_TOKEN; npm run deploy -- --build --message '`git log -1 --pretty=\%s`'; } ;\
	"

# useful for running npm
shell:
	@docker-compose run ${NAME} /bin/bash

up: Dockerfile.build
	@docker-compose up

# run commands with send-keys so the window returns to a shell when the command exits
dev:
	-tmux kill-session -t "${NAME}"
	tmux new-session -s "${NAME}" -d -n vi
	tmux send-keys -t "${NAME}:vi" "vi" Enter
	tmux new-window -t "${NAME}" -n shell "/bin/zsh"
	tmux new-window -t "${NAME}" -n build
	tmux send-keys -t "${NAME}:build" "make up" Enter
	tmux select-window -t "${NAME}:vi"
	tmux attach-session -t "${NAME}"
