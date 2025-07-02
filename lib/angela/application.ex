defmodule Angela.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      if Application.get_env(:angela, :enable, true),
        do: [
          # Starts a worker by calling: Angela.Worker.start_link(arg)
          # {Angela.Worker, arg}
          ExGram,
          {Angela.Bot, Application.get_all_env(:ex_gram)}
        ],
        else: []

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Angela.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
