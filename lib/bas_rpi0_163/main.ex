defmodule BasRpi0163.Main do
  @moduledoc false

  @default_interval 60_000 #ms

  alias BasRpi0163.Sensors.SGP30
  alias BasRpi0163.Publisher.Producer

  use GenServer

  defmodule State do
    @moduledoc false
    defstruct \
      interval: 60_000,         \
      source:   "bas-rpi0-163", \
      location: "Office"
  end

  defmodule Measurement do
    @moduledoc false
    defstruct \
      measured_at: nil, \
      quantity:    nil, \
      unit:        nil, \
      value:       nil, \
      location:    nil, \
      source:      nil
  end

  def start_link(interval \\ @default_interval) do
    GenServer.start_link(__MODULE__, interval, name: __MODULE__)
  end

  def init(interval) do
    Process.send_after(self(), :tick, interval)
    {:ok, %State{interval: interval}}
  end

  def handle_info(:tick, state) do
    with %{eco2_ppm: eco2_ppm, tvoc_ppb: tvoc_ppb} <- SGP30.get_measurements() do
      build_measurement("CO2", eco2_ppm, "ppm", state)
      |> Producer.enqueue

      build_measurement("TVOC", tvoc_ppb, "ppb", state)
      |> Producer.enqueue
    end

    Process.send_after(self(), :tick, state.interval)
    {:noreply, state}
  end

  def build_measurement(quantity, value, unit, state) do
    %Measurement{
      measured_at: nil,
      quantity:    quantity,
      value:       value,
      unit:        unit,
      location:    state.location,
      source:      state.source,
    }
  end

end

