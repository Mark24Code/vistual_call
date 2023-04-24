require "sinatra"
require_relative "../lib/vistual_call"

VistualCall.trace(show_dot: true, show_order_number: true) do
  get "/" do
    "hello"
  end
end
