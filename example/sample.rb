require_relative "../lib/vistual_call"

def call_c
end

def call_b
  call_c
end

def call_a
  call_b
end

VistualCall.trace(title: "Hellow", show_dot: true) do
  call_a # enter call
end
