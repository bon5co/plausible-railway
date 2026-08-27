#!/bin/sh
set -eu

fail() { echo "[railway] $1" >&2; exit 1; }

[ -n "${PLAUSIBLE_ADMIN_EMAIL:-}" ] || fail "PLAUSIBLE_ADMIN_EMAIL is empty - refusing to boot an unclaimed instance"
[ -n "${PLAUSIBLE_ADMIN_PASSWORD:-}" ] || fail "PLAUSIBLE_ADMIN_PASSWORD is empty - refusing to boot an unclaimed instance"

# ClickHouse accepts connections later than Postgres does, and the migrations
# fail outright against a ClickHouse that is not answering yet. Retry rather
# than depending on a wait tool the base image may not carry.
run_migrations() {
  i=0
  while :; do
    if /entrypoint.sh db createdb && /entrypoint.sh db migrate; then
      return 0
    fi
    i=$((i + 1))
    [ "$i" -ge 40 ] && fail "migrations never succeeded (is ClickHouse reachable?)"
    echo "[railway] migrations not ready yet (attempt $i), retrying in 5s"
    sleep 5
  done
}

echo "[railway] running migrations"
run_migrations

# Seed or rotate the owner BEFORE any port is opened.
echo "[railway] seeding owner account"
/app/bin/plausible eval 'Code.eval_file("/opt/plausible-railway/seed_owner.exs")'

echo "[railway] starting Plausible on port ${PORT:-8000}"
exec /entrypoint.sh run
