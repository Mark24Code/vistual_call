require_relative "../lib/vistual_call"

def c
end

def b
  c
end
def a
  b
end

VistualCall.trace(show_dot: true, show_path: true) do
  a
  a
end
