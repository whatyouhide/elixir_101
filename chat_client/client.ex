defmodule Chat.Client do
  import IO.ANSI

  def start() do
    {address, port} = get_address_and_port()
    {:ok, socket} = :gen_tcp.connect(address, port, [:binary, active: true, packet: 2])
    nickname = IO.gets("Nickname: ") |> String.trim()

    gets_pid = spawn_gets_process(self())
    write_prompt(nickname)

    loop(socket, nickname, gets_pid)
  end

  defp spawn_gets_process(parent) do
    spawn(fn ->
      message = IO.gets("") |> String.trim()
      IO.write([cursor_up(), cursor_left(1000), clear_line()])
      send(parent, {:gets, message})
    end)
  end

  defp loop(socket, nickname, gets_pid) do
    receive do
      {:gets, message} ->
        message =
          case message do
            <<message::bytes-size(100), _::binary>> -> message
            other -> other
          end

        payload = %{"kind" => "broadcast", "nickname" => nickname, "message" => message}
        :ok = :gen_tcp.send(socket, Jason.encode!(payload))

        write_prompt(nickname)
        gets_pid = spawn_gets_process(self())
        loop(socket, nickname, gets_pid)

      {:tcp, ^socket, data} ->
        message = Jason.decode!(data)
        gets_pid = handle_server_message(gets_pid, nickname, message)
        loop(socket, nickname, gets_pid)

      {:tcp_closed, ^socket} ->
        raise "TCP connection was closed"

      {:tcp_error, ^socket, reason} ->
        raise "TCP connection error: #{:inet.format_error(reason)}"
    end
  end

  defp handle_server_message(gets_pid, nickname, %{"kind" => "broadcast"} = payload) do
    %{"nickname" => broadcaster_nickname, "message" => message} = payload

    kill_and_wait(gets_pid)

    clear_line_from_beginning()
    write_message(broadcaster_nickname, message)

    write_prompt(nickname)

    spawn_gets_process(self())
  end

  defp handle_server_message(gets_pid, nickname, %{"kind" => "welcome"} = payload) do
    %{"users_online" => users_online} = payload

    kill_and_wait(gets_pid)

    clear_line_from_beginning()
    write_message("~SERVER~", "Welcome #{nickname}! There are #{users_online} users online.")

    write_prompt(nickname)

    spawn_gets_process(self())
  end

  defp kill_and_wait(pid) do
    ref = Process.monitor(pid)
    Process.exit(pid, :kill)

    receive do
      {:DOWN, ^ref, _, _, _} -> :ok
    end
  end

  defp get_address_and_port() do
    input = IO.gets("Server address as address:port (defaults to localhost:4000): ")

    case String.trim(input) do
      "" ->
        {'localhost', 4000}

      other ->
        [address, port] = String.split(other, ":", parts: 2)
        {String.to_charlist(address), String.to_integer(port)}
    end
  end

  defp write_prompt(nickname) do
    IO.write([cyan(), bright(), nickname, ": ", reset()])
  end

  defp write_message(nickname, message) do
    IO.write([light_green(), nickname, ": ", reset(), faint(), message, reset(), ?\n])
  end

  defp clear_line_from_beginning() do
    IO.write([cursor_left(1000), clear_line()])
  end
end

Chat.Client.start()
