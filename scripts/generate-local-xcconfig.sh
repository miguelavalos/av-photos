#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
profile="${1:-local}"
output_mode="${2:-write}"

case "$profile" in
  local)
    bundle_identifier="com.avalsys.avphotos.dev"
    ;;
  production)
    bundle_identifier="com.avalsys.avphotos"
    ;;
  *)
    echo "Unsupported profile: $profile" >&2
    exit 1
    ;;
esac

eval "$("$repo_root/scripts/resolve-infisical-bootstrap-env.sh" "$profile")"

varlock_bin="$repo_root/node_modules/.bin/varlock"

if [ ! -x "$varlock_bin" ]; then
  echo "varlock CLI is required. Run 'bun install' in $repo_root." >&2
  exit 1
fi

printenv_value() {
  local key="$1"
  "$varlock_bin" printenv --path "$repo_root/" "$key" 2>/dev/null || true
}

xcodebuild_url_value() {
  local value="$1"
  printf '%s' "$value" | sed 's#//#/$()/#g'
}

clerk_publishable_key="$(printenv_value CLERK_PUBLISHABLE_KEY)"
avapps_auth_token="$(printenv_value AVAPPS_AUTH_TOKEN)"
avapps_api_base_url="$(printenv_value AVPHOTOS_AVAPPS_API_BASE_URL)"
support_email="$(printenv_value AVPHOTOS_SUPPORT_EMAIL)"
account_management_url="$(printenv_value AVPHOTOS_ACCOUNT_MANAGEMENT_URL)"
terms_url="$(printenv_value AVPHOTOS_TERMS_URL)"
privacy_url="$(printenv_value AVPHOTOS_PRIVACY_URL)"
open_source_url="$(printenv_value AVPHOTOS_OPEN_SOURCE_URL)"

if [ -z "${open_source_url:-}" ]; then
  open_source_url="https://github.com/miguelavalos/av-photos"
fi

rendered_config="$(cat <<EOF
AVPHOTOS_BUNDLE_IDENTIFIER = $bundle_identifier
CLERK_PUBLISHABLE_KEY = $clerk_publishable_key
AVAPPS_AUTH_TOKEN = ${avapps_auth_token:-}
AVPHOTOS_AVAPPS_API_BASE_URL = ${avapps_api_base_url:-}
AVPHOTOS_SUPPORT_EMAIL = ${support_email:-}
AVPHOTOS_ACCOUNT_MANAGEMENT_URL = $(xcodebuild_url_value "${account_management_url:-}")
AVPHOTOS_TERMS_URL = $(xcodebuild_url_value "${terms_url:-}")
AVPHOTOS_PRIVACY_URL = $(xcodebuild_url_value "${privacy_url:-}")
AVPHOTOS_OPEN_SOURCE_URL = $(xcodebuild_url_value "$open_source_url")
EOF
)"

target_file="$repo_root/apps/ios/Config/Local.xcconfig"

case "$output_mode" in
  write)
    umask 077
    printf '%s\n' "$rendered_config" > "$target_file"
    echo "Wrote $target_file for profile '$profile'."
    ;;
  stdout)
    printf '%s\n' "$rendered_config"
    ;;
  *)
    echo "Unsupported output mode: $output_mode" >&2
    exit 1
    ;;
esac
