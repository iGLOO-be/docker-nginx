#!/usr/bin/env bash

set -e
nginx && tail -f /var/log/nginx/access.log /var/log/nginx/error.log
