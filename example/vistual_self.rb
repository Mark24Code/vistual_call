require_relative "../lib/vistual_call"

def call_a
end

VistualCall.trace(title: "Outer", show_dot: true) do
  VistualCall.trace(title: "Inner", show_dot: true) do
    call_a # enter call
  end
end
