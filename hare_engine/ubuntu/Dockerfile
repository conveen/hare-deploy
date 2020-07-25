# Conveen
# 07/13/2020

# Ubuntu 18.04 LTS
FROM ubuntu:bionic

# tag: branch or tag name to use
ARG tag=master

# Switch to installation directory
WORKDIR /var/www

# Let Ubuntu know the shell session won't be interactive
# See: https://www.mankier.com/7/debconf#noninteractive
ENV DEBIAN_FRONTEND noninteractive

# Ensure apt is up to date
RUN apt-get update

# Install the following dependencies:
#   1) git: clone and setup the Hare repo
#   2) nginx: uwsgi reverse proxy
#   3) python3 (3.6.9): required by Hare to run Flask
#   4) python3-pip: required for installing Hare Python dependencies
#   5) python3-venv: Python virtual environment
RUN apt-get install -y build-essential git nginx python3 python3-pip python3-venv && \
    pip3 install uwsgi

# Clone Hare from GitHub
RUN git clone https://github.com/conveen/hare.git

# Switch to Hare root directory
WORKDIR /var/www/hare

# Fetch and checkout the desired branch or tag
RUN git fetch origin $tag && \
    git checkout $tag

# Install requirements and generate random 64-byte hex secret key 
# TODO: Enable setting secret key form env variable (i.e., secret manager)
RUN python3 -m venv venv && \
    . venv/bin/activate && \
    pip install wheel && \
    pip install -r requirements.txt && \
    python -c "import secrets; print(secrets.token_hex(64))" > hare_engine/.app_secret.key

# Copy uWSGI configuration to container
COPY wsgi/hare_engine.ini /var/www/hare

# Remove default Nginx site configuration
RUN rm -rf /etc/nginx/sites-enabled/default && rm -rf /etc/nginx/sites-available/default

# Copy Nginx configuration to sites-available and enable it
COPY nginx/hare_engine.http.conf /etc/nginx/sites-available/hare_engine.conf
RUN ln -s /etc/nginx/sites-available/hare_engine.conf /etc/nginx/sites-enabled/hare_engine.conf

# Copy entrypoint to container
COPY docker_run.sh .

# Change ownership of hare directory to www-data
RUN chown -R www-data:www-data /var/www/hare

ENTRYPOINT ["./docker_run.sh"]
