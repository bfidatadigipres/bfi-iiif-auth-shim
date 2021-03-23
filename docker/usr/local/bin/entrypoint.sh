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
  render_template "/etc/nginx/conf.d/auth-shim.conf" "\${SERVER_NAME} \${ENDPOINT_SCHEME} \${ENDPOINT_HOSTNAME} \${ENDPOINT_PORT} \${LOGGING_SCHEME} \${LOGGING_HOSTNAME} \${LOGGING_PORT} \${API_REQUEST_TYPE}"
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
