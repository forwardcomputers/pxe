#!/bin/bash
#
# Requires openssl, efitools, sbsigntool(s)
#
if [[ "$OSTYPE" == "darwin"* ]]; then
  echo "Need to run in Linux"
  exit
fi
#
_rootdir='/opt/filer/os/pxe/keys'
# create openssl config file
# from https://ubuntu.com/blog/how-to-sign-things-for-secure-boot
cat > /tmp/openssl.cnf << EOF
# This definition stops the following lines choking if HOME isn't defined.
HOME                    = .
RANDFILE                = \$ENV::HOME/.rnd

[ ca ]
default_ca              = CA_default

[ CA_default ]
default_md              = sha256

[ req ]
distinguished_name      = req_distinguished_name
x509_extensions         = v3_ca
string_mask             = utf8only
prompt                  = no
default_bits            = 2048

[ req_distinguished_name ]
commonName              = Forward Computers

[ v3_ca ]
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid:always,issuer
basicConstraints        = critical,CA:FALSE
EOF
#
_guid=$( uuidgen -r )
echo "${_guid}" > "${_rootdir}/GUID.txt"
#
for _keytype in DB KEK PK; do
  _dir="${_rootdir}/${_keytype}"
# create private and public keys
  openssl req -config /tmp/openssl.cnf -new -x509 -days 36500 -newkey rsa -nodes -keyout "${_dir}.key" -out "${_dir}.crt"
  cert-to-efi-sig-list -g "${_guid}" "${_dir}.crt" "${_dir}.esl"
  openssl x509 -outform DER -in "${_dir}.crt" -out "${_dir}.cer"
done
#
rm -f noPK.esl 2>/dev/nul
touch noPK.esl
sign-efi-sig-list -t "$(date --date='1 second' +'%Y-%m-%d %H:%M:%S')" \
                  -k "${_rootdir}/PK.key" -c "${_rootdir}/PK.crt" PK "${_rootdir}/PK.esl" "${_rootdir}/PK.auth"
sign-efi-sig-list -t "$(date --date='1 second' +'%Y-%m-%d %H:%M:%S')" \
                  -k "${_rootdir}/PK.key" -c "${_rootdir}/PK.crt" PK "${_rootdir}/noPK.esl" "${_rootdir}/noPK.auth"
sign-efi-sig-list -t "$(date --date='1 second' +'%Y-%m-%d %H:%M:%S')" \
                  -k "${_rootdir}/PK.key" -c "${_rootdir}/PK.crt" PK "${_rootdir}/KEK.esl" "${_rootdir}/KEK.auth"
sign-efi-sig-list -t "$(date --date='1 second' +'%Y-%m-%d %H:%M:%S')" \
                  -k "${_rootdir}/KEK.key" -c "${_rootdir}/KEK.crt" PK "${_rootdir}/DB.esl" "${_rootdir}/DB.auth"
#
# echo
# echo "KeyTool uses the *.auth and *.esl files"
# echo "UEFI built-in key managers use the *.cer or *.auth files"
# echo
