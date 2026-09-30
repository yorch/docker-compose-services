#!/usr/bin/env bash
set -Eeuo pipefail

# --- usage ---
# Create or update a service's .env from its .env.sample.
#
#   ./setup-env.sh <service> [<service>...]   one or more service folders
#   ./setup-env.sh --all                      every service that has a .env.sample
#   ./setup-env.sh --check [<service>...]     report without writing anything
# --- end usage ---
#
# What it does, per service:
#   1. copies .env.sample to .env when .env is missing
#   2. fills BLANK values for keys this repo generates itself (database
#      passwords, session secrets, encryption keys) with `openssl rand`
#   3. leaves every third-party credential blank - a generated Google or Slack
#      client secret is worse than a blank one, because it looks filled in
#   4. reports which keys still need a value, so a human knows what to paste
#   5. replaces a key still holding the sample's placeholder (e.g. the `12345`
#      several samples ship) ONLY when the service has never run, and only for
#      keys that are safe to rotate - `--check` shows the decision without
#      making it
#
# It is idempotent in the way that matters: a key that already has a value is
# never touched. Re-running against a live deployment cannot rotate a password
# out from under a running database.
#
# Invariants, worth preserving if you change this:
#   - A blank value is generated. A key with any value is left alone, except
#     that a PLACEHOLDER in that key may be replaced - see the next point.
#   - A placeholder is replaced only when the service has never run, decided by
#     whether ./data holds anything. Postgres keeps its password inside the
#     cluster, and n8n's encryption key decrypts stored credentials, so
#     replacing either against an existing install breaks a live stack. A key
#     in NEVER_ROTATE is never replaced even when fresh.
#   - Values are never printed. They travel from openssl to the file through
#     the environment, never as a command argument, so they stay out of the
#     terminal, out of shell history and out of `ps`.
#   - Third-party credentials are never generated. A random GOOGLE_CLIENT_SECRET
#     is worse than a blank one: the service starts, looks configured, and fails
#     at the first login instead of refusing.
#
# Adding a secret this repo makes up for itself (a new *_MASTER_KEY, a shared
# token between two containers) means adding the key name to is_generatable.
# A key that must EQUAL another value rather than be random belongs in
# RELATED_SECRETS instead, so it is reported with an instruction rather than
# filled with something that cannot work. A key whose rotation destroys data
# belongs in NEVER_ROTATE.
#
# Usage notes:
#   - Run from the repo root. The service argument is a folder name, e.g. `n8n`,
#     not a path.
#   - .env is written mode 600: it holds every secret the service has.
#   - There are no prompts. Everything this script can decide, it decides; the
#     remainder is reported for a human.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${REPO_ROOT}"

MODE='write'
declare -a SERVICES=()

usage() {
  # Print the usage block from the header comment, delimited by markers rather
  # than hardcoded line numbers, so editing the header cannot silently truncate
  # or overrun it.
  sed -n '/^# --- usage ---/,/^# --- end usage ---/p' "${BASH_SOURCE[0]}" \
    | sed 's/^# \{0,1\}//' | sed '1d;$d'
  exit "${1:-0}"
}

ALL=0
while [ $# -gt 0 ]; do
  case "$1" in
    --help | -h) usage 0 ;;
    --all)
      ALL=1
      shift
      ;;
    --check)
      MODE=check
      shift
      ;;
    -*)
      echo "unknown option: $1" >&2
      usage 1
      ;;
    *)
      SERVICES+=("$1")
      shift
      ;;
  esac
done

if [ "${ALL}" = 1 ]; then
  # Not `mapfile`: macOS ships bash 3.2, which does not have it, and the
  # shebang resolves to that on a stock Mac.
  SERVICES=()
  while IFS= read -r d; do
    SERVICES+=("${d}")
  done < <(for d in */; do
    [ -f "${d}.env.sample" ] && echo "${d%/}"
  done | sort)
fi

