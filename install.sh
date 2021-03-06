#!/usr/bin/env bash

set -e

##################
# VARS
##################

if [ -z $NGINX_VERSION ]
then
  echo 'NGINX_VERSION is undefined'
  exit 1
fi

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

vHEADERSMORE=${HEADERSMORE_VERSION:-"0.30"}
vNGINXFILTER=${FILTER_VERSION:-"0.6.4"}
vNGINXECHO=${ECHO_VERSION:-"0.59"}
vNGINXPAGESPEED=${NPS_VERSION:-"1.11.33.2"}
vUPSTREAM_PATCH=${UPSTREAM_PATCH_VERSION:-"1.11.5+"}

NGINXPKG="http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz"
NGINXHEADERSMORE="https://github.com/openresty/headers-more-nginx-module/archive/v${vHEADERSMORE}.tar.gz"
NGINXFILTER="https://github.com/yaoweibin/ngx_http_substitutions_filter_module/archive/v${vNGINXFILTER}.tar.gz"
NGINXECHO="https://github.com/openresty/echo-nginx-module/archive/v${vNGINXECHO}.tar.gz"
NGINXUPSTREAM="https://github.com/yaoweibin/nginx_upstream_check_module.git"
NGINXPAGESPEED="https://github.com/pagespeed/ngx_pagespeed/archive/v${vNGINXPAGESPEED}-beta.tar.gz"

##################
# FCT
##################

function getPackage() {
  echo "Get package $2 $1"
  mkdir $2
  curl -L# $1 | tar -zx --strip 1 -C $2
}

##################
# BEGIN
##################

cd
mkdir -p nginx_install && cd nginx_install

# Install pkgs
apt-get -qq update && \
apt-get -qq install -y \
  curl build-essential libpcre3-dev libgeoip-dev libssl-dev \
  git \
  zlib1g-dev libpcre3 unzip

# Get nginx and prepare modules
getPackage $NGINXPKG nginx
getPackage $NGINXHEADERSMORE headersmore
getPackage $NGINXFILTER substitution
getPackage $NGINXECHO nginxecho
git clone $NGINXUPSTREAM `pwd`/nginxupstream
getPackage $NGINXPAGESPEED nginxpagespeed

cd nginxpagespeed
wget --quiet https://dl.google.com/dl/page-speed/psol/${vNGINXPAGESPEED}.tar.gz
tar -xzf ${vNGINXPAGESPEED}.tar.gz
cd ..

# Build
cd nginx
/usr/bin/patch -p0 < ../nginxupstream/check_${vUPSTREAM_PATCH}.patch && \
./configure --with-cc-opt='-g -O2 -fstack-protector --param=ssp-buffer-size=4 -Wformat -Wformat-security -Werror=format-security -D_FORTIFY_SOURCE=2' \
--with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro' \
--prefix=/usr/share/nginx \
--conf-path=/etc/nginx/nginx.conf \
--http-log-path=/var/log/nginx/access.log \
--error-log-path=/var/log/nginx/error.log \
--lock-path=/var/lock/nginx.lock \
--pid-path=/run/nginx.pid \
--with-debug \
--with-pcre-jit \
--with-ipv6 \
--with-http_ssl_module \
--with-http_stub_status_module \
--with-http_realip_module \
--with-http_auth_request_module \
--with-http_gzip_static_module \
--without-http_browser_module \
--without-http_geo_module \
--without-http_memcached_module \
--without-http_referer_module \
--without-http_scgi_module \
--without-http_split_clients_module \
--without-http_ssi_module \
--without-http_userid_module \
--without-http_uwsgi_module \
--add-module=../headersmore/ \
--add-module=../substitution/ \
--add-module=../nginxecho/ \
--add-module=../nginxupstream/ \
--add-module=../nginxpagespeed/ \
--with-http_flv_module \
--with-mail \
--with-http_geoip_module \
--with-http_v2_module && \
make && make install

STATUS=$?

if [ $STATUS -eq 0 ]
then

  cp -r $DIR/nginx-install/geoip /etc/nginx/
  cp $DIR/nginx-install/nginx-logrotate /etc/logrotate.d/nginx
  mkdir -p /etc/nginx/conf.d

  # Clean install directory
  rm -rf $HOME/nginx_install

  echo 'NGINX VERSION: ' && `/usr/share/nginx/sbin/nginx -v`
else
  echo "Error... ($STATUS)"
  exit $STATUS
fi

exit 0
