# Plausible Community Edition packaged for Railway.
#
# Adds three things the stock image cannot do on a public URL:
#   1. seeds the owner account before the HTTP port is opened, so the
#      first-launch registration window is never reachable by a stranger;
#   2. re-applies the owner password on every boot, making a redeploy a
#      working password reset (Plausible CE has no offline reset and a
#      fresh deploy has no SMTP);
#   3. closes public registration by default.
FROM ghcr.io/plausible/community-edition:v3.2.1

ENV DISABLE_REGISTRATION=true

COPY railway-entrypoint.sh /usr/local/bin/railway-entrypoint.sh
COPY seed_owner.exs /opt/plausible-railway/seed_owner.exs

USER root
RUN chmod +x /usr/local/bin/railway-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/railway-entrypoint.sh"]
