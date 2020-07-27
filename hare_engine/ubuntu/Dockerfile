# Conveen
# 07/13/2020

# Ubuntu 18.04 LTS
FROM ubuntu:bionic

# See: deploy.sh
ARG TAG=master

# Let Ubuntu know the shell session won't be interactive
# See: https://www.mankier.com/7/debconf#noninteractive
ENV DEBIAN_FRONTEND noninteractive

WORKDIR /var/www

# Copy deployment script and supporting files to container
COPY deploy.sh .
RUN mkdir wsgi nginx
COPY wsgi/hare_engine.ini wsgi/
COPY nginx/hare_engine.http.conf nginx/

# Run deployment script with provided tag
RUN ./deploy.sh -t $TAG -g

# Copy entrypoint to container
COPY docker_run.sh .

# Change ownership of hare directory to www-data
RUN chown -R www-data:www-data /var/www/hare

ENTRYPOINT ["./docker_run.sh"]
