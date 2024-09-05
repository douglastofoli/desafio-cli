defmodule DesafioCliTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  test "main/1" do
    input = """
    EXIT
    """

    output =
      capture_io([input: input, capture_prompt: false], fn ->
        DesafioCli.main([])
      end)

    assert output =~ "Interactive KV Store started."
    assert output =~ "Exiting program."
  end
end