if [ ${#SERVICES[@]} -eq 0 ]; then
  echo "error: no service given" >&2
  echo >&2
  usage 1
fi

# --- what may be generated ------------------------------------------------
#
# Two questions, asked in this order: does the value belong to a third party
# (then never generate), and is it one of the secrets this repo makes up for
# itself (then generate)?
#
# The third-party test comes first and must stay broad. A name-pattern rule of
# `*_SECRET` or `*_API_KEY` looks reasonable and is badly wrong: it would fill
# GITHUB_CLIENT_SECRET, GOOGLE_CLIENT_SECRET, AWS_SECRET_ACCESS_KEY and ~240
# others with random hex. The service then starts, looks configured, and fails
# at the first login attempt - strictly worse than leaving the line empty,
# because an empty value is visibly empty.
is_thirdparty() {
  case "$1" in
    # Vendor-prefixed credentials. Placed first because these are broader than
    # the suffix rules below; shellcheck flags the overlap otherwise, and the
    # ordering is what makes the intent readable.
    AWS_* | AZURE_* | GOOGLE_* | GITHUB_* | GITLAB_* | SLACK_* | DISCORD_*) return 0 ;;
    FACEBOOK_* | FB_* | TWITTER_* | STRIPE_* | BUNGIE_* | MAPBOX_* | MAILGUN_*) return 0 ;;
    MANDRILL_* | WANDB_* | OPENAI_* | ANTHROPIC_* | OPENROUTER_* | DATAFORSEO_*) return 0 ;;
    FREESTYLE_* | RESEND_* | AI_* | LEARNHOUSE_* | SMTP_* | MAILER_* | PENPOT_SMTP_*) return 0 ;;
    RAILS_INBOUND_EMAIL_* | LOGFLARE_* | PROXY_* | SALESFORCE_* | OKTA_* | ONELOGIN_*) return 0 ;;
    OSSO_* | WORDPRESS_* | ZITADEL_* | ZOHO_* | ZOOM_* | YANDEX_* | VK_* | MAILRU_*) return 0 ;;
    WIKIMEDIA_* | UNITED_EFFECTS_* | TODOIST_* | STRAVA_* | SPOTIFY_* | PINTEREST_*) return 0 ;;
    PIPEDRIVE_* | PATREON_* | OSU_* | NETLIFY_* | NAVER_* | MAILCHIMP_* | LINKEDIN_*) return 0 ;;
    LINE_* | KAKAO_* | KEYCLOAK_* | HUBSPOT_* | FRESHBOOKS_* | FUSIONAUTH_*) return 0 ;;
    FOURSQUARE_* | FORTYTWO_* | EVEONLINE_* | DROPBOX_* | COINBASE_* | COGNITO_*) return 0 ;;
    BOX_* | BATTLENET_* | AUTHENTIK_* | ATLASSIAN_* | APPLE_* | GLITCHTIP_COLD_STORAGE_*) return 0 ;;
    SPACES_* | WOODPECKER_GITHUB_* | PLAYWRIGHT_* | GEOLITE_LICENSE_KEY) return 0 ;;
    IG_VERIFY_TOKEN | INITIAL_SERVER_URL) return 0 ;;
    # Suffix rules.
    *_CLIENT_ID | *_CLIENT_SECRET | *_APP_ID | *_APP_SECRET) return 0 ;;
    *_CONSUMER_KEY | *_CONSUMER_SECRET) return 0 ;;
    *_SECRET_ACCESS_KEY | *_OAUTH_CALLBACK_URL | *_API_KEY | *_ACCESS_KEY) return 0 ;;
    *_ISSUER | *_TENANT_ID | *_CUSTOM_NAME | *_SCOPE) return 0 ;;
    # A bcrypt hash, not a secret we can make up: it has to be produced by
    # htpasswd from a password a human chose, and $$-escaped for compose.
    BASIC_AUTH_PASSWORD_HASH | HASHED_PASSWORD | DASHBOARD_HASHED_PASSWORD) return 0 ;;
  esac
  return 1
}

