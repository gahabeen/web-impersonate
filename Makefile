.PHONY: build

build:
	docker build -t web-impersonate .

run:
	 docker run --rm -it -e CMD="echo \"🦄 Web Impersonate is running!\"" web-impersonate