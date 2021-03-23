FROM nginx:1.19.8
LABEL maintainer="Daniel Grant <daniel.grant@digirati.com>"
LABEL org.opencontainers.image.source=https://github.com/bfidatadigipres/bfi-iiif-auth-shim

COPY docker/usr/local/bin/entrypoint.sh /usr/local/bin
COPY docker/etc/nginx/conf.d/auth-shim.conf /etc/nginx/conf.d

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
