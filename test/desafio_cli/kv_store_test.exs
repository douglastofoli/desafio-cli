defmodule DesafioCli.KVStoreTest do
  use ExUnit.Case

  alias DesafioCli.KVStore

  setup do
    if File.exists?("kvstore_dets_test") do
      File.rm!("kvstore_dets_test")
    end

    {:ok, _pid} = KVStore.start_link([], :kvstore_dets_test)
    :ok
  end

  describe "stop/0" do
    test "close the dets file and stop the application" do
      assert KVStore.stop() == :ok
    end
  end

  describe "set/2" do
    test "when it has a valid key and value, it stores the value in the key" do
      assert KVStore.set("teste", 1) == {:FALSE, 1}
      assert KVStore.set("teste", 2) == {:TRUE, 2}
    end
  end

  describe "get/1" do
    test "when the key exists, returns the value" do
      KVStore.set("teste", 1)

      assert KVStore.get("teste") == 1
    end

    test "when the key does not exist, returns nil" do
      assert KVStore.get("not_exist") == :NIL
    end
  end

  describe "begin_transaction/0" do
    test "when there is no transaction open, it opens and returns the value" do
      assert KVStore.begin_transaction() == 1
      assert KVStore.begin_transaction() == 2
    end
  end

  describe "rollback_transaction/0" do
    test "when there is an open transaction, undo the changes" do
      # 1
      KVStore.begin_transaction()

      assert KVStore.rollback_transaction() == 0

      # 1
      KVStore.begin_transaction()
      # 2
      KVStore.begin_transaction()

      assert KVStore.rollback_transaction() == 1
    end

    test "when there is no transaction open, an error is returned" do
      assert KVStore.rollback_transaction() == {:error, "No transaction"}
    end
  end

  describe "commit_transaction/0" do
    test "when there is an open transaction, save the changes" do
      assert KVStore.set("teste", 1) == {:FALSE, 1}
      assert KVStore.begin_transaction() == 1
      assert KVStore.set("teste", 2) == {:TRUE, 2}
      assert KVStore.commit_transaction() == 0
      assert KVStore.get("teste") == 2
    end
  end
end
