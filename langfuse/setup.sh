#!/bin/bash
set -Eeuo pipefail

# Fills the blank secrets in .env with generated values. Idempotent: a variable
# that already has a value is never touched, so this is safe to re-run and safe
# to run against a live deployment.
#
# No generated value is ever printed, echoed, or passed as a command argument -
# values move from openssl into the file through the environment, so they stay
# out of the terminal, out of shell history, and out of `ps`. The script reports
# which variables it filled, never what it filled them with.
#
# Usage:
#   ./setup.sh            fill the secrets only
#   ./setup.sh --dev      also set the two addresses to their localhost values

DEV=0
case "${1:-}" in
  --dev) DEV=1 ;;
  '') ;;
  *)
    echo "usage: $0 [--dev]" >&2
    exit 1
    ;;
esac

# --- .env ----------------------------------------------------------------

if [ ! -f .env ]; then
  cp .env.sample .env
  echo "==> Created .env from .env.sample."
fi

# Secrets land here, so keep it to the owner.
chmod 600 .env

# --- helpers -------------------------------------------------------------

# Is the variable missing, or present but empty?
is_blank() {
  ! grep -qE "^$1=.+" .env
}

# Set a variable from the environment rather than from an argument. awk reads
# it with ENVIRON, so the value never appears in argv where `ps` could see it.
# Appends the line if the variable is absent entirely.
set_from_env() {
  local key="$1" tmp
  tmp="$(mktemp)"
  if grep -qE "^${key}=" .env; then
    KEY="${key}" awk '
      BEGIN { k = ENVIRON["KEY"] }
      $0 ~ "^" k "=" { print k "=" ENVIRON["VALUE"]; next }
      { print }
    ' .env >"${tmp}"
  else
    cp .env "${tmp}"
    KEY="${key}" awk 'BEGIN { print ENVIRON["KEY"] "=" ENVIRON["VALUE"] }' >>"${tmp}"
  fi
  cat "${tmp}" >.env
  rm -f "${tmp}"
}

# Reads the value of a variable already in .env. Used only to assemble
# DATABASE_URL; the value is never printed.
value_of() {
  sed -n "s/^$1=//p" .env | head -1
}

filled=()
kept=()

generate() {
  local key="$1" kind="$2"
  if is_blank "${key}"; then
    case "${kind}" in
      hex16) VALUE="$(openssl rand -hex 16)" ;;
      hex32) VALUE="$(openssl rand -hex 32)" ;;
      b64) VALUE="$(openssl rand -base64 32)" ;;
    esac
    export VALUE
    set_from_env "${key}"
    unset VALUE
    filled+=("${key}")
  else
    kept+=("${key}")
  fi
}

# --- secrets -------------------------------------------------------------

# Formats are not interchangeable. ENCRYPTION_KEY must be exactly 64 hex
# characters or Langfuse refuses to start. The datastore passwords are hex
# rather than base64 so they survive being embedded in DATABASE_URL without
# percent-encoding - base64 can contain / and +, which are not URL-safe.
generate SALT b64
generate ENCRYPTION_KEY hex32
generate NEXTAUTH_SECRET b64
generate POSTGRES_PASSWORD hex16
generate CLICKHOUSE_PASSWORD hex16
generate REDIS_AUTH hex16
generate S3_SECRET_KEY hex16

# --- DATABASE_URL --------------------------------------------------------

# Assembled rather than generated, because it has to agree with the Postgres
# variables. This is the value most likely to drift out of sync by hand.
if is_blank DATABASE_URL; then
  pg_user="$(value_of POSTGRES_USER)"
  pg_db="$(value_of POSTGRES_DB)"
  VALUE="postgresql://${pg_user:-langfuse}:$(value_of POSTGRES_PASSWORD)@postgres:5432/${pg_db:-langfuse}"
  export VALUE
  set_from_env DATABASE_URL
  unset VALUE
  filled+=(DATABASE_URL)
else
  kept+=(DATABASE_URL)
fi

# --- addresses -----------------------------------------------------------

if [ "${DEV}" = 1 ]; then
  for pair in "NEXTAUTH_URL=http://localhost:3000" "S3_PUBLIC_URL=http://localhost:8333"; do
    key="${pair%%=*}"
    if is_blank "${key}"; then
      VALUE="${pair#*=}"
      export VALUE
      set_from_env "${key}"
      unset VALUE
      filled+=("${key}")
    else
      kept+=("${key}")
    fi
  done
fi

# --- report --------------------------------------------------------------

echo
[ ${#filled[@]} -gt 0 ] && printf '==> Generated: %s\n' "${filled[*]}"
[ ${#kept[@]} -gt 0 ] && printf '==> Already set, left alone: %s\n' "${kept[*]}"

still_blank=()
for key in NEXTAUTH_URL S3_PUBLIC_URL; do
  is_blank "${key}" && still_blank+=("${key}")
done

if [ ${#still_blank[@]} -gt 0 ]; then
  echo
  echo "==> Still needs a value: ${still_blank[*]}"
  echo "    Dev:     ./setup.sh --dev  sets them to localhost"
  echo "    Traefik: NEXTAUTH_URL=https://\$DOMAIN and S3_PUBLIC_URL=https://\$S3_DOMAIN,"
  echo "             and set DOMAIN and S3_DOMAIN to two hostnames pointing here."
fi

echo
echo "Values were not printed. To confirm nothing is empty without revealing"
echo "anything, check that this lists no variables:"
echo "  grep -E '^[A-Z_]+=\$' .env"
