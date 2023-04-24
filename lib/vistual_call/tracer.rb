require_relative "./method_call_tree"

module VistualCall
  class Tracer
    attr_accessor :call_tree
    def initialize(options = {})
      @events = %i[call return]
      @call_tree = MethodCallTree.new

      @trace_point =
        TracePoint.new(*@events) do |tp|
          # TODO: stop
          @call_tree.send("dispatch_#{tp.event}", tp)
        end
    end

    def track(&block)
      @trace_point.enable { block.call }
    end

    def call_tree_root
      @call_tree.call_stack.first || nil
    end

    def call_tree_hashmap
      @call_tree.memo || {}
    end
  end
end
