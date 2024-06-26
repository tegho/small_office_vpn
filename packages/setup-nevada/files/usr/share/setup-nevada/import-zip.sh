#!/bin/bash

import_file="$1"

if [ -z "$import_file" ] || [ ! -s "$import_file" ] ; then
  echo "No zip file specified or it is empty"
  exit 1
fi

tmp_dir=$(mktemp -d /tmp/impXXXXXX) && \
  chmod 700 "$tmp_dir" && \
  unzip "$import_file" -d "$tmp_dir" && \
  cp -f "${tmp_dir}/"*      /etc/openvpn/pki-montana && \
  rm -f "${tmp_dir}/ta.key" && \
  cp -f "${tmp_dir}/"*      /etc/nginx/pki-montana && \
  mv -f "${tmp_dir}/ca.crt" /etc/swanctl/x509ca && \
  mv -f "${tmp_dir}/"*.crt  /etc/swanctl/x509 && \
  mv -f "${tmp_dir}/"*.key  /etc/swanctl/private

rm -rf "$tmp_dir"
