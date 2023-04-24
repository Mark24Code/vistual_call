require_relative "./method_node"

module VistualCall
  class MethodCallTree
    attr_accessor :call_stack, :memo
    def initialize
      @call_stack = []
      @memo = {}

      root = StartNode.new
      @call_stack.push(root)
      memo_it(root.node_id, root)
    end

    def memo_it(node_id, payload)
      @memo[node_id] = payload unless @memo.key?(node_id)
      return @memo[node_id]
    end

    def dispatch_call(method_info)
      # Memo: 构建树的call、return 不应该被跳过、修改，来保持对应关系，可以还原起调用树。过滤工作应该在消费数据的层面
      node = MethodNode.new(method_info)
      node_id = node.node_id
      memo_it(node_id, node)

      @call_stack.push(node)
    end

    def dispatch_return(method_info = {})
      match_call_method = @call_stack.pop

      match_call_method_parent = @call_stack.last
      if match_call_method_parent
        match_call_method.parent_node_id = match_call_method_parent.node_id
        match_call_method_parent.add_child(match_call_method)
      end
    end
  end
end
