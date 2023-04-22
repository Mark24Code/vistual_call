module VistualCall
  StartNodeID = 1
  class StartNode
    attr_accessor :node_id,
                  :method_name,
                  :call_node_id,
                  :return_node_id,
                  :parent_node_id,
                  :children
    def initialize(method_name = nil)
      @node_id = StartNodeID
      @method_name = method_name || 'Start'
      @call_node_id = nil
      @return_node_id = nil
      @parent_node_id = nil
      @children = []
    end

    def add_child(child)
      @children << child
    end
  end

  class MethodNode
    @@instance_count = StartNodeID

    def self.instance_count
      @@instance_count
    end

    attr_accessor :node_id,
                  :method_name,
                  :call_node_id,
                  :return_node_id,
                  :parent_node_id,
                  :children
    def initialize(method_info)
      @@instance_count += 1
      @node_id = @@instance_count
      @call_node_id = nil
      @return_node_id = nil
      @parent_node_id = nil
      @children = []

      # Must copy TracePointer information, because TracePointer cannot access outside.
      [
        :path,
        :event,
        :lineno,
        :method_id,
        :callee_id,
        :defined_class,
        :parameters
      ].each do |attr|
        instance_variable_set("@#{attr}", method_info.send(attr))
        self.class.send(:attr_accessor, attr)
      end
      @method_name = get_method_name
    end

    def get_method_name
      "#{@defined_class}##{@method_id}"
    end

    def add_child(child)
      @children << child
    end
  end
end