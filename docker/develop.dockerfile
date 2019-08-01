FROM netologygroup/janus-gateway:7959ab6 as janus-conference-plugin
FROM alpine:latest

## -----------------------------------------------------------------------------
## Install dependencies
## -----------------------------------------------------------------------------
RUN apk add --update --no-cache \
      # Build & debug tools
      build-base \
      gcc \
      git \
      autoconf \
      automake \
      libtool \
      curl-dev \
      # Janus Gateway dependencies
      libressl-dev \
      libsrtp-dev \
      libconfig-dev \
      libmicrohttpd-dev \
      jansson-dev \
      opus-dev \
      libogg-dev \
      libwebsockets-dev \
      gengetopt \
      libnice-dev \
      # Janus Conference plugin dependencies
      gstreamer-dev \
      gstreamer-tools \
      gst-plugins-base-dev \
      gst-plugins-good \
      gst-plugins-bad \
      gst-plugins-ugly \
      gst-libav \
      libnice-gstreamer \
      ffmpeg

## -----------------------------------------------------------------------------
## Build Paho MQTT client
## -----------------------------------------------------------------------------
ARG PAHO_MQTT_VERSION=1.3.0

RUN PAHO_MQTT_BUILD_DIR=$(mktemp -d) \
    && cd "${PAHO_MQTT_BUILD_DIR}" \
    && git clone "https://github.com/eclipse/paho.mqtt.c.git" . \
    && git checkout "v${PAHO_MQTT_VERSION}" \
    && make \
    && make install \
    && rm -rf "${PAHO_MQTT_BUILD_DIR}"

## -----------------------------------------------------------------------------
## Build Janus Gateway
## -----------------------------------------------------------------------------
COPY ./janus-gateway/ /janus-gateway

RUN set -xe \
    && cd /janus-gateway \
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
