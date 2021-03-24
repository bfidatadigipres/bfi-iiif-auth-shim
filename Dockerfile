FROM ubuntu:20.04 as module_build

RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get -y dist-upgrade \
    && apt-get -y install curl build-essential libpcre3 libpcre3-dev zlib1g zlib1g-dev libssl-dev

RUN curl -L http://nginx.org/download/nginx-1.17.8.tar.gz -o /tmp/nginx-1.17.8.tar.gz \
    && echo "97d23ecf6d5150b30e284b40e8a6f7e3bb5be6b601e373a4d013768d5a25965b /tmp/nginx-1.17.8.tar.gz" | sha256sum -c - \
    && tar xvfz /tmp/nginx-1.17.8.tar.gz -C /tmp

RUN curl -L https://github.com/openresty/headers-more-nginx-module/archive/refs/tags/v0.33.tar.gz -o /tmp/headers-more-nginx-module-0.33.tar.gz \
    && echo "a3dcbab117a9c103bc1ea5200fc00a7b7d2af97ff7fd525f16f8ac2632e30fbf /tmp/headers-more-nginx-module-0.33.tar.gz" | sha256sum -c - \
    && tar xvfz /tmp/headers-more-nginx-module-0.33.tar.gz -C /tmp

RUN cd /tmp/nginx-1.17.8 \
    && /tmp/nginx-1.17.8/configure \
        --prefix=/opt/nginx \
        --add-dynamic-module=/tmp/headers-more-nginx-module-0.33 \
        --with-compat \
    && make \
    && make install

FROM nginx:1.17.8
LABEL maintainer="Daniel Grant <daniel.grant@digirati.com>"
LABEL org.opencontainers.image.source=https://github.com/bfidatadigipres/bfi-iiif-auth-shim

COPY --from=module_build /opt/nginx/modules/ngx_http_headers_more_filter_module.so /etc/nginx/modules
RUN sed -i '1s/^/load_module \/etc\/nginx\/modules\/ngx_http_headers_more_filter_module.so;\n/' /etc/nginx/nginx.conf

COPY docker/usr/local/bin/entrypoint.sh /usr/local/bin
COPY docker/etc/nginx/conf.d/auth-shim.conf /etc/nginx/conf.d

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
