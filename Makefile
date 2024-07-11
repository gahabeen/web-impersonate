.PHONY: build

build:
	docker-compose build

run:
	CMD="echo \"🦄 Web Impersonate is running!\"" docker-compose up

run-nginx:
	START_NGINX="true" docker-compose up