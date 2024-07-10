ARG NODE_VERSION=20.15.0
ARG NODE_IMAGE="node:${NODE_VERSION}-bookworm"

FROM python:3.11-slim-bookworm AS curl-impersonate

ARG TARGETPLATFORM

WORKDIR /build

ARG CURL_BROWSER_TYPE=chrome
ENV CURL_BROWSER_TYPE=${CURL_BROWSER_TYPE}

# Install common dependencies in one RUN statement
RUN apt-get update && \
    apt-get install -y \
    git ninja-build cmake curl zlib1g-dev \
# The following are needed because we are going to change some autoconf scripts, both for libnghttp2 and curl.
    autoconf automake autotools-dev pkg-config libtool \
# Dependencies for downloading and building nghttp2
    bzip2 xz-utils \
# Dependencies for downloading and building curl
    g++ golang-go unzip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Download and compile libbrotli
ARG BROTLI_VERSION=1.0.9
RUN curl -L https://github.com/google/brotli/archive/refs/tags/v${BROTLI_VERSION}.tar.gz -o brotli-${BROTLI_VERSION}.tar.gz && \
    tar xf brotli-${BROTLI_VERSION}.tar.gz && \
    cd brotli-${BROTLI_VERSION} && \
    mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=./installed .. && \
    cmake --build . --config Release --target install

# BoringSSL doesn't have versions. Choose a commit that is used in a stable
# Chromium version.
ARG BORING_SSL_COMMIT=1b7fdbd9101dedc3e0aa3fcf4ff74eacddb34ecc
RUN curl -L https://github.com/google/boringssl/archive/${BORING_SSL_COMMIT}.zip -o boringssl.zip && \
    unzip boringssl && \
    mv boringssl-${BORING_SSL_COMMIT} boringssl

# Compile BoringSSL.
# See https://boringssl.googlesource.com/boringssl/+/HEAD/BUILDING.md
COPY curl-impersonate/${CURL_BROWSER_TYPE}/patches/boringssl-*.patch boringssl/
RUN cd boringssl && \
    for p in $(ls boringssl-*.patch); do patch -p1 < $p; done && \
    mkdir build && cd build && \
    cmake \
        -DCMAKE_C_FLAGS="-Wno-error=array-bounds -Wno-error=stringop-overflow" \
        -DCMAKE_BUILD_TYPE=Release -DCMAKE_POSITION_INDEPENDENT_CODE=on -GNinja .. && \
    ninja

# Fix the directory structure so that curl can compile against it.
# See https://everything.curl.dev/source/build/tls/boringssl
RUN mkdir boringssl/build/lib && \
    ln -s ../crypto/libcrypto.a boringssl/build/lib/libcrypto.a && \
    ln -s ../ssl/libssl.a boringssl/build/lib/libssl.a && \
    cp -R boringssl/include boringssl/build

ARG NGHTTP2_VERSION=nghttp2-1.56.0
ARG NGHTTP2_URL=https://github.com/nghttp2/nghttp2/releases/download/v1.56.0/nghttp2-1.56.0.tar.bz2
# Download & compile nghttp2 for HTTP/2.0 support.
RUN curl -o ${NGHTTP2_VERSION}.tar.bz2 -L ${NGHTTP2_URL} && \
    tar xf ${NGHTTP2_VERSION}.tar.bz2 && \
    cd ${NGHTTP2_VERSION} && \
    ./configure --prefix=/build/${NGHTTP2_VERSION}/installed --with-pic --disable-shared && \
    make && make install

# Download curl
ARG CURL_VERSION=curl-8.1.1
RUN curl -o ${CURL_VERSION}.tar.xz https://curl.se/download/${CURL_VERSION}.tar.xz && \
    tar xf ${CURL_VERSION}.tar.xz

# Patch and compile curl with dependencies
COPY curl-impersonate/${CURL_BROWSER_TYPE}/patches/curl-*.patch ${CURL_VERSION}/
RUN cd ${CURL_VERSION} && \
    for p in $(ls curl-*.patch); do patch -p1 < $p; done && \
    autoreconf -fi && \
    # Compile curl with nghttp2, libbrotli and nss (firefox) or boringssl (chrome).
# Enable keylogfile for debugging of TLS traffic.
    ./configure --prefix=/build/install --enable-static --disable-shared --enable-websockets \
                --with-nghttp2=/build/${NGHTTP2_VERSION}/installed \
                --with-brotli=/build/brotli-${BROTLI_VERSION}/build/installed \
                --with-openssl=/build/boringssl/build \
                LIBS="-pthread" CFLAGS="-I/build/boringssl/build" USE_CURL_SSLKEYLOGFILE=true && \
    make && make install

RUN mkdir out && \
    cp /build/install/bin/curl-impersonate-${CURL_BROWSER_TYPE} out/ && \
    ln -s curl-impersonate-${CURL_BROWSER_TYPE} out/curl-impersonate && \
    strip out/curl-impersonate

