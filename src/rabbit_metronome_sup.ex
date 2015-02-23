
defmodule Rabbit.Metronome.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    children = [
      worker(Rabbit.Metronome.Worker, [], [
        restart: :permanent,
        shutdown: 10000
      ])
    ]
    supervise(children, [
      strategy: :one_for_one,
      max_restarts: 3,
      max_seconds: 10
    ])
  end


end
