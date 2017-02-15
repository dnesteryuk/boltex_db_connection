defmodule BoltexDbConnection do
  @default_opts [
    host: "localhost",
    port: 7687,
  ]

  def start_link(opts) do
    opts = Keyword.merge @default_opts, opts

    DBConnection.start_link BoltexDbConnection.Connection, opts
  end

  def test(host, port, query, params \\ %{}, auth \\ {}) do
    options = [
      host: host,
      port: port,
      auth: auth
    ]
    query = %BoltexDBConnection.Query{statement: query}

    {:ok, pid} = DBConnection.start_link BoltexDbConnection.Connection, options

    DBConnection.execute pid, query, params, [log: &log/1]
  end

  def log(msg) do
    IO.puts "Pool time: #{msg.pool_time / 1_000}"
    IO.puts "Connection time: #{msg.connection_time / 1_000}"
    IO.puts "Decode time: #{(msg.decode_time || 0) / 1_000}"
  end
end
