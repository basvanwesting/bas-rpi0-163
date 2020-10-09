defmodule BasRpi0163.Sensors.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(_args) do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    children = [
      {BasRpi0163.Sensors.SGP30, []},
      {BasRpi0163.Sensors.SCD30, []},
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
