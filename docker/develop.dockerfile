FROM netologygroup/janus-gateway:408fbf2 as janus-conference-plugin
FROM debian:buster

## -----------------------------------------------------------------------------
## Install dependencies
## -----------------------------------------------------------------------------
RUN set -xe \
    && apt-get update \
    && apt-get -y --no-install-recommends install \
        autoconf \
        automake \
        awscli \
        ca-certificates \
        curl \
        ffmpeg \
        gengetopt \
        git \
        libavformat-dev \
        libavcodec-dev \
        libconfig-dev \
        libcurl4-openssl-dev \
        libglib2.0-dev \
        libjansson-dev \
        libmicrohttpd-dev \
        libogg-dev \
        libopus-dev \
        libsofia-sip-ua-dev \
        libssl-dev \
        libtool \
        libwebsockets-dev \
        m4 \
        make \
        pkg-config \
        wget

RUN apt-get -y --no-install-recommends install \
        gdb \
        gdbserver \
        gtk-doc-tools \
        libasan5

## -----------------------------------------------------------------------------
## Install libnice 0.1.13 (signaling doesn't work in dev with newer versions)
## -----------------------------------------------------------------------------
RUN git clone https://gitlab.freedesktop.org/libnice/libnice \
    && cd libnice \
    && git checkout 0.1.13 \
    && ./autogen.sh \
    && ./configure \
    && make -j $(nproc) \
    && make install

## -----------------------------------------------------------------------------
## Install libsrtp (with --enable-openssl option)
## -----------------------------------------------------------------------------
ARG LIBSRTP_VERSION=2.3.0

RUN wget https://github.com/cisco/libsrtp/archive/v${LIBSRTP_VERSION}.tar.gz \
    && tar xfv v${LIBSRTP_VERSION}.tar.gz \
    && cd libsrtp-${LIBSRTP_VERSION} \
    && ./configure --prefix=/usr --enable-openssl \
    && make shared_library \
    && make install

## -----------------------------------------------------------------------------
## Build Paho MQTT client
## -----------------------------------------------------------------------------
ARG PAHO_MQTT_VERSION=1.3.4

RUN PAHO_MQTT_BUILD_DIR=$(mktemp -d) \
    && cd "${PAHO_MQTT_BUILD_DIR}" \
    && git clone "https://github.com/eclipse/paho.mqtt.c.git" . \
    && git checkout "v${PAHO_MQTT_VERSION}" \
    && make \
    && make install

## -----------------------------------------------------------------------------
## Build Janus Gateway
## -----------------------------------------------------------------------------
COPY ./janus-gateway/ /janus-gateway

RUN set -xe \
    && cd /janus-gateway \
    && CFLAGS="-g -O0" \
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
