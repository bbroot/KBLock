#!/bin/bash
# Import the Developer ID Application certificate into a temporary keychain for
# CI signing. Reads base64 + password from the environment.
#
#   DEVELOPER_ID_CERT_BASE64   base64 of the .p12
#   DEVELOPER_ID_CERT_PASSWORD password for the .p12
#
# Leaves a keychain that codesign can use for the rest of the job.
set -euo pipefail

: "${DEVELOPER_ID_CERT_BASE64:?missing}"
: "${DEVELOPER_ID_CERT_PASSWORD:?missing}"

KEYCHAIN="$RUNNER_TEMP/lockime-signing.keychain-db"
KEYCHAIN_PASSWORD="$(openssl rand -base64 24)"
CERT_PATH="$RUNNER_TEMP/developer_id.p12"

echo "$DEVELOPER_ID_CERT_BASE64" | base64 --decode > "$CERT_PATH"

security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN"
security set-keychain-settings -lut 21600 "$KEYCHAIN"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN"

security import "$CERT_PATH" -P "$DEVELOPER_ID_CERT_PASSWORD" \
	-A -t cert -f pkcs12 -k "$KEYCHAIN"

# Allow codesign to use the key without an interactive prompt.
security set-key-partition-list -S apple-tool:,apple:,codesign: \
	-k "$KEYCHAIN_PASSWORD" "$KEYCHAIN" >/dev/null

# Put our keychain first in the search list so codesign finds the identity.
security list-keychains -d user -s "$KEYCHAIN" login.keychain-db

rm -f "$CERT_PATH"
echo "Imported Developer ID certificate into $KEYCHAIN"
