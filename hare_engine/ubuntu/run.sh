#!/usr/bin/env sh
# Conveen
# 07/15/2020

# Run uWSGI in daemon mode and start nginx in foreground
uwsgi -d --ini /var/www/hare/hare_engine.ini && \
    nginx -g 'daemon off;'
