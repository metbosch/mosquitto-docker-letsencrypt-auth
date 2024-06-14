#!/bin/bash

## Copy certificates to /mosquitto
cp -v /etc/letsencrypt/live/${DOMAIN}/chain.pem /mosquitto/certs/chain.pem
cp -v /etc/letsencrypt/live/${DOMAIN}/fullchain.pem /mosquitto/certs/fullchain.pem
cp -v /etc/letsencrypt/live/${DOMAIN}/privkey.pem /mosquitto/certs/privkey.pem

## Set ownership and restrictive permissions
chown mosquitto: /mosquitto/certs/chain.pem /mosquitto/certs/fullchain.pem /mosquitto/certs/privkey.pem
chmod 0600 /mosquitto/certs/chain.pem /mosquitto/certs/fullchain.pem /mosquitto/certs/privkey.pem

if [ -e /var/run/s6/services/mosquitto ]; then
	/bin/s6-svc -r /var/run/s6/services/mosquitto
fi
