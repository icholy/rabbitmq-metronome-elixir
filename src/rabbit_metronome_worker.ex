
defmodule Rabbit.Metronome.Worker do

  @amqp_lib "amqp_client/include/amqp_client.hrl"
  @rk_format "~4.10.0B.~2.10.0B.~2.10.0B.~1.10.0B.~2.10.0B.~2.10.0B.~2.10.0B"

  require Record

  Record.defrecord Exchange, :exchange, Record.extract(
      :exchange, from_lib: @amqp_lib)

  Record.defrecord ExchangeDeclare, :"exchange.declare", Record.extract(
      :"exchange.declare", from_lib: @amqp_lib)

  Record.defrecord PBasic, :P_basic, Record.extract(
      :P_basic, from_lib: @amqp_lib)

  Record.defrecord AmqpMsg, :amqp_msg, Record.extract(
      :amqp_msg, from_lib: @amqp_lib)

  Record.defrecord BasicPublish, :"basic.publish", Record.extract(
      :"basic.publish", from_lib: @amqp_lib)

  Record.defrecord AmqpParamsDirect, :amqp_params_direct, Record.extract(
      :amqp_params_direct, from_lib: @amqp_lib)

  def start_link() do
    GenServer.start_link __MODULE__, [], []
  end

  def init([]) do
    {:ok, connection} = :amqp_connection.start(AmqpParamsDirect())
    {:ok, channel} = :amqp_connection.open_channel(connection)
    :amqp_channel.call(channel, 
        ExchangeDeclare(exchange: "metronome", type: "topic"))
    fire()
    {:ok, %{channel: channel}}
  end

  def handle_call(_msg, _from, state) do
    {:reply, :unknown_command, state}
  end

  def handle_cast(:fire, %{channel: channel} = state) do
    {{year, month, day} = date, {hour, min, sec}} = :erlang.universaltime()
    day_of_week = :calendar.day_of_the_week(date)
    routing_key = String.Chars.to_string(
        :io_lib.formati(@rk_format, 
            [year, month, day, day_of_week, hour, min, sec]))
    message = routing_key
    properties = PBasic(content_type: "text/plain", delivery_mode: 1)
    basic_publish = BasicPublish(exchange: "metronome", routing_key: routing_key)
    content = AmqpMsg(props: properties, payload: message)
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

  def fire do
    GenServer.cast __MODULE__, :fire
  end
  
end

