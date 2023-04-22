require_relative "./method_node"

module VistualCall
  class MethodCallTree
    attr_accessor :call_stack, :memo
    def initialize
      @call_stack = []
      @memo = {}

      root = StartNode.new
      @call_stack.push(root)
      memo_it(root.node_id, {})
    end

    def memo_it(node_id, payload)
      @memo[node_id] = payload unless @memo.key?(node_id)
      return @memo[node_id]
    end



    def handle_event_call(method_info)
      node = MethodNode.new(method_info)
      node_id = node.node_id
      memo_it(node_id, node)

      @call_stack.last.call_node_id = node_id
      @call_stack.push(node)
    end

    def handle_event_return(method_info)
      node = MethodNode.new(method_info)
      node_id = node.node_id
      memo_it(node_id, node)

      if @call_stack.last.method_name == node.method_name
        match_call_method = @call_stack.pop
        match_call_method.return_node_id = node_id

        match_call_method_parent = @call_stack.last
        if match_call_method_parent
          match_call_method.parent_node_id = match_call_method_parent.node_id
          match_call_method_parent.add_child(match_call_method)
        end
      end
    end
  end
end