is_generatable() {
  case "$1" in
    POSTGRES_PASSWORD | DB_PASSWORD | DB_ROOT_PASSWORD) return 0 ;;
    *_DB_PASSWORD | *_DATABASE_PASSWORD) return 0 ;;
    REDIS_PASSWORD | REDIS_AUTH) return 0 ;;
    MONGODB_PASSWORD | MONGO_EXPRESS_PASSWORD | COUCHDB_PASSWORD | CLICKHOUSE_PASSWORD) return 0 ;;
    ENCRYPTION_KEY | SECRET_KEY_BASE | APP_KEY | NEXTAUTH_SECRET | BETTER_AUTH_SECRET) return 0 ;;
    # App-level secrets and admin logins this repo generates for itself.
    SECRET_KEY | GF_SECURITY_ADMIN_PASSWORD | PGADMIN_DEFAULT_PASSWORD) return 0 ;;
    DOCKER_INFLUXDB_INIT_PASSWORD | DOCKER_INFLUXDB_INIT_ADMIN_TOKEN) return 0 ;;
    INTERNAL_API_SECRET | CRON_SECRET | COLLAB_INTERNAL_KEY | BULL_AUTH_KEY) return 0 ;;
    OPENUI_SESSION_KEY | LEARNHOUSE_AUTH_JWT_SECRET_KEY | WOODPECKER_AGENT_SECRET) return 0 ;;
    SECRET | SALT | WP_PASSWORD | WB_PASSWORD | ACCOUNT_PASSWORD | ACKEE_PASSWORD) return 0 ;;
    LITELLM_MASTER_KEY | LITELLM_SALT_KEY | MEILI_MASTER_KEY | ZO_ROOT_USER_PASSWORD) return 0 ;;
    ERRBIT_ADMIN_PASSWORD | INITIAL_PASSWORD | LANGFUSE_INIT_USER_PASSWORD) return 0 ;;
    LEARNHOUSE_INITIAL_ADMIN_PASSWORD) return 0 ;;
    # Service-specific shared secrets. These are not recognizable from a generic
    # naming pattern - `SANDBOX_API_KEYS` reads like a third-party credential,
    # which is why the third-party test runs first and does not match it - so
    # they are listed explicitly. Add new ones here when a service ships a
    # secret the repo makes up for itself.
    SANDBOX_API_KEYS | N8N_SANDBOX_SERVICE_API_KEY) return 0 ;;
    SANDBOX_API_RUNNER_REGISTRATION_TOKEN | SANDBOX_API_RUNNER_API_KEY) return 0 ;;
    SEARXNG_SECRET | N8N_RUNNERS_AUTH_TOKEN | N8N_ENCRYPTION_KEY) return 0 ;;
    LANGFUSE_S3_SECRET_KEY | LANGFUSE_CLICKHOUSE_PASSWORD | LANGFUSE_REDIS_AUTH) return 0 ;;
  esac
  return 1
}

# Values that are non-empty but are obviously placeholder defaults from a
# sample file. These are left ALONE rather than replaced, because a key that
# already has a value might be a real password on a live deployment and
# silently rotating it would break the database. They are reported instead, so
# the weak value is visible rather than shipped quietly.
is_placeholder() {
  case "$1" in
    secret | secret-very-secret | password | changeme | change-me | very-secret) return 0 ;;
    your-password | your-secret | your-encryption-key-here | your-secret-here) return 0 ;;
    12345 | 123456 | 123456789 | admin | test | postgres | n8n | glitchtip) return 0 ;;
  esac
  return 1
}

# Keys that must never be rotated, even on a fresh install. Kept separate from
# the placeholder logic because the cost of getting it wrong is not a failed
# login - it is permanent data loss.
#
# N8N_ENCRYPTION_KEY encrypts every credential n8n has stored. Rotating it
# against an existing ./data/n8n leaves saved logins undecryptable, and there
# is no way back from .env alone. It is cheap for a human to set and
# catastrophic to get wrong, so this script never touches it.
NEVER_ROTATE=(
  "N8N_ENCRYPTION_KEY"
)

