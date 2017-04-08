defmodule BoltexDBConnection.Connection do
  @moduledoc """
  DBConnection implementation for Boltex.

  Heavily inspired by
  https://github.com/elixir-ecto/db_connection/tree/master/examples/tcp_connection

  The launched gen server keeps a tuple as a state.
  That tuple keeps an open connection as a first element and a socket
  interface as a second element.
  """

  use DBConnection

  alias Boltex.{Bolt, Error}
  alias BoltexDBConnection.Query

  @doc "Callback for DBConnection.connect/1"
  def connect(opts) do
    host        = Keyword.fetch!(opts, :host) |> parse_ip_or_hostname
    port        = Keyword.fetch!(opts, :port)
    auth        = Keyword.fetch!(opts, :auth)

    socket      = Keyword.get(opts, :socket, BoltexDBConnection.Socket)
    socket_opts = Keyword.get(opts, :socket_options, [])
    timeout     = Keyword.get(opts, :connect_timeout, 5_000)

    enforced_opts = [packet: :raw, mode: :binary, active: false]
    socket_opts   = Enum.reverse socket_opts, enforced_opts

    with {:ok, sock} <- socket.connect(host, port, socket_opts, timeout),
         :ok         <- Bolt.handshake(socket, sock),
         :ok         <- Bolt.init(socket, sock, auth),
         :ok         <- socket.setopts(sock, active: :once)
    do
      {:ok, {sock, socket}}
    else
      {:error, %Boltex.Error{}} = error ->
        error

      error ->
        {:error, Error.exception(error, nil, :connect)}
    end
  end

  @doc "Callback for DBConnection.checkout/1"
  def checkout({sock, socket}) do
    case socket.setopts(sock, active: false) do
      :ok    -> {:ok, {sock, socket}}
      other  -> other
    end
  end

  @doc "Callback for DBConnection.checkin/1"
  def checkin({sock, socket}) do
    case socket.setopts(sock, active: :once) do
      :ok    -> {:ok, {sock, socket}}
      other  -> other
    end
  end

  @doc "Callback for DBConnection.handle_execute/1"
  def handle_execute(%Query{statement: statement}, params, opts, {sock, socket}) do
    case Bolt.run_statement(socket, sock, statement, params) do
      [{:success, _} | _] = data ->
        {:ok, data, {sock, socket}}

      %Error{type: :cypher_error} = error ->
        with :ok <- Bolt.ack_failure(socket, sock),
        do:  {:error, error, {sock, socket}}

      other ->
        {:disconnect, other, {sock, socket}}
    end
  end

  def handle_cast(i) do
    IO.puts "cast #{inspect i}"
  end

  def handle_info({:tcp_closed, sock}, {sock, _} = state) do
    {:disconnect, Error.exception({:recv, :closed}, state, nil), state}
  end
  def handle_info({:tcp_error, sock, reason}, {sock, _} = state) do
    {:disconnect, Error.exception({:recv, reason}, state, nil), state}
  end
  def handle_info(_, state), do: {:ok, state}

  def disconnect(_err, {sock, socket}) do
    socket.close sock

    :ok
  end

  def parse_ip_or_hostname(host) when is_binary(host) do
    host = String.to_charlist host

    case :inet.parse_address(host) do
      {:ok, address}    -> address
      {:error, :einval} -> host
    end
  end
  def parse_ip_or_hostname(host) when is_tuple(host), do: host
end
