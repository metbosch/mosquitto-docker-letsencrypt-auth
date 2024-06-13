FROM python:3.12-alpine3.20
LABEL maintainer metbosch https://github.com/metbosch

# Set environment variables.
ENV TERM=xterm-color
ENV SHELL=/bin/bash
# Use a shell script to select the right s6-overlay installer for the processor architecture
WORKDIR /
COPY ./build_internal.sh /build_internal.sh
RUN /build_internal.sh
# Choose needed packages.
RUN \
	mkdir /mosquitto && \
	mkdir /mosquitto/log && \
	mkdir /mosquitto/conf && \
	apk update && \
	apk upgrade && \
	apk add \
		bash \
		coreutils \
		curl \
		py3-crypto \
		ca-certificates \
		certbot \
		mosquitto \
		mosquitto-clients \
		mosquitto-dev \
		make \
		sed \
		go && \
	rm -f /var/cache/apk/* && \
	rm /build_internal.sh && \
	pip install --upgrade pip && \
	pip install pyRFC3339 configobj ConfigArgParse

# Download, build and install the mosquitto-go-auth plugin
# Its Makefile requires a fix to add -D_LARGEFILE64_SOURCE in order to fix a compile issue
RUN wget https://github.com/iegomez/mosquitto-go-auth/archive/refs/tags/2.1.0.zip && \
	unzip 2.1.0.zip && \
	cd mosquitto-go-auth-2.1.0 && \
	sed -i '/^CFLAGS :=/ s/$/ -D_LARGEFILE64_SOURCE/' Makefile && \
	sed -i 's/env CGO_LDFLAGS="$(LDFLAGS)"/env CGO_LDFLAGS="$(LDFLAGS)" CGO_CFLAGS="$(CFLAGS)"/g' Makefile && \
	make && \
	cp go-auth.so go-auth.h /mosquitto/ && \
	cd - && \
	rm -rf mosquito-go-auth-2.1.0 mosquito-go-auth-2.1.0.zip

COPY etc /etc
COPY certbot.sh /certbot.sh
COPY restart.sh /restart.sh
COPY croncert /etc/periodic/weekly/croncert
RUN \
	chmod +x /certbot.sh && \
	chmod +x /restart.sh && \
	chmod +x /etc/periodic/weekly/croncert

ENTRYPOINT ["/init"]