# Is this key one the script must not rotate even on a fresh install?
is_never_rotate() {
  local k
  for k in ${NEVER_ROTATE[@]+"${NEVER_ROTATE[@]}"}; do
    [ "${k}" = "$1" ] && return 0
  done
  return 1
}

# --- fresh install detection ----------------------------------------------

# True when the service looks like it has never been started, which is the only
# state in which replacing a placeholder is safe.
#
# Called from inside the service directory, so it tests ./data relative to the
# current directory - NOT <svc>/data. Getting that wrong is silent and
# dangerous: the check would look for <svc>/<svc>/data, never find it, and
# report "fresh" for a service that is already running.
#
# The test is "does its data directory contain anything", NOT "does the
# directory exist". dc-dev.sh runs `mkdir -p ./data` before `docker compose up`,
# so an empty data/ directory is the NORMAL state of a service that has never
# run - a [ -d data ] test would call every fresh install pre-existing and
# refuse to generate, which is the whole win this is here for.
#
# A non-empty data/ means a datastore has written something: Postgres stores
# its password inside the cluster at initdb, so replacing POSTGRES_PASSWORD in
# .env afterwards leaves the app presenting a password the database does not
# accept, and the stack fails with "password authentication failed".
#
# Services with no ./data mount (telegraf) are treated as fresh: there is no
# local datastore to be inconsistent with.
is_fresh_install() {
  # No ./data at all: nothing has run here.
  [ -d data ] || return 0
  # ./data exists but is empty: dc-dev.sh created it, nothing has run yet.
  [ -n "$(find data -mindepth 1 -print -quit 2>/dev/null)" ] && return 1
  return 0
}

# --- .env line handling ---------------------------------------------------

# True when the key is absent, or present with an empty value. A key set to a
# non-empty value is left alone, which is what makes re-running safe.
# Reads ENVFILE, which is .env normally and .env.sample in check mode.
is_blank() {
  ! grep -qE "^$1=.+" "${ENVFILE:-.env}"
}

# Replace a variable in .env, reading its new value from the environment so the
# value never appears in argv. Appends the line when the key is absent.
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

# 32 bytes of hex. Hex rather than base64 throughout: these values end up
# embedded in DSNs and URLs, where base64's / and + are not safe and would need
# percent-encoding.
generate() {
  local key="$1"
  VALUE="$(openssl rand -hex 32)"
  export VALUE
  set_from_env "${key}"
  unset VALUE
}

# --- per service ----------------------------------------------------------

declare -a PROBLEMS=()

# Secrets whose correct value is not independent: one has to equal another, or
# match a member of a list. Generating them separately produces a service that
# starts and then fails authentication, so they are named here and reported
# with an instruction rather than filled. Kept as "key|what it must equal".
RELATED_SECRETS=(
  "SANDBOX_API_RUNNER_API_KEY|must be THE SAME value as SANDBOX_API_KEYS's first entry, and is also the runner's SANDBOX_RUNNER_API_KEYS"
  "N8N_SANDBOX_SERVICE_API_KEY|must equal one of the values in SANDBOX_API_KEYS"
)

