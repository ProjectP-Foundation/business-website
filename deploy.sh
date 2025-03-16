#!/bin/bash

# Configuration variables
SERVER_USERNAME="ubuntu"
SERVER_HOST="110.40.152.53"
HUGO_LOCAL_PATH="./public"
HUGO_SERVER_PATH="/home/ubuntu/business-website"

# Log function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Build and deploy Hugo site
log "Starting Hugo build..."
hugo --minify

if [ ! -d "$HUGO_LOCAL_PATH" ]; then
    log "Error: Hugo build directory does not exist"
    exit 1
fi

log "Starting Hugo site deployment..."
rsync -avz --delete --stats --human-readable \
    -e "ssh -o StrictHostKeyChecking=no" \
    $HUGO_LOCAL_PATH/ $SERVER_USERNAME@$SERVER_HOST:$HUGO_SERVER_PATH

if [ $? -ne 0 ]; then
    log "Hugo site deployment failed!"
    exit 1
fi
log "Hugo site deployment successful!"
exit 0