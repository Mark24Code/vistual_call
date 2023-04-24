require "sinatra"
require_relative "../lib/vistual_call"

VistualCall.trace do
  get "/" do
    "hello"
  end
end
