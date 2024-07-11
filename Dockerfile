# Common arguments
ARG NODE_VERSION=20.15.0
ARG PLAYWRIGHT_VERSION=1.45.1
ARG NODE_IMAGE="node:${NODE_VERSION}-bookworm"
ARG PLAYWRIGHT_IMAGE="mcr.microsoft.com/playwright:v${PLAYWRIGHT_VERSION}-noble-amd64"
ARG CURL_IMPERSONATE_TAG=0.6.1-chrome-slim-bullseye
ARG PLAYWRIGHT_BROWSERS_PATH=/home/pw-browsers
ARG PNPM_VERSION=9.5.0

FROM lwthiker/curl-impersonate:${CURL_IMPERSONATE_TAG} AS curl-impersonate
FROM ${PLAYWRIGHT_IMAGE} AS playwright
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1

FROM ${NODE_IMAGE} AS node

ENV DEBIAN_FRONTEND=noninteractive
ENV USER=root

# Install necessary packages
RUN apt-get update && \
    apt-get install --no-install-recommends -y curl gnupg2 gnupg libnss3 nss-plugin-pem ca-certificates lsb-release x11vnc xvfb fluxbox && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install pnpm
RUN corepack enable
ENV PNPM_VERSION=${PNPM_VERSION}
RUN curl -fsSL https://get.pnpm.io/install.sh | ENV="$HOME/.shrc" SHELL="$(which sh)" sh -
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

# Install OpenResty
RUN curl -L https://openresty.org/package/pubkey.gpg | apt-key add -
RUN echo "deb http://openresty.org/package/debian $(lsb_release -sc) openresty" > /etc/apt/sources.list.d/openresty.list

RUN curl -fsSL https://packagecloud.io/cloudamqp/lavinmq/gpgkey | gpg --dearmor -o /usr/share/keyrings/lavinmq.gpg
RUN . /etc/os-release \
    && echo "deb [signed-by=/usr/share/keyrings/lavinmq.gpg] https://packagecloud.io/cloudamqp/lavinmq/${ID} ${VERSION_CODENAME} main" | tee /etc/apt/sources.list.d/lavinmq.list

RUN apt-get update && \
    apt-cache madison openresty

RUN apt-get update && \
    apt-get install --no-install-recommends -y lavinmq openresty && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

ENV PATH="/usr/local/openresty/bin:$PATH"

RUN openresty -v

WORKDIR /usr/src/app

COPY --from=curl-impersonate /build/out/curl-impersonate* /usr/local/bin
COPY --from=curl-impersonate /build/out/libcurl-impersonate* /usr/local/lib

RUN ldconfig

COPY --from=curl-impersonate /build/out /build/out
COPY --from=curl-impersonate /build/out/curl_* /usr/local/bin/

COPY --from=playwright ${PLAYWRIGHT_BROWSERS_PATH} ${PLAYWRIGHT_BROWSERS_PATH}

# Stage 3: Environment setup
FROM node AS release

ARG DISPLAY=:99
ENV DISPLAY=${DISPLAY}

ARG SCREEN_RESOLUTION=1920x1080
ENV SCREEN_RESOLUTION=${SCREEN_RESOLUTION}

ARG SCREEN_DEPTH=24
ENV SCREEN_DEPTH=${SCREEN_DEPTH}

ARG XVFB_WHD=${SCREEN_RESOLUTION}x${SCREEN_DEPTH}
ENV XVFB_WHD=${XVFB_WHD}

ARG START_XVBF=true
ENV START_XVBF=${START_XVBF}

ARG START_VNC=false
ENV START_VNC=${START_VNC}

ARG START_NGINX=false
ENV START_NGINX=${START_NGINX}

ARG VNC_PORT=5900
ENV VNC_PORT=${VNC_PORT}

ARG VNC_PASSWORD=123456
ENV VNC_PASSWORD=${VNC_PASSWORD}

ARG NGINX_BASE_PORT=3456
ENV NGINX_BASE_PORT=${NGINX_BASE_PORT}

ARG CMD="tail -f /dev/null"
ENV CMD=${CMD}

EXPOSE ${NGINX_BASE_PORT}
EXPOSE ${VNC_PORT}

# Expose LavinMQ ports
EXPOSE 5671
EXPOSE 5672
EXPOSE 15672

COPY ./start.sh .
RUN chmod +x ./start.sh

ENTRYPOINT ["./start.sh"]
