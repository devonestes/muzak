defmodule Muzak.ConfigTest do
  use ExUnit.Case, async: true

  describe "setup/1" do
    test "throws an exception when the file passed to `--only` doesn't exist" do
      path = "/does/not/exist.ex"
      args = ["--only", path]
      msg = "file `#{path}` passed as argument to `--only` does not exist"
      assert_raise RuntimeError, msg, fn -> Muzak.Config.setup(args) end
    end
  end
end
