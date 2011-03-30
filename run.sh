#!/bin/sh
exec 2>&1
export RIDGE_ENV=production
export PLACK_ENV=production
export SERVER_STATUS_CLASS=myapp
export APPROOT=/home/httpd/apps/myapp/releases
cd $APPROOT || exit 1

exec /usr/local/bin/start_server --port 80 -- \
    setuidgid apache \
    /usr/local/bin/plackup -s Starlet\
    --preload-app \
    --max-workers=10 \
    --max-reqs-per-child=10000 \
    -a script/app.psgi


