.PHONY: build

build:
	docker buildx build --platform linux/amd64,linux/arm64 -t us-east1-docker.pkg.dev/vobile-373513/bf-base/image:latest .

publish:
	docker buildx push --platform linux/amd64,linux/arm64 -t us-east1-docker.pkg.dev/vobile-373513/bf-base/image:latest .