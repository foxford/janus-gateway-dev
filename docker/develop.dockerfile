FROM netologygroup/janus-gateway:9668ce0 as janus-conference-plugin
FROM debian:stretch

## -----------------------------------------------------------------------------
## Install dependencies
## -----------------------------------------------------------------------------
RUN set -xe \
    && apt-get update \
    && apt-get -y --no-install-recommends install \
        libconfig-dev \
        libmicrohttpd-dev \
        libjansson-dev \
        libnice-dev \
        libcurl4-openssl-dev \
        libsofia-sip-ua-dev \
        libopus-dev \
        libogg-dev \
        libwebsockets-dev \
        libsrtp2-dev \
        gengetopt \
        ca-certificates \
        git \
        libtool \
        m4 \
        automake \
        make \
        libgstreamer1.0-dev \
        libgstreamer-plugins-base1.0-dev \
        gstreamer1.0-plugins-base \
        gstreamer1.0-plugins-good \
        gstreamer1.0-plugins-bad \
        gstreamer1.0-plugins-ugly \
        gstreamer1.0-libav \
        libgstrtspserver-1.0-dev \
        wget \
        gdb \
        gdbserver \
        libasan3

## -----------------------------------------------------------------------------
## Build Paho MQTT client
## -----------------------------------------------------------------------------
RUN PAHO_MQTT_BUILD_DIR=$(mktemp -d) \
    && cd "${PAHO_MQTT_BUILD_DIR}" \
    && git clone "https://github.com/eclipse/paho.mqtt.c.git" . \
    && git checkout v1.3.0 \
    && make \
    && make install

## -----------------------------------------------------------------------------
## Build Janus Gateway
## -----------------------------------------------------------------------------
COPY ./janus-gateway/ /janus-gateway

RUN set -xe \
    && cd /janus-gateway \
    && CFLAGS="-g -fsanitize=thread -fsanitize=address -fno-omit-frame-pointer" \
    && LDFLAGS="-lasan" \
    && ./autogen.sh \
    && ./configure --prefix=/opt/janus \
    && make -j $(nproc) \
    && make install \
    && make configs

## -----------------------------------------------------------------------------
## Set up janus-conference plugin
## -----------------------------------------------------------------------------
COPY --from=janus-conference-plugin /opt/janus/lib/janus/plugins/*.so /opt/janus/lib/janus/plugins/

## -----------------------------------------------------------------------------
## Configure Janus Gateway
## -----------------------------------------------------------------------------
COPY ./docker/configs/* /opt/janus/etc/janus/
