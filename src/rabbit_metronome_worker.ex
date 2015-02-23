
defmodule Rabbit.Metronome.Worker do

  @amqp_lib "amqp_client/include/amqp_client.hrl"
  @server_name {:global, __MODULE__}

  require Record
  Record.defrecord :exchange,
      Record.extract(:exchange, from_lib: @amqp_lib)

  Record.defrecord :exchange_declare, :"exchange.declare",
      Record.extract(:"exchange.declare", from_lib: @amqp_lib)

  Record.defrecord :properties_basic, :P_basic,
      Record.extract(:P_basic, from_lib: @amqp_lib)

  Record.defrecord :amqp_msg,
      Record.extract(:amqp_msg, from_lib: @amqp_lib)

  Record.defrecord :basic_publish, :"basic.publish",
      Record.extract(:"basic.publish", from_lib: @amqp_lib)

  Record.defrecord :amqp_params_direct,
      Record.extract(:amqp_params_direct, from_lib: @amqp_lib)


  # Client API

  def start_link() do
    GenServer.start_link __MODULE__, [], name: @server_name
  end

  def fire do
    GenServer.cast @server_name, :fire
  end

  # Server API

  defp format_date_time({{year, month, day} = date, {hour, min, sec}}) do
    day_of_week = :calendar.day_of_the_week(date)
    [year, month, day, day_of_week, hour, min, sec] |> Enum.join "."
  end

  def init([]) do
    {:ok, connection} = :amqp_connection.start(:amqp_params_direct())
    {:ok, channel} = :amqp_connection.open_channel(connection)
    :amqp_channel.call(channel, 
        :exchange_declare(exchange: "metronome", type: "topic"))
    fire()
    {:ok, %{channel: channel}}
  end

  def handle_call(_msg, _from, state) do
    {:reply, :unknown_command, state}
  end

  def handle_cast(:fire, %{channel: channel} = state) do
    message = routing_key = format_date_time(:erlang.universaltime())
    properties = :properties_basic(content_type: "text/plain", delivery_mode: 1)
    content = :amqp_msg(props: properties, payload: message)
    basic_publish = :basic_publish(exchange: "metronome", routing_key: routing_key)
    :amqp_channel.call(channel, basic_publish, content)
    :timer.apply_after(1000, __MODULE__, fire, [])
  end

  def handle_cast(_, state) do
    {:noreply, state}
  end

  def handle_info(_info, state) do
    {:noreply, state}
  end

  def terminate(_old_vns, state, _extra) do
    {:ok, state}
  end
  
end

