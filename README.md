# plausible-railway

Plausible Community Edition v3.2.1 packaged for Railway.

The stock image opens its HTTP port with an empty user table, and Plausible's
first-launch flow lets **any** anonymous visitor register the first account —
`PlausibleWeb.Plugs.MaybeDisableRegistration` is bypassed while
`Plausible.Release.should_be_first_launch?()` is true, so `DISABLE_REGISTRATION`
does not close that window. On a public Railway URL the first stranger to load
`/register` owns the instance, and the deployer is then locked out permanently
(Plausible's password reset is an emailed link, and a fresh deploy has no SMTP).

This wrapper:

1. runs the migrations, then seeds the owner account and its team **before** the
   Plausible endpoint binds the port, so the first request the public URL ever
   serves already gets `302 /login` on `/register`;
2. re-applies the owner password on every boot, which makes a redeploy a working
   password reset;
3. refuses to boot when `PLAUSIBLE_ADMIN_EMAIL` or `PLAUSIBLE_ADMIN_PASSWORD` is
   empty, rather than shipping an unclaimed instance;
4. sets `DISABLE_REGISTRATION=true`.

## Variables

| Name | Purpose |
| --- | --- |
| `PLAUSIBLE_ADMIN_EMAIL` | Owner account email. Required. |
| `PLAUSIBLE_ADMIN_PASSWORD` | Owner password. Required, 12–128 characters. |

Everything else is stock Plausible CE configuration (`BASE_URL`, `DATABASE_URL`,
`CLICKHOUSE_DATABASE_URL`, `SECRET_KEY_BASE`, `TOTP_VAULT_KEY`, …).

Image: `ghcr.io/bon5co/plausible-railway:v3.2.1`
