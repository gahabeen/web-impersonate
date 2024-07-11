.PHONY: build

build:
	docker-compose build

run:
	CMD="echo \"🦄 Web Impersonate is running!\"" docker-compose up


# Run NGINX server local sample
# Try running `make run-nginx` and open http://localhost:3456
run-nginx:
	START_NGINX="true" docker-compose up