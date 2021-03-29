#!/bin/bash
########################################################
# Script name : entrypoint
# Description : Entrypoint for Authentication Shim.
# Author      : Daniel Grant <daniel.grant@digirati.com>
########################################################

set -o errexit

main() {
  show_motd
  prepare_conf
  prepare_symlinks
  run_nginx "$@"
}

log() {
  echo "[$(date +"%Y-%m-%d %H:%M:%S")] [${1}] ${2}"
}

log_info() {
  log "INFO" "${1}"
}

show_motd() {
  log_info "Starting BFI IIIF Authentication Shim..."
}

prepare_conf() {
  render_template "/etc/nginx/conf.d/auth-shim.conf" "\${SERVER_NAME} \${VIEWER_SCHEME} \${VIEWER_HOSTNAME} \${ENDPOINT_SCHEME} \${ENDPOINT_HOSTNAME} \${ENDPOINT_PORT} \${LOGGING_SCHEME} \${LOGGING_HOSTNAME} \${LOGGING_PORT} \${API_REQUEST_TYPE}"
}

prepare_symlinks() {
  mkdir -p "/etc/nginx/ssl"

  # /etc/nginx/ssl/bfi-iiif-root-ca.crt
  ln -sfv "/run/secrets/ssl/bfi-iiif-root-ca.crt" "/etc/nginx/ssl"

  # /etc/nginx/ssl/bk-ci-data4.dpi.bfi.org.uk.crt
  ln -sfv "/run/secrets/ssl/bk-ci-data4.dpi.bfi.org.uk.crt" "/etc/nginx/ssl"

  # /etc/nginx/ssl/bk-ci-data4.dpi.bfi.org.uk.key
  ln -sfv "/run/secrets/ssl/bk-ci-data4.dpi.bfi.org.uk.key" "/etc/nginx/ssl"
}

render_template() {
  local target=${1}
  local vars=${2}
  log_info "Rendering template '${target}'..."
  envsubst "${vars}" < "${target}" > "${target}.rendered" && rm "${target}" && mv "${target}.rendered" "${target}"
}

run_nginx() {
  log_info "Executing \"$*\"..."
  set -e
  exec "$@"
}

main "$@"
