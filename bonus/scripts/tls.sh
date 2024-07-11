#!/bin/bash
set -e
#############
## make and change into a working directory
pushd $(mktemp -d)

#############
## setup environment
NAMESPACE=${NAMESPACE:-default}
RELEASE=${RELEASE:-gitlab}
## stop if variable is unset beyond this point
set -u
## known expected patterns for SAN
CERT_SANS="*.${NAMESPACE}.svc,${RELEASE}-metrics.${NAMESPACE}.svc,*.${RELEASE}-gitaly.${NAMESPACE}.svc,gitlab.acetin.com"

#############
## generate default CA config
cfssl print-defaults config > ca-config.json
## generate a CA
echo '{"CN":"'${RELEASE}.${NAMESPACE}.internal.ca'","key":{"algo":"ecdsa","size":256}}' | \
  cfssl gencert -initca - | \
  cfssljson -bare ca -
## generate certificate
echo '{"CN":"'${RELEASE}.${NAMESPACE}.internal'","key":{"algo":"ecdsa","size":256}}' | \
  cfssl gencert -config=ca-config.json -ca=ca.pem -ca-key=ca-key.pem -profile www -hostname="${CERT_SANS}" - |\
  cfssljson -bare ${RELEASE}-services

#############
## load certificates into K8s
kubectl -n ${NAMESPACE} create secret tls ${RELEASE}-internal-tls \
  --cert=${RELEASE}-services.pem \
  --key=${RELEASE}-services-key.pem
kubectl -n ${NAMESPACE} create secret generic ${RELEASE}-internal-tls-ca \
  --from-file=ca.crt=ca.pem
