defmodule BasRpi0163.Publisher.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(_args) do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    children = [
      {BasRpi0163.Publisher.AMQP, []},
      {BasRpi0163.Publisher.Producer, []},
      {BasRpi0163.Publisher.Consumer, []},
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
