FROM python:3.12
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
	apt update && \
	apt upgrade && \
	apt install -y \
		bash \
		coreutils \
		cron \
		curl \
		ca-certificates \
		certbot \
		mosquitto \
		mosquitto-clients \
		libmosquitto-dev \
		mosquitto-dev \
		make \
		sed \
		golang \
		python3-cryptography && \
	rm -rf /var/cache/apt/* && \
	rm /build_internal.sh && \
	pip install --upgrade pip && \
	pip install pyRFC3339 configobj ConfigArgParse

# Download, build and install the mosquitto-go-auth plugin
# Its Makefile requires a fix to add -D_LARGEFILE64_SOURCE in order to fix a compile issue
RUN wget https://github.com/iegomez/mosquitto-go-auth/archive/refs/tags/2.1.0.zip && \
	unzip 2.1.0.zip && \
	cd mosquitto-go-auth-2.1.0 && \
	make && \
	chmod +x pw && \
	cp go-auth.so go-auth.h pw /mosquitto/ && \
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
