#!/bin/bash
#
_keysdir='/opt/filer/os/pxe/keys'
#
_unsigned="${1}"
if [ "${_unsigned##*.}" = "unsigned" ]; then
  _signed="${_unsigned%.*}"
else
  _signed="${_unsigned}"
fi
# sign file
sbsign --key "${_keysdir}/DB.key" --cert "${_keysdir}/DB.crt" --output "${_signed}.signed" "${_unsigned}"
