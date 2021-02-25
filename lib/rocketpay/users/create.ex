defmodule Rocketpay.Users.Create do
  alias Rocketpay.{Account, Repo, User}
  alias Ecto.Multi

  def call(params) do

      Multi.new()
      |> Multi.insert(:create_user, User.changeset(params))
      |> Multi.run(:create_account, fn repo, %{create_user: user} ->

        insert_account(repo, user.id)
      end)
      |> Multi.run(:preload_data, fn repo, %{create_user: user} ->

        preload_Data(repo, user)
      end)
      |> run_transaction()
  end

  defp insert_account(repo, user) do

    user.id
    |> account_changeset()
    |> repo.insert()

  end

  defp account_changeset(user_id) do
    params = %{user_id: user_id, balance: "0.00"}
    Account.changeset(params)
  end

  defp preload_Data(repo,%{create_user: user}) do
    {:ok, repo.preload(user, :account)}
  end

  defp run_transaction(multi) do
    case Repo.transaction(multi) do
      {:error, _operation, reason, _changes} -> {:error, reason}
      {:ok, %{preload_data: user}} -> {:ok, user}
    end

  end
end
