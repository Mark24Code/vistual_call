require_relative "./method_call_tree"

module VistualCall
  class Tracer
    attr_accessor :call_tree
    def initialize(options = {})
      @stop_trace_methods = options.fetch(:stop_trace_methods, [])
      # TODO: implement c_call, c_return
      @events = %i[call return]
      @call_tree = MethodCallTree.new

      @trace_point = TracePoint.new(*@events) do |tp|
          if @stop_trace_methods.length > 0 && @stop_trace_methods.include?(tp.method_id)
            tp.disable
          else
            @call_tree.send("handle_event_#{tp.event}", tp)
          end
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
