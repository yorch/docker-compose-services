#!/usr/bin/env bash
# Shared helpers for the registry maintenance scripts (registry-audit.sh, prune-empty-repos.sh,
# prune-old-tags.sh). Sourced, never executed. The caller must already have cd'ed into this folder.

# The registry container of this compose project (empty when there is none). It must be running,
# unless "-a" is given, which also finds a stopped one.
registry_container() {
  local found ps_args=()
  if [[ "${1:-}" == -a ]]; then ps_args=(-a); fi
  found="$(docker ps -q ${ps_args[@]+"${ps_args[@]}"} \
    --filter "label=com.docker.compose.project.working_dir=$PWD" \
    --filter 'label=com.docker.compose.service=registry' | head -n1)"
  if [[ -z "$found" ]]; then
    # the label holds the path the stack was started from, which can differ from $PWD (symlinks)
    found="$(docker ps -q ${ps_args[@]+"${ps_args[@]}"} \
      --filter "label=com.docker.compose.project=${COMPOSE_PROJECT_NAME:-$(basename "$PWD")}" \
      --filter 'label=com.docker.compose.service=registry' | head -n1)"
  fi
  printf '%s' "$found"
}

# Settings come from the running registry (falling back to .env). Credentials are exported so that
# `docker run -e VAR` passes them without putting them on a command line or on disk.
load_s3_settings() {
  local cid
  cid="$(registry_container)"
  if [[ -z "$cid" ]]; then
    printf '%s\n' 'Registry container is not running; cannot read the S3 settings.' >&2
    exit 1
  fi
  setting() {
    local value
    value="$(docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' "$cid" | sed -n "s/^$1=//p" | head -n1)"
    if [[ -z "$value" && -f .env ]]; then value="$(sed -n "s/^$1=//p" .env | head -n1)"; fi
    printf '%s' "$value"
  }
  AWS_ACCESS_KEY_ID="$(setting REGISTRY_STORAGE_S3_ACCESSKEY)"
  AWS_SECRET_ACCESS_KEY="$(setting REGISTRY_STORAGE_S3_SECRETKEY)"
  AWS_DEFAULT_REGION="$(setting REGISTRY_STORAGE_S3_REGION)"
  BUCKET="$(setting REGISTRY_STORAGE_S3_BUCKET)"
  # S3-compatible storage (MinIO, Ceph, ...) uses a custom endpoint; AWS itself needs none
  AWS_ENDPOINT_URL="$(setting REGISTRY_STORAGE_S3_REGIONENDPOINT)"
  export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_DEFAULT_REGION BUCKET
  if [[ -n "$AWS_ENDPOINT_URL" ]]; then export AWS_ENDPOINT_URL; else unset AWS_ENDPOINT_URL; fi
  if [[ -z "$AWS_ACCESS_KEY_ID" || -z "$AWS_SECRET_ACCESS_KEY" || -z "$BUCKET" ]]; then
    printf '%s\n' 'Missing S3 settings (access key, secret key or bucket).' >&2
    exit 1
  fi
}

# Scratch directory shared with the throw-away aws-cli container.
#
# On the host it is a plain temp dir. Inside the maintenance container ($MAINTENANCE_WORKDIR is set)
# the Docker daemon resolves bind mounts on the HOST, so the host path behind that directory is
# looked up from this container's own mounts and only that directory is handed to aws-cli.
work_init() {
  local src data_dir
  if [[ -n "${MAINTENANCE_WORKDIR:-}" ]]; then
    # MAINTENANCE_DATA_DIR is the bind mount that contains MAINTENANCE_WORKDIR
    data_dir="${MAINTENANCE_DATA_DIR:?MAINTENANCE_DATA_DIR must be set together with MAINTENANCE_WORKDIR}"
    mkdir -p "$MAINTENANCE_WORKDIR"
    work="$(mktemp -d -p "$MAINTENANCE_WORKDIR")"
    src="$(docker inspect -f "{{range .Mounts}}{{if eq .Destination \"$data_dir\"}}{{.Source}}{{end}}{{end}}" "$HOSTNAME")"
    if [[ -z "$src" ]]; then
      printf 'Cannot find the host path behind %s (is it a bind mount of this container?).\n' "$data_dir" >&2
      exit 1
    fi
    work_mount="$src/${work#"$data_dir"/}"
  else
    work="$(mktemp -d)"
    work_mount="$work"
  fi
  trap 'rm -rf "$work"' EXIT
}

# Runs /work/<script> (written into $work) with bash in a throw-away aws-cli container.
# Extra arguments are passed to `docker run`, e.g. -e MODE=plan.
aws_run() {
  local script="$1" args=()
  shift
  args+=(-e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_DEFAULT_REGION -e BUCKET)
  if [[ -n "${AWS_ENDPOINT_URL:-}" ]]; then args+=(-e AWS_ENDPOINT_URL); fi
  if [[ -n "${AWS_CLI_NETWORK:-}" ]]; then args+=(--network "$AWS_CLI_NETWORK"); fi
  docker run --rm "${args[@]}" "$@" \
    -v "$work_mount:/work" --entrypoint bash "${AWS_CLI_IMAGE:-amazon/aws-cli}" "/work/$script"
}

# Functions shared by every inner script that runs inside the aws-cli container. Written into the
# work dir and sourced there (`. /work/common.sh`).
write_inner_common() {
  cat > "$work/common.sh" <<'COMMON'
# S3 connection resets are common from some hosts, so every call retries.
ls_retry() { # prefix, output file
  local i rc
  for i in 1 2 3 4 5 6; do
    rc=0
    aws s3 ls "$1" --recursive > "$2" 2> "$2.err" || rc=$?
    [[ "$rc" -eq 0 ]] && return 0
    # `aws s3 ls` exits 1 with no output and no error text when the prefix is simply empty
    [[ "$rc" -eq 1 && ! -s "$2.err" ]] && return 0
    echo "listing $1 failed (exit $rc, attempt $i), retrying" >&2
    sleep 5
  done
  return 1
}
cp_retry() {
  local i
  for i in 1 2 3; do
    aws s3 cp "$1" - 2>/dev/null && return 0
    sleep 2
  done
  return 1
}
rm_retry() { # prefix; prints the number of deleted objects
  local i out
  for i in 1 2 3; do
    out="$(aws s3 rm "$1" --recursive 2>/dev/null)" && { echo "$out" | grep -c '^delete:'; return 0; }
    sleep 3
  done
  return 1
}

# head-object on one exact key: returns 0 = exists, 1 = confirmed missing, 2 = could not tell.
# Used to re-check candidates live, because a push between a listing and a read would otherwise
# make a brand-new tag look dangling.
s3_state() {
  local i out
  for i in 1 2 3; do
    out="$(aws s3api head-object --bucket "$BUCKET" --key "$1" 2>&1)" && return 0
    grep -qE 'Not Found|404|NoSuchKey' <<< "$out" && return 1
    sleep 2
  done
  return 2
}
COMMON
}
