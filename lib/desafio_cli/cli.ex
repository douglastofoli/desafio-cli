defmodule DesafioCli.CLI do
  alias DesafioCli.KVStore

  def main(_args) do
    KVStore.start_link([])

    IO.puts("Interactive KV Store started.")
    loop()
  end

  defp loop do
    input = IO.gets("> ") |> String.trim()

    case parse_command(input) do
      ["SET", key, value] ->
        {bool, value} = KVStore.set(key, value)
        IO.puts("#{bool} #{value}")

      ["SET", _key] ->
        IO.puts("ERR \"SET <key> <value> - Syntax error\"")

      ["GET", key] ->
        value = KVStore.get(key)
        IO.puts(value)

      ["BEGIN"] ->
        value = KVStore.begin_transaction()
        IO.puts(value)

      ["ROLLBACK"] ->
        case KVStore.rollback_transaction() do
          {:error, message} -> IO.puts("ERR #{message}")
          value -> IO.puts(value)
        end

      ["COMMIT"] ->
        case KVStore.commit_transaction() do
          {:error, message} -> IO.puts("ERR #{message}")
          value -> IO.puts(value)
        end

      ["EXIT"] ->
        KVStore.stop()
        IO.puts("Exiting program.")
        System.halt(0)

      _ ->
        IO.puts("ERR \"No command #{input}\"")
    end

    loop()
  end

  defp parse_command(input) do
    Regex.scan(~r/(?:"([^"]*)"|\S+)/, input)
    |> Enum.map(fn
      [_, quoted] -> quoted
      [unquoted] -> unquoted
    end)
  end
end
