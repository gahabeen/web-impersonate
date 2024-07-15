.PHONY: build

build:
	docker build --build-arg CMD="echo \"🦄 Web Impersonate is running!\"" -t web-impersonate .