Web Impersonate
---
Your neal ideal base image to automate the web


**USAGE**
1. Directly plug it into your dockerfile
`FROM us-east1-docker.pkg.dev/gahabeen/web-impersonate/web-impersonate:latest AS base`


**INCLUDES**

- node 20.15.0
- bun 1.1.18
- curl-impersonate
- playwright
- openresty (nginx)
- vnc (for debugging)

**PLATFORMS**

- linux/amd64
- linux/arm64 (like for Mac M series)

**BUILD ARGS**

All variables are optional and can be set in the docker run command via ARGS.

| Variable | Description | Default | Options |
| --- | --- | --- | --- |
| CMD_TO_RUN | Command to run | tail -f /dev/null | - |
| NODE_VERSION | Node image to use | 20.15.0 | - |
| BUN_VERSION | Bun version to use | bun-v1.1.18 | - |
| CURL_BROWSER_TYPE | Browser type to use with curl-impersonate | chrome | chrome, firefox |
| PLAYWRIGHT_VERSION | Playwright version to use | 1.45.1 | - |
| PLAYWRIGHT_BROWSERS_PATH | Playwright browsers path | /root/pw-browsers | - |
| DISPLAY | X virtual framebuffer display | :99 | :0..99 |
| SCREEN_RESOLUTION | X virtual framebuffer resolution | 1920x1080 | - |
| SCREEN_DEPTH | X virtual framebuffer depth | 24 | - |
| START_XVBF | Start XVBF | true | true, false |
| START_VNC | Start VNC server | false | true, false |
| START_NGINX | Start NGINX server | false | true, false |
| VNC_PORT | VNC server port | 5900 | 1-65535 |
| VNC_PASSWORD | VNC server password | 123456 | - |
|---|---|---|---|
| *Probably don't change below* |---|---|---|
| BROTLI_VERSION | Brotli version to use | 1.0.9 | - |
| BORING_SSL_COMMIT | BoringSSL commit to use | 1b7fdbd9101dedc3e0aa3fcf4ff74eacddb34ecc | - |
| NGHTTP2_VERSION | NGHTTP2 version to use | 1.56.0 | - |
| NGHTTP2_URL | NGHTTP2 URL to download from | [link](https://github.com/nghttp2/nghttp2/releases/download/v1.56.0/nghttp2-1.56.0.tar.bz2) | - |
| CURL_VERSION | curl version to use | curl-8.1.1 | - |