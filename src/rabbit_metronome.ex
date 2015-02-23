
defmodule Rabbit.Metronome do
  use Application

  def start(:normal, []) do
    Rabbit.Metronome.Supervisor.start_link
  end

  def stop(_state) do
    :ok
  end
end
