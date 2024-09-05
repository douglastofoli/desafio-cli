defmodule DesafioCli.KVStoreTest do
  use ExUnit.Case

  alias DesafioCli.KVStore

  setup do
    KVStore.start_link([])
    on_exit(fn -> KVStore.stop() end)
  end

  test "set and get key-value" do
    KVStore.set("name", "Alice")
    assert KVStore.get("name") == "Alice"
  end

  test "get returns :NIL for non-existent key" do
    assert KVStore.get("age") == :NIL
  end

  test "begin, rollback, and commit transactions" do
    KVStore.set("name", "Alice")
    KVStore.begin_transaction()
    KVStore.set("name", "Bob")
    assert KVStore.get("name") == "Bob"

    KVStore.rollback_transaction()
    assert KVStore.get("name") == "Alice"

    KVStore.begin_transaction()
    KVStore.set("name", "Charlie")
    KVStore.commit_transaction()
    assert KVStore.get("name") == "Charlie"
  end
end
