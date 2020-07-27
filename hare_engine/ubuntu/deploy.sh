#!/usr/bin/env sh
# Conveen
# 07/15/2020

##########################################
##### Constants and Helper Functions #####
##########################################

PWD="$(pwd)"

log() {
    MESSAGE="${1}"
    LEVEL="${2:-INFO}"

    echo "::: ${LEVEL}: ${MESSAGE}"
}

print_usage() {
    echo "usage: [-h] [-d DEPLOY_DIR] [-g GEN_SECRET_KEY] [-s WITH_SERVICE] [-t TAG]"
    echo
    echo "optional arguments:"
    echo "-h, --help            show this help message and exit"
    echo "-d, --deploy-dir      directory to deploy hare to (default: /var/www/)"
    echo "-g, --gen-secret      whether to generate random secret key (default: false)"
    echo "-s, --with-service    whether to deploy uWSGI as a Systemd service (default: false)"
    echo "-t, --tag             the branch or tag to checkout from the Hare repo (default: master)"
}

##################################
##### Command Line Arguments #####
##################################

DEPLOY_DIR="/var/www/"
GEN_SECRET_KEY="false"
TAG="master"
WITH_SERVICE="false"

while [ $# -gt 0 ]
do
    case "${1}" in
        -h|--help)
            print_usage
            exit 0
            ;;
        -d|--deploy-dir)
            shift
            DEPLOY_DIR="${1}"
            shift
            ;;
        -g|--gen-secret)
            GEN_SECRET_KEY="true"
            shift
            ;;
        -s|--with-service)
            WITH_SERVICE="true"
            shift
            ;;
        -t|--tag)
            shift
            TAG="${1}"
            shift
            ;;
        *) break;;
    esac
done

########################
##### Script Block #####
########################

if [ ! -d "${DEPLOY_DIR}" ]
then
    log "Deployment directory ${DEPLOY_DIR} doesn't exist, creating it now"
    if (! $(mkdir -p "${DEPLOY_DIR}"))
    then
        log "Failed to create deployment directory" "ERROR"
        exit 1
    fi
fi
cd "${DEPLOY_DIR}"

log "Updating APT and installing dependencies"
apt update && \
    apt install -y build-essential git nginx python3 python3-pip python3-venv && \
    pip3 install uwsgi
if [ $? -ne 0 ]
then
    log "Failed to install dependencies" "ERROR"
    exit 1
fi

log "Cloning Hare from GitHub"
if (! git clone https://github.com/conveen/hare)
then
    log "Failed to clone Hare from GitHub" "ERROR"
    exit 1
fi
cd hare

log "Checking out branch or tag ${TAG}"
if (! git fetch origin "${TAG}" && git checkout "${TAG}" && git pull origin "${TAG}")
then
    log "Failed to checkout ${TAG}" "ERROR"
    exit 1
fi

log "Installing Python requirements"
python3 -m venv venv && \
    . venv/bin/activate && \
    pip install wheel && \
    pip install -r requirements.txt
if [ $? -ne 0 ]
then
    log "Failed to install Python requirements" "ERROR"
    exit 1
fi
if [ "${GEN_SECRET_KEY}" = "true" ]
then
    log "Generating random secret key"
    python -c "import secrets; print(secrets.token_hex(64))" > hare_engine/.app_secret.key
fi

log "Copying uWSGI and Nginx configurations to proper locations"
if (! cp ../wsgi/hare_engine.ini .)
then
    log "Failed to copy uWSGI ini file" "ERROR"
    exit 1
fi
if (! rm -f /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default)
then
    log "Failed to remove default Nginx config" "ERROR"
    exit 1
fi
if (! cp ../nginx/hare_engine.http.conf /etc/nginx/sites-available/hare_engine.conf)
then
    log "Failed to copy Nginx config file" "ERROR"
fi
if (! ln -s /etc/nginx/sites-available/hare_engine.conf /etc/nginx/sites-enabled/hare_engine.conf)
then
    log "Failed to enable Hare Nginx site" "ERROR"
    exit 1
fi

if [ "${WITH_SERVICE}" = "true" ]
then
    log "Enabling uWSGI service"
    cp service/hare_engine.service /lib/systemd/system && \
        systemctl daemon-reload && \
        systemctl enable hare_engine && \
        systemctl start hare_engine
    if [ $? -ne 0 ]
    then
        log "Failed to enable uWSGI service" "ERROR"
        exit 1
    fi
fi
