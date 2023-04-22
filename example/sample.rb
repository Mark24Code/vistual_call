require_relative '../lib/graph'

def c
end

def b
  c
end
def a
  b
end

g = VistualCall::Graph.new(show_dot: true, show_path: true)

g.track { a }

g.output
