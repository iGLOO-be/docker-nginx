
# Docker NGINX

## Modules

- [headers-more-nginx-module](https://github.com/openresty/headers-more-nginx-module)
- [ngx_http_substitutions_filter_module](https://github.com/yaoweibin/ngx_http_substitutions_filter_module)
- [echo-nginx-module](https://github.com/openresty/echo-nginx-module)
- [nginx_upstream_check_module](https://github.com/yaoweibin/nginx_upstream_check_module)
- [ngx_pagespeed](https://github.com/pagespeed/ngx_pagespeed)

## Pull

```
docker pull igloo/nginx
```
Tags: https://hub.docker.com/r/igloo/nginx/tags/

## Run

```
docker run --rm -ti \
  --name nginx \
  -p 80:80 -p 443:443 \
  -v pathConfig:/etc/nginx/conf.d \
  igloo/nginx
```
