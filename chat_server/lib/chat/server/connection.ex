defmodule Chat.Server.Connection do
  use GenServer, restart: :temporary

  require Logger

  defstruct [:socket]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def send_to_client(pid, message) do
    GenServer.cast(pid, {:send_to_client, message})
  end

  @impl true
  def init(opts) do
    socket = Keyword.fetch!(opts, :socket)
    Chat.Server.Data.register()
    :ok = :inet.setopts(socket, active: :once)

    {:ok, %__MODULE__{socket: socket}, {:continue, :send_welcome_message}}
  end

  @impl true
  def handle_continue(:send_welcome_message, state) do
    users_online = Chat.Server.Data.get_all_connections() |> MapSet.size()
    payload = %{"kind" => "welcome", "users_online" => users_online}
    :ok = :gen_tcp.send(state.socket, Jason.encode!(payload))

    {:noreply, state}
  end

  @impl true
  def handle_cast({:send_to_client, message}, state) do
    :ok = :gen_tcp.send(state.socket, Jason.encode!(message))
    {:noreply, state}
  end

  @impl true
  def handle_info(message, state)

  def handle_info({:tcp_closed, socket}, %{socket: socket} = state) do
    Logger.info("Stopping connection because the TCP socket was closed")
    Chat.Server.Data.unregister()
    {:stop, :normal, %{state | socket: nil}}
  end

  def handle_info({:tcp_error, socket, reason}, %{socket: socket} = state) do
    Logger.info("Stopping connection because of a TCP error: #{:inet.format_error(reason)}")
    Chat.Server.Data.unregister()
    {:stop, :normal, %{state | socket: nil}}
  end

  def handle_info({:tcp, socket, data}, %{socket: socket} = state) do
    :ok = :inet.setopts(socket, active: :once)
    handle_data(data)
    {:noreply, state}
  end

  ## Helpers

  defp handle_data(data) do
    case Jason.decode(data) do
      {:ok, %{"kind" => "broadcast", "nickname" => _, "message" => _} = message}
        connections = Chat.Server.Data.get_all_connections()
        Enum.each(connections, &Chat.Server.Connection.send_to_client(&1, message))

      {:ok, other} ->
        Logger.error("Unknown message from client: #{inspect(other)}")

      {:error, exception} ->
        Logger.error("Malformed JSON from client: #{Exception.message(exception)}")
    end
  end
end
