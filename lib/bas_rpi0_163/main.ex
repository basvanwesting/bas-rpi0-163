defmodule BasRpi0163.Main do
  @moduledoc false

  @default_interval 60_000 #ms

  alias BasRpi0163.Sensors.SCD30
  alias BasRpi0163.Sensors.SGP30
  alias BasRpi0163.Publisher.Producer

  use GenServer

  defmodule State do
    @moduledoc false
    defstruct \
      interval: nil, \
      host:  "bas-rpi0-163"
  end

  def start_link(interval \\ @default_interval) do
    GenServer.start_link(__MODULE__, interval, name: __MODULE__)
  end

  def init(interval) do
    Process.send_after(self(), :tick, interval)
    {:ok, %State{interval: interval}}
  end

  def handle_info(:tick, state) do
    publish_measurements_for(SCD30, state.host)
    publish_measurements_for(SGP30, state.host)

    Process.send_after(self(), :tick, state.interval)
    {:noreply, state}
  end

  def publish_measurements_for(sensor, host) do
    with measurements when is_list(measurements) <- sensor.get_measurements() do
      for measurement <- measurements do
        measurement
        |> enrich_measurement(host)
        |> Producer.enqueue
      end
    end
  end

  def enrich_measurement(measurement, host) do
    %{ measurement |
        measured_at: DateTime.now!("Etc/UTC"),
        host: host,
    }
  end

end