# Verify that the resulting 'curl' has all the necessary features. And that the resulting 'curl' is really statically compiled
RUN ./out/curl-impersonate -V | grep -q zlib && \
    ./out/curl-impersonate -V | grep -q brotli && \
    ./out/curl-impersonate -V | grep -q nghttp2 && \
    ./out/curl-impersonate -V | grep -q -e NSS -e BoringSSL && \
    ./out/curl-impersonate -V | grep -q -e wss && \
    !(ldd ./out/curl-impersonate | grep -q -e libcurl -e nghttp2 -e brotli -e ssl -e crypto)

RUN rm -Rf /build/install

# Re-compile libcurl dynamically
RUN cd ${CURL_VERSION} && \
    ./configure --prefix=/build/install --enable-websockets \
                --with-nghttp2=/build/${NGHTTP2_VERSION}/installed \
                --with-brotli=/build/brotli-${BROTLI_VERSION}/build/installed \
                --with-openssl=/build/boringssl/build \
                LIBS="-pthread" CFLAGS="-I/build/boringssl/build" USE_CURL_SSLKEYLOGFILE=true && \
    make clean && make && make install

# Copy libcurl-impersonate and create symbolic links
RUN cp -d /build/install/lib/libcurl-impersonate* /build/out && \
    ver=$(readlink -f ${CURL_VERSION}/lib/.libs/libcurl-impersonate-${CURL_BROWSER_TYPE}.so | sed 's/.*so\.//') && \
    major=$(echo -n $ver | cut -d'.' -f1) && \
    ln -s "libcurl-impersonate-${CURL_BROWSER_TYPE}.so.$ver" "out/libcurl-impersonate.so.$ver" && \
    ln -s "libcurl-impersonate.so.$ver" "out/libcurl-impersonate.so" && \
    strip "out/libcurl-impersonate.so.$ver"

RUN ! (ldd ./out/curl-impersonate | grep -q -e nghttp2 -e brotli -e ssl -e crypto)

COPY curl-impersonate/${CURL_BROWSER_TYPE}/curl_* out/
RUN chmod +x out/curl_*

FROM ${NODE_IMAGE} AS playwright

ENV DEBIAN_FRONTEND=noninteractive
ENV USER=root

# Install necessary packages
RUN apt-get update && \
    apt-get install --no-install-recommends -y wget curl gnupg2 wget gnupg ca-certificates lsb-release x11vnc xvfb fluxbox && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

ARG TARGETPLATFORM

RUN if [ -z "$TARGETPLATFORM" ]; then \
        ARCH=$(uname -m); \
        if [ "$ARCH" = "x86_64" ]; then \
            TARGETPLATFORM="linux/amd64"; \
        elif [ "$ARCH" = "aarch64" ]; then \
            TARGETPLATFORM="linux/arm64"; \
        else \
            echo "Unsupported architecture: $ARCH"; \
            exit 1; \
        fi; \
    fi

# Install OpenResty
RUN wget -O - https://openresty.org/package/pubkey.gpg | apt-key add -
RUN apt-get update

RUN \
    if [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
        echo "deb http://openresty.org/package/arm64/debian $(lsb_release -sc) openresty" > /etc/apt/sources.list.d/openresty.list; \
    elif [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
        echo "deb http://openresty.org/package/debian $(lsb_release -sc) openresty" > /etc/apt/sources.list.d/openresty.list; \
    fi

RUN apt-get update && \
    apt-cache madison openresty

RUN apt-get update && \
    apt-get install --no-install-recommends -y openresty && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

ENV PATH="/usr/local/openresty/bin:$PATH"

RUN openresty -v

WORKDIR /usr/src/app

ARG BUN_VERSION=bun-v1.1.18
ENV BUN_VERSION=${BUN_VERSION}

# Install Bun
RUN curl -fsSL https://bun.sh/install | bash -s "${BUN_VERSION}"
ENV PATH="/root/.bun/bin:$PATH"

ARG PLAYWRIGHT_VERSION=1.45.1
ENV PLAYWRIGHT_VERSION=${PLAYWRIGHT_VERSION}

# Set up Playwright
ENV HOME=/root
ENV PLAYWRIGHT_BROWSERS_PATH=$HOME/pw-browsers
RUN mkdir -p ${PLAYWRIGHT_BROWSERS_PATH}
RUN npx -y playwright@${PLAYWRIGHT_VERSION} install --with-deps

ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1

# ------------------------------------------------------------------------------

FROM playwright AS release

COPY --from=curl-impersonate /build/out/curl-impersonate* /usr/local/bin
COPY --from=curl-impersonate /build/out/libcurl-impersonate* /usr/local/lib
RUN ldconfig
COPY --from=curl-impersonate /build/out /build/out
COPY --from=curl-impersonate /build/out/curl_* /usr/local/bin/

FROM release AS env

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

EXPOSE ${VNC_PORT}

COPY ./start.sh .
RUN chmod +x ./start.sh

ENTRYPOINT ["./start.sh"]