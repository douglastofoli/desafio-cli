defmodule DesafioCli do
  @moduledoc """
  Main module for DesafioCli.
  """

  alias DesafioCli.CLI
  alias DesafioCli.KVStore

  def main(_args) do
    KVStore.start_link([])
    IO.puts("Interactive KV Store started.")

    CLI.main()
  end
end
