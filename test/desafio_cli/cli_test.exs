defmodule DesafioCli.CLITest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  alias DesafioCli.CLI
  alias DesafioCli.KVStore

  setup do
    remove_file_test("kvstore_dets_test")

    on_exit(fn ->
      remove_file_test("kvstore_dets_test")
    end)

    {:ok, _pid} = KVStore.start_link([], :kvstore_dets_test)
    :ok
  end

  test "SET commands" do
    input = """
    SET teste 1
    SET teste 2
    EXIT
    """

    output =
      capture_io([input: input, capture_prompt: false], fn ->
        CLI.main()
      end)

    assert output =~ "FALSE 1"
    assert output =~ "TRUE 2"
    assert output =~ "Exiting program."
  end

  test "SET command error with no value" do
    input = """
    SET teste
    EXIT
    """

    output =
      capture_io([input: input, capture_prompt: false], fn ->
        CLI.main()
      end)

    assert output =~ "ERR \"SET <key> <value> - Syntax error\""
    assert output =~ "Exiting program."
  end

  test "GET commands" do
    input = """
    GET teste
    SET teste 1
    GET teste
    EXIT
    """

    output =
      capture_io([input: input, capture_prompt: false], fn ->
        CLI.main()
      end)

    assert output =~ "NIL"
    assert output =~ "FALSE 1"
    assert output =~ "1"
    assert output =~ "Exiting program."
  end

  test "BEGIN command" do
    input = """
    GET teste
    BEGIN
    SET teste 1
    GET teste
    EXIT
    """

    output =
      capture_io([input: input, capture_prompt: false], fn ->
        CLI.main()
      end)

    assert output =~ "NIL"
    assert output =~ "1"
    assert output =~ "FALSE 1"
    assert output =~ "1"
    assert output =~ "Exiting program."
  end

  test "BEGIN command recursive" do
    input = """
    BEGIN
    BEGIN
    EXIT
    """

    output =
      capture_io([input: input, capture_prompt: false], fn ->
        CLI.main()
      end)

    assert output =~ "1"
    assert output =~ "2"
    assert output =~ "Exiting program."
  end

  test "BEGIN command persistence" do
    input = """
    GET teste
    BEGIN
    SET teste 1
    GET teste
    COMMIT
    EXIT
    """

    output =
      capture_io([input: input, capture_prompt: false], fn ->
        CLI.main()
      end)

    assert output =~ "NIL"
    assert output =~ "1"
    assert output =~ "FALSE 1"
    assert output =~ "1"
    assert output =~ "0"
    assert output =~ "Exiting program."

    input = """
    GET teste
    EXIT
    """

    output =
      capture_io([input: input, capture_prompt: false], fn ->
        {:ok, _pid} = KVStore.start_link([], :kvstore_dets_test)
        CLI.main()
      end)

    assert output =~ "1"
    assert output =~ "Exiting program."
  end

  test "ROLLBACK command" do
    input = """
    GET teste
    BEGIN
    SET teste 1
    GET teste
    ROLLBACK
    GET teste
    EXIT
    """

    output =
      capture_io([input: input, capture_prompt: false], fn ->
        CLI.main()
      end)

    assert output =~ "NIL"
    assert output =~ "1"
    assert output =~ "FALSE 1"
    assert output =~ "1"
    assert output =~ "0"
    assert output =~ "NIL"
    assert output =~ "Exiting program."
  end

  test "ROLLBACK command recursive" do
    input = """
    GET teste
    BEGIN
    SET teste 1
    GET teste
    BEGIN
    SET foo bar
    SET bar baz
    GET foo
    GET bar
    ROLLBACK
    GET foo
    GET bar
    GET teste
    EXIT
    """

    output =
      capture_io([input: input, capture_prompt: false], fn ->
        CLI.main()
      end)

    assert output =~ "NIL"
    assert output =~ "1"
    assert output =~ "FALSE 1"
    assert output =~ "1"
    assert output =~ "2"
    assert output =~ "FALSE bar"
    assert output =~ "FALSE baz"
    assert output =~ "bar"
    assert output =~ "baz"
    assert output =~ "1"
    assert output =~ "NIL"
    assert output =~ "NIL"
    assert output =~ "1"
    assert output =~ "Exiting program."
  end

  test "COMMIT command" do
    input = """
    GET teste
    BEGIN
    SET teste 1
    GET teste
    COMMIT
    GET teste
    EXIT
    """

    output =
      capture_io([input: input, capture_prompt: false], fn ->
        CLI.main()
      end)

    assert output =~ "NIL"
    assert output =~ "1"
    assert output =~ "FALSE 1"
    assert output =~ "1"
    assert output =~ "0"
    assert output =~ "1"
    assert output =~ "Exiting program."
  end

  test "COMMIT command recursive" do
    input = """
    GET teste
    BEGIN
    SET teste 1
    GET teste
    BEGIN
    SET foo bar
    SET bar baz
    GET foo
    GET bar
    COMMIT
    GET foo
    GET bar
    GET teste
    ROLLBACK
    GET teste
    GET foo
    GET bar
    EXIT
    """

    output =
      capture_io([input: input, capture_prompt: false], fn ->
        CLI.main()
      end)

    assert output =~ "NIL"
    assert output =~ "1"
    assert output =~ "FALSE 1"
    assert output =~ "1"
    assert output =~ "2"
    assert output =~ "FALSE bar"
    assert output =~ "FALSE baz"
    assert output =~ "bar"
    assert output =~ "baz"
    assert output =~ "1"
    assert output =~ "bar"
    assert output =~ "1"
    assert output =~ "0"
    assert output =~ "NIL"
    assert output =~ "NIL"
    assert output =~ "NIL"
    assert output =~ "Exiting program."
  end

  test "COMMIT command error no transaction" do
    input = """
    COMMIT
    EXIT
    """

    output =
      capture_io([input: input, capture_prompt: false], fn ->
        CLI.main()
      end)

    assert output =~ "ERR No transaction"
    assert output =~ "Exiting program."
  end

  test "Invalid command error" do
    input = """
    TRY
    EXIT
    """

    output =
      capture_io([input: input, capture_prompt: false], fn ->
        CLI.main()
      end)

    assert output =~ "ERR \"No command TRY\""
    assert output =~ "Exiting program."
  end

  defp remove_file_test(file) do
    if File.exists?(file) do
      File.rm!(file)
    end
  end
end
