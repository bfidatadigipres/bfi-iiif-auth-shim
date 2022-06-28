# BFI - IIIF Authentication Shim

## Introduction

This project contains an "authentication shim", designed to act as a
proxy between consumers of resources and the underlying services
providing those resources. The intention is to ensure that all access to
those resources are both authenticated, and logged for long term
auditing.

The project makes use of [NGINX](https://www.nginx.com/), operating as a
[reverse proxy](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/)
with the
[`ngx_http_auth_request_module`](https://nginx.org/en/docs/http/ngx_http_auth_request_module.html)
providing authentication checks against the [BFI IIIF Logging
platform](https://github.com/bfidatadigipres/bfi-iiif-logging/) which,
as part of that check, logs the resource being accessed into the audit
log.

Additionally, the project utilises the
[`ngx_headers_more`](https://github.com/openresty/headers-more-nginx-module)
module, allowing HTTP headers to not only be appended (as per NGINX's
own `add_header` functionality), but replaced and remove too.

Deployment NOTE: this is deployed in the IIIF server not the Load Balancer server

## Getting Started

### Repository Layout

The repository is split into the following components:

- [`Dockerfile`](Dockerfile) and [`docker/`](docker/)
  - This image is responsible for retrieving and building the
    `ngx_headers_more` module, and providing it to the underlying NGINX
    image, along with various other customisations provided within the
    [`docker/`](docker/) directory.
  - A running instance of the container requires a number of environment
    variables to be provided, containing the necessary configuration.
- [`deploy/`](deploy/)
  - Contains the folder structure and configuration files required to
    deploy the authentication shim. Specifically:
    - [`/etc/opt/bfi/iiif-auth-shim/<environment>_<type>/`](deploy/etc/opt/bfi/iiif-auth-shim/%3Cenvironment%3E/%3Ctype%3E):
      contains configuration files and assets used by the authentication
      shim.
    - [`/etc/systemd/system/<environment>-<type>-iiif-auth-shim.service`](deploy/etc/systemd/system/<environment>-<type>-iiif-auth-shim.service):
      the systemd unit used for starting and stopping the underlying
      authentication shim.
    - [`/opt/bfi/iiif-auth-shim/<environment>_<type>/docker-compose.yml`](deploy/opt/bfi/iiif-auth-shim/%3Cenvironment%3E_%3Ctype%3E/docker-compose.yml):
      the Docker Compose manifest, defining the authentication shim
      application, dependencies and relationships therein.

### Secrets Management

All secrets checked in as part of the repository have been encrypted
using [git-secret.io](https://git-secret.io/). This includes the
contents of the
[`ssl`](https://github.com/bfidatadigipres/bfi-iiif-auth-shim/blob/master/ssl)
directory, which contains various SSL / TLS related certificates and
keys.

Existing users who already exist in the keyring can decrypt secrets with
the following command:

```bash
git secret reveal
```

To decrypt secrets, you must first be added to the keyring by an
existing user (assuming a key for `some.user@example.com` already exists
in your local GPG keyring):

```bash
git secret reveal
git secret tell some.user@example.com
git secret hide
```

New secrets can be added with the following commands:

```bash
git secret add path/to/my/secret.txt
git secret hide
```

### Building

[![build](https://github.com/bfidatadigipres/bfi-iiif-auth-shim/actions/workflows/build.yml/badge.svg)](https://github.com/bfidatadigipres/bfi-iiif-auth-shim/actions/workflows/build.yml)

The [`Dockerfile`](Dockerfile) can be built by executing:

```bash
docker build -t bfi-iiif-auth-shim .
```

## Local Development

A Docker Component manifest
[`docker-compose.dev.yml`](docker-compose.dev.yml) is provided for
facilitate local development.

This manifest requires that the secrets
[`ssl/bfi-iiif-root-ca.crt`](ssl/bfi-iiif-root-ca.crt),
[`ssl/bk-ci-data4.dpi.bfi.org.uk.crt`](ssl/bk-ci-data4.dpi.bfi.org.uk.crt)
,
[`ssl/bk-ci-data4.dpi.bfi.org.uk.key`](ssl/bk-ci-data4.dpi.bfi.org.uk.key)
and [`ssl/dhparam.pem`](ssl/dhparam.pem) are available (i.e. has been
decrypted), as it is made available to the running container as a Docker
Compose secret.

```bash
git secret reveal
docker-compose -f docker-compose.dev.yml up --remove-orphans
```

The manifest deploys an instance of the authentication shim for both a
manifest resource server and an image resource server.

## Deployment

### Prerequisites

The application requires Docker and Docker Compose. It is recommended
that these are installed from the official Docker repositories:

- https://docs.docker.com/engine/install/
- https://docs.docker.com/compose/install/

The application deployment should mirror the contents of the
[`deploy/`](deploy/) directory. Start by creating the necessary
directories:

### Deploy Configuration

Deployments are scoped to a specific environment, e.g. `DEV`, `UAT`,
`PROD`, etc, and by the resource server type, e.g. `image`, `manifest`,
etc. The environment and type are defined in both the paths to the
installation configuration (i.e. `<environment>` and `<type>`) and in
the `config.env` configuration file.

```bash
sudo -i
mkdir -p /etc/opt/bfi/iiif-auth-shim/<environment>_<type>/ssl
mkdir -p /opt/bfi/iiif-auth-shim/<environment>_<type>
```

Deploy BFI's IIIF root certificate authority, and the SSL certificates:

```bash
cp bfi-iiif-root-ca.crt /etc/opt/bfi/iiif-auth-shim/<environment>_<type>/ssl
cp bk-ci-data4.dpi.bfi.org.uk.crt /etc/opt/bfi/iiif-auth-shim/<environment>_<type>/ssl
cp bk-ci-data4.dpi.bfi.org.uk.key /etc/opt/bfi/iiif-auth-shim/<environment>_<type>/ssl
cp dhparam.pem /etc/opt/bfi/iiif-auth-shim/<environment>_<type>/ssl
```

Update
[`/etc/opt/bfi/iiif-auth-shim/<environment>_<type>/config.env`](deploy/etc/opt/bfi/iiif-auth-shim/<environment>_<type>/config.env)
to set the desired configuration:

```text
ENVIRONMENT=prod
AUTH_SHIM_IMAGE_TAG=1.0.0
AUTH_SHIM_PORT=443
SERVER_NAME=<RESOURCE_SERVER_HOSTNAME>
VIEWER_SCHEME=<UNIVERSAL_VIEWER_SCHEME>
VIEWER_HOSTNAME=<UNIVERSAL_VIEWER_HOSTNAME>
ENDPOINT_SCHEME=<RESOURCE_SERVER_SCHEME>
ENDPOINT_HOSTNAME=<RESOURCE_SERVER_HOSTNAME>
ENDPOINT_PORT=<RESOURCE_SERVER_PORT>
LOGGING_SCHEME=<LOGGING_PLATFORM_SCHEME>
LOGGING_HOSTNAME=<LOGGING_PLATFORM_HOSTNAME>
LOGGING_PORT=<LOGGING_PLATFORM_PORT>
API_REQUEST_TYPE=<manifest|image>
```

Add the Docker Compose manifest:

```bash
cp docker-compose.yml /opt/bfi/iiif-auth-shim/<environment>_<type>
```

Add the systemd unit:

```bash
cp <environment>-<type>=iiif-auth-shim.service /etc/systemd/system
```

### Start Load Balancer

Enable the systemd unit to start at boot:

```bash
systemctl enable <environment>-<type>=iiif-auth-shim
```

Start the load balancer:

```bash
systemctl start <environment>-<type>=iiif-auth-shim
```

The authentication shim instance can now be accessed on port `443`.

## Contributors

[![contributors](https://contrib.rocks/image?repo=bfidatadigipres/bfi-iiif-auth-shim)](https://github.com/bfidatadigipres/bfi-iiif-auth-shim/graphs/contributors)

## Versioning

We use SemVer for versioning. For the versions available, see the [tags
on this repository](https://github.com/bfidatadigipres/bfi-iiif-auth-shim/tags).

## License

This project is licensed under the MIT license - see the
[`LICENSE`](LICENSE) file for details.
