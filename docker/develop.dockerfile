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
      gdb \
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
RUN PAHO_MQTT_BUILD_DIR=$(mktemp -d) \
    && cd "${PAHO_MQTT_BUILD_DIR}" \
    && git clone "https://github.com/eclipse/paho.mqtt.c.git" . \
    && git checkout v1.3.0 \
    && make \
    && make install

    # WARGING: If you want to switch to Paho 1.1.0 pay attention that `make install`
    # works badly in that version on alpine. Use commands below instead:
    #
    # && cp ./build/output/libpaho* /usr/local/lib/ \
    # && ldconfig /usr/local/lib \
    # && mkdir -p /usr/local/include \
    # && cp ./src/MQTTAsync.h /usr/local/include/MQTTAsync.h \
    # && cp ./src/MQTTClient.h /usr/local/include/MQTTClient.h \
    # && cp ./src/MQTTClientPersistence.h /usr/local/include/MQTTClientPersistence.h
    
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
