require "sinatra"
require "vistual_call"

VistualCall.trace(show_dot: true) do
  get "/" do
    "hello"
  end
end
