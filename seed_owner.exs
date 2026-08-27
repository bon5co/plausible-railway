# Seeds (or rotates the password of) the owner account.
#
# Runs with only Ecto started, so no HTTP listener exists while it runs and the
# account is in place before Plausible ever binds a port. Plausible CE lets
# anyone register while the users table is empty: MaybeDisableRegistration is
# bypassed whenever Plausible.Release.should_be_first_launch?/0 is true, which
# on CE is simply "no user exists". DISABLE_REGISTRATION cannot close that
# window - seeding the owner first is what closes it.
Application.load(:plausible)
{:ok, _} = Application.ensure_all_started(:ecto_sql)
{:ok, _} = Application.ensure_all_started(:postgrex)
{:ok, _} = Plausible.Repo.start_link(pool_size: 2)

alias Plausible.Repo
alias Plausible.Auth.User

email = System.get_env("PLAUSIBLE_ADMIN_EMAIL") |> to_string() |> String.trim()
password = System.get_env("PLAUSIBLE_ADMIN_PASSWORD") |> to_string()
name = System.get_env("PLAUSIBLE_ADMIN_NAME") |> to_string() |> String.trim()
name = if name == "", do: "Owner", else: name

if email == "" or password == "" do
  IO.puts(:stderr, "[railway] PLAUSIBLE_ADMIN_EMAIL and PLAUSIBLE_ADMIN_PASSWORD are required")
  System.halt(1)
end

user =
  case Repo.get_by(User, email: email) do
    nil ->
      {:ok, user} =
        %{name: name, email: email, password: password, password_confirmation: password}
        |> User.new()
        |> Ecto.Changeset.put_change(:email_verified, true)
        |> Repo.insert()

      IO.puts("[railway] owner account created: #{email}")
      user

    existing ->
      user =
        existing
        |> User.set_password(password)
        |> Ecto.Changeset.put_change(:email_verified, true)
        |> Repo.update!()

      IO.puts("[railway] owner password re-applied: #{email}")
      user
  end

# get_or_create/1 is what the real registration flow calls
# (lib/plausible_web/live/register_form.ex); it is idempotent, so a redeploy
# rotates the password without disturbing the existing team or its sites.
{:ok, team} = Plausible.Teams.get_or_create(user)
IO.puts("[railway] owner ready (user_id=#{user.id} team_id=#{team.id})")
