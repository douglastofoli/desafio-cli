defmodule DesafioCli.CLI do
  alias DesafioCli.KVStore

  def main(), do: loop()

  defp loop do
    input = IO.gets("> ") |> String.trim()

    case parse_command(input) do
      ["EXIT"] ->
        KVStore.stop()
        IO.puts("Exiting program.")

      command ->
        execute_command(command)
        loop()
    end
  end

  defp execute_command(["SET", key, value]) do
    {bool, value} = KVStore.set(key, value)
    IO.puts("#{bool} #{value}")
  end

  defp execute_command(["GET", key]) do
    value = KVStore.get(key)
    IO.puts(value)
  end

  defp execute_command(["BEGIN"]) do
    value = KVStore.begin_transaction()
    IO.puts(value)
  end

  defp execute_command(["ROLLBACK"]) do
    case KVStore.rollback_transaction() do
      {:error, message} -> IO.puts("ERR #{message}")
      value -> IO.puts(value)
    end
  end

  defp execute_command(["COMMIT"]) do
    case KVStore.commit_transaction() do
      {:error, message} -> IO.puts("ERR #{message}")
      value -> IO.puts(value)
    end
  end

  defp execute_command([command | _]) do
    case command do
      "SET" -> IO.puts("ERR \"SET <key> <value> - Syntax error\"")
      "GET" -> IO.puts("ERR \"GET <key> - Syntax error\"")
      _ -> IO.puts("ERR \"No command #{command}\"")
    end
  end

  defp parse_command(input) do
    input
    |> tokenize_input()
    |> process_tokens()
  end

  defp tokenize_input(input) do
    Regex.scan(~r/(?:"([^"]*)"|\S+)/, input)
    |> Enum.map(fn
      [_, quoted] -> quoted
      [unquoted] -> unquoted
    end)
  end

  defp process_tokens([command, key | rest]) when rest != [] do
    [command, key, Enum.join(rest, " ")]
  end

  defp process_tokens(parsed) do
    parsed
  end
end
