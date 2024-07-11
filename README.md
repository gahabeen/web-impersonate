Web Impersonate
---
Base image to automate the web
Available for linux/amd64 and linux/arm64

**Start your project with a prebuilt image**

```dockerfile
FROM us-east1-docker.pkg.dev/gahabeen/web-impersonate/web-impersonate:latest AS base
```

**Manually build your own image**
```bash
# Build your own image
make build

# Run the image by default
make run

# Test the image with NGINX
make run-nginx
```

**What's included**
- node: 20.15.0
- pnpm: 9.5.0
- curl-impersonate: 0.6.1
- playwright: 1.45.1
- lavinmq: latest
- openresty (nginx)
- vnc

**Arguments**
Pass the following arguments to the docker build command to customize the image.
Ex: `docker build --build-arg CMD="npm run dev" ...`

| Variable | Description | Default |
| --- | --- | --- |
| CMD | Command to run | tail -f /dev/null |
| NODE_VERSION | Node image to use | 20.15.0 |
| PNPM_VERSION | pnpm version | 9.5.0 |
| CURL_IMPERSONATE_VERSION | curl-impersonate image tag | 0.6.1 |
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