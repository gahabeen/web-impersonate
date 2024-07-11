Web Impersonate
---
Your neal ideal base image to automate the web


**Get started**
1. Directly plug it into your dockerfile: `FROM us-east1-docker.pkg.dev/gahabeen/web-impersonate/web-impersonate:latest AS base`
2. Build your own image: `make build`
3. Run the image by default: `make run`
4. Test the image with NGINX: `make run-nginx`

**What's included**
- node: 20.15.0
- bun: 1.1.18
- curl-impersonate: 0.6.1-chrome-slim-bullseye
- playwright: 1.45.1
- lavinmq: latest
- openresty (nginx)
- vnc (for debugging)

**Arguments**
Pass the following arguments to the docker build command to customize the image.
Ex: `docker build --build-arg CMD="npm run dev" ...`

| Variable | Description | Default |
| --- | --- | --- |
| CMD | Command to run | tail -f /dev/null |
| NODE_VERSION | Node image to use | 20.15.0 |
| BUN_VERSION | Bun version to use | bun-v1.1.18 |
| CURL_IMPERSONATE_TAG | curl-impersonate image tag | 0.6.1-chrome-slim-bullseye |
| PLAYWRIGHT_VERSION | Playwright version to use | 1.45.1 |
| PLAYWRIGHT_BROWSERS_PATH | Playwright browsers path | /root/pw-browsers |

**Environment variables (also available as build-time arguments)**

| DISPLAY | X virtual framebuffer display | :99 | :0..99 |
| SCREEN_RESOLUTION | X virtual framebuffer resolution | 1920x1080 |
| SCREEN_DEPTH | X virtual framebuffer depth | 24 |
| VNC_PORT | VNC server port | 5900 |
| VNC_PASSWORD | VNC server password | 123456 |
| START_XVBF | Start XVBF | true |
| START_VNC | Start VNC server | false |
| START_NGINX | Start NGINX server | false |