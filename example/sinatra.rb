require "sinatra"
require_relative "../lib/vistual_call"

VistualCall.trace(theme: :lemon) do
  get "/" do
    "hello"
  end
end