process() {
  local svc="$1"
  local filled=() kept=() pending=() weak=() rotated=() frozen=()
  # Declared up front, not at first use: a service whose branch returns early
  # would otherwise leave these unset, and `set -u` turns that into a crash
  # partway through a --all run.
  local -a related_blank=()
  local -a pending_secrets=()
  local -a keys=()
  local entry rkey rhint key secret_ish val
  # Reset per service: set below to .env, or to .env.sample in check mode when
  # there is no .env to inspect.
  ENVFILE=""

  if [ ! -d "${svc}" ]; then
    PROBLEMS+=("${svc}: no such service folder")
    return
  fi

  if [ ! -f "${svc}/.env.sample" ]; then
    PROBLEMS+=("${svc}: no .env.sample, nothing to do")
    return
  fi

  pushd "${svc}" >/dev/null

  local created=0
  if [ ! -f .env ]; then
    if [ "${MODE}" = check ]; then
      # Nothing to inspect: analyse the sample instead, so --check still reports
      # what a real run would do, without creating a file.
      ENVFILE=".env.sample"
      created=1
    else
      cp .env.sample .env
      created=1
    fi
  fi
  ENVFILE="${ENVFILE:-.env}"

  if [ "${MODE}" = write ]; then
    # Secrets live here, so keep it to the owner. Done even when .env already
    # existed, since that is the case most likely to have been created loose.
    chmod 600 .env
  fi

  # Whether a placeholder in this service may be replaced. Decided once, before
  # any key is looked at, and reported so the reason is visible. is_fresh_install
  # reads ./data relative to the current directory.
  local fresh=0
  if is_fresh_install; then
    fresh=1
  fi

  # Every key the sample defines, in sample order.
  while IFS= read -r key; do
    [ -n "${key}" ] && keys+=("${key}")
  done < <(sed -n 's/^\([A-Z][A-Z0-9_]*\)=.*/\1/p' .env.sample)

  for key in ${keys[@]+"${keys[@]}"}; do
    if ! is_blank "${key}"; then
      # Present, but is it a real value or the sample's placeholder?
      val="$(sed -n "s/^${key}=//p" "${ENVFILE:-.env}" | head -1 | tr -d "'\"")"
      # Any key whose name reads like a secret gets reported when it still
      # holds the sample's placeholder - the classification rules are about
      # what we GENERATE, and a weak value deserves flagging regardless.
      case "${key}" in
        *_PASSWORD | *_SECRET | *_SECRET_KEY | *_TOKEN | *_API_KEY | *_KEY) secret_ish=1 ;;
        *) secret_ish=0 ;;
      esac
      if [ "${secret_ish}" = 1 ] && is_placeholder "${val}"; then
        # A placeholder is only replaced when this service has never run, and
        # only for keys that are safe to rotate. Otherwise it is reported -
        # replacing it could break a live datastore or destroy stored data.
        if is_never_rotate "${key}"; then
          frozen+=("${key}")
        elif [ "${fresh}" = 1 ] && is_generatable "${key}"; then
          if [ "${MODE}" = write ]; then
            generate "${key}"
          fi
          rotated+=("${key}")
        else
          weak+=("${key}")
        fi
      else
        kept+=("${key}")
      fi
      continue
    fi
    if is_thirdparty "${key}"; then
      pending+=("${key}")
      continue
    fi
    if is_generatable "${key}"; then
      if [ "${MODE}" = write ]; then
        generate "${key}"
      fi
      filled+=("${key}")
    else
      pending+=("${key}")
    fi
  done

  # Record which relational secrets are still blank, while we are still inside
  # the service directory and .env is reachable.
  for entry in ${RELATED_SECRETS[@]+"${RELATED_SECRETS[@]}"}; do
    rkey="${entry%%|*}"
    if grep -qE "^${rkey}=$" "${ENVFILE:-.env}" 2>/dev/null; then
      related_blank+=("${entry}")
    fi
  done

  popd >/dev/null
  echo "==> ${svc}"
  if [ "${created}" = 1 ]; then
    if [ "${MODE}" = check ]; then
      echo "    .env missing - a real run would create it from .env.sample"
    else
      echo "    created .env from .env.sample"
    fi
  fi
  [ ${#filled[@]} -gt 0 ] && {
    if [ "${MODE}" = write ]; then
      printf '    generated: %s\n' "${filled[*]}"
    else
      printf '    would generate: %s\n' "${filled[*]}"
    fi
  }

  # Placeholders replaced because the service has never run.
  if [ ${#rotated[@]} -gt 0 ]; then
    if [ "${MODE}" = write ]; then
      echo "    replaced the sample's placeholder (fresh install): ${rotated[*]}"
    else
      echo "    would replace the sample's placeholder (fresh install): ${rotated[*]}"
    fi
  fi

  # Reported rather than replaced, with the reason. A sentinel of "abc123"
  # rather than a real value, so the note names the KEY and not a secret.
  if [ ${#weak[@]} -gt 0 ]; then
    echo "    still the sample's placeholder - replace before exposing this:"
    printf '      %s\n' ${weak[@]+"${weak[@]}"}


    if [ "${fresh}" = 0 ]; then
      echo "    (not replaced automatically: this service has already run, and"
      echo "     a datastore may depend on the current value)"
    fi
  fi

  # Never touched, whatever the state.
  if [ ${#frozen[@]} -gt 0 ]; then
    echo "    never replaced automatically - set this yourself:"
    printf '      %s\n' ${frozen[@]+"${frozen[@]}"}
    echo "      encrypts stored credentials; changing it after first start makes"
    echo "      them permanently unreadable"
  fi

  # Only report pending keys that are plausibly a secret. A blank timeout,
  # model name or optional feature flag is normal and listing all 400 of them
  # would bury the ones that actually block startup.
  for key in ${pending[@]+"${pending[@]}"}; do
    case "${key}" in
      *_PASSWORD | *_SECRET | *_SECRET_*) pending_secrets+=("${key}") ;;
      *_API_KEY | *_KEY | *_API_KEYS | *_TOKEN | *_CLIENT_ID) pending_secrets+=("${key}") ;;
      *_USERNAME | *_AUTH_USER | *_EMAIL) pending_secrets+=("${key}") ;;
      *_AUTH |*_AUTH_URL |*_AUTHENTICATION | *_ISSUER) pending_secrets+=("${key}") ;;
      SMTP_CONNECTION_URL | SMTP_ADDRESS | BASE_URL | SERVER_URL |*_URL) pending_secrets+=("${key}") ;;
    esac
  done

  if [ ${#pending_secrets[@]} -gt 0 ]; then
    echo "    needs a value you must supply:"
    printf '      %s\n' ${pending_secrets[@]+"${pending_secrets[@]}"}
  fi

  # A key that is set to the sample's placeholder is more dangerous than a
  # blank one: it looks configured. Report it, but never replace it - it could
  # be a real password on a machine that is already running.
  if [ ${#weak[@]} -gt 0 ]; then
    echo "    still the sample's placeholder - replace before exposing this:"
    printf '      %s\n' ${weak[@]+"${weak[@]}"}
  fi

  # Call out the keys that cannot be filled independently, so a blank here is
  # not mistaken for "optional".
  # `${related_blank[@]:-}` rather than `${related_blank[@]}`: under `set -u`,
  # bash 3.2 (which macOS ships) treats an EMPTY array expansion as unbound, so
  # a service with no related-secret hits would abort the whole run.
  for entry in ${related_blank[@]+"${related_blank[@]}"}; do
    rkey="${entry%%|*}"
    rhint="${entry#*|}"
    echo "    note: ${rkey} is blank and must match another value —"
    echo "          ${rhint}"
  done

  if [ ${#filled[@]} -eq 0 ] && [ ${#pending_secrets[@]} -eq 0 ] && [ ${#kept[@]} -gt 0 ]; then
    echo "    nothing to do"
  fi
}

echo "==> repo ${REPO_ROOT}"
[ "${MODE}" = check ] && echo "    (check mode: nothing will be written)"
echo

for svc in ${SERVICES[@]+"${SERVICES[@]}"}; do
  process "${svc}"
done

echo
if [ ${#PROBLEMS[@]} -gt 0 ]; then
  printf 'warning: %s\n' ${PROBLEMS[@]+"${PROBLEMS[@]}"} >&2
fi

cat <<'DONE'
Done. Values were not printed. To confirm nothing secret is still empty without
revealing anything, list the blank lines and check the keys that matter:

  grep -E '^[A-Z_]+=$' <service>/.env

Then start the stack. A service using ${VAR:?message} refuses to start while a
required value is blank, which is the check that catches a missed one.
DONE
