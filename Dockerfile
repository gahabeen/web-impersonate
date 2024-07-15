# Common arguments
ARG NODE_VERSION="20.15.0"
ARG PLAYWRIGHT_VERSION="1.45.1"
ARG NODE_IMAGE="node:${NODE_VERSION}-bookworm"

FROM ${NODE_IMAGE} AS node

ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
ENV DEBIAN_FRONTEND=noninteractive
ENV USER=root

# Install necessary packages
RUN apt-get update && apt-get install -y --no-install-recommends tar gettext-base p7zip curl gnupg2 gnupg libnss3 nss-plugin-pem ca-certificates lsb-release x11vnc xvfb fluxbox

ARG TARGETPLATFORM
ARG BUILDARCH

# Install ffmpeg
RUN apt-get update && apt-get install -y --no-install-recommends ffmpeg

# Install sqlite3
RUN apt-get install --no-install-recommends -y sqlite3

# Install curl-impersonate
ARG CURL_IMPERSONATE_VERSION="0.6.1"
RUN \
    if [ "$TARGETPLATFORM" = 'linux/arm64' ]; then CURL_IMPERSONATE_ARCH="aarch64"; else CURL_IMPERSONATE_ARCH="x86_64"; fi && \
    CURL_IMPERSONATE_FILENAME="curl-impersonate-v${CURL_IMPERSONATE_VERSION}.${CURL_IMPERSONATE_ARCH}-linux-gnu.tar.gz" && \
    curl -L -o /tmp/$CURL_IMPERSONATE_FILENAME "https://github.com/lwthiker/curl-impersonate/releases/download/v${CURL_IMPERSONATE_VERSION}/${CURL_IMPERSONATE_FILENAME}" && \
    mkdir -p /opt/curl-impersonate && \
    tar -xzf /tmp/$CURL_IMPERSONATE_FILENAME -C /opt/curl-impersonate && \
    rm /tmp/$CURL_IMPERSONATE_FILENAME

ENV PATH="/opt/curl-impersonate:$PATH"

# Install pnpm
ARG PNPM_VERSION="9.5.0"
ENV PNPM_VERSION=${PNPM_VERSION}
RUN npm install -g pnpm@${PNPM_VERSION}

# Install playwright
RUN npx playwright@${PLAYWRIGHT_VERSION} install --with-deps chromium firefox webkit

# Install openresty
RUN curl -L https://openresty.org/package/pubkey.gpg | gpg --dearmor -o /usr/share/keyrings/openresty.gpg
RUN if [ "$TARGETPLATFORM" = 'linux/arm64' ]; then OPENRESTY_PATH="/arm64/debian"; else OPENRESTY_PATH="/debian"; fi && \
 echo deb "[signed-by=/usr/share/keyrings/openresty.gpg]" http://openresty.org/package${OPENRESTY_PATH} $(lsb_release -sc) openresty > /etc/apt/sources.list.d/openresty.list;

# Install haproxy
RUN curl https://haproxy.debian.net/bernat.debian.org.gpg | gpg --dearmor -o /usr/share/keyrings/haproxy.debian.net.gpg
RUN echo deb "[signed-by=/usr/share/keyrings/haproxy.debian.net.gpg]" http://haproxy.debian.net bookworm-backports-3.0 main > /etc/apt/sources.list.d/haproxy.list
RUN apt-get update && apt-get install --no-install-recommends -y libjemalloc2 liblua5.3-0 libopentracing-c-wrapper0 libopentracing1 haproxy=3.0.\*

# Install lavinmq
RUN curl -fsSL https://packagecloud.io/cloudamqp/lavinmq/gpgkey | gpg --dearmor -o /usr/share/keyrings/lavinmq.gpg
RUN . /etc/os-release \
    && echo "deb [signed-by=/usr/share/keyrings/lavinmq.gpg] https://packagecloud.io/cloudamqp/lavinmq/${ID} ${VERSION_CODENAME} main" | tee /etc/apt/sources.list.d/lavinmq.list

RUN apt-get update && apt-cache madison openresty
RUN apt-get install --no-install-recommends -y lavinmq openresty
ENV PATH="/usr/local/openresty/bin:$PATH"

# Clean up
RUN rm -rf /var/lib/apt/lists/*

# Stage 3: Environment setup
FROM node AS release

WORKDIR /usr/src/app

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

ARG START_HAPROXY=false
ENV START_HAPROXY=${START_HAPROXY}

ARG VNC_PORT=5900
ENV VNC_PORT=${VNC_PORT}

ARG VNC_PASSWORD=123456
ENV VNC_PASSWORD=${VNC_PASSWORD}

ARG NGINX_BASE_PORT
ENV NGINX_BASE_PORT=${NGINX_BASE_PORT}

ARG HAPROXY_BASE_PORT
ENV HAPROXY_BASE_PORT=${HAPROXY_BASE_PORT}

ARG CMD="tail -f /dev/null"
ENV CMD=${CMD}

EXPOSE ${NGINX_BASE_PORT}
EXPOSE ${VNC_PORT}
EXPOSE ${HAPROXY_BASE_PORT}

# Expose LavinMQ ports
EXPOSE 5671
EXPOSE 5672
EXPOSE 15672

COPY ./start.sh .
RUN chmod +x ./start.sh

ENTRYPOINT ["./start.sh"]
