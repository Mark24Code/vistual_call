module VistualCall
  StartNodeID = 1
  class StartNode
    attr_accessor :node_id, :method_name, :parent_node_id, :children
    def initialize(method_name = nil)
      @node_id = StartNodeID
      @method_name = method_name || "Start"
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

    def self.get_method_name(node_info)
      "#{node_info.defined_class}##{node_info.method_id}"
    end

    attr_accessor :node_id, :method_name, :parent_node_id, :children
    def initialize(method_info)
      @@instance_count += 1
      @node_id = @@instance_count
      @parent_node_id = nil

      # Must copy TracePointer information, because TracePointer cannot access outside.
      %i[path event lineno method_id defined_class parameters].each do |attr|
        instance_variable_set("@#{attr}", method_info.send(attr))
        self.class.send(:attr_accessor, attr)
      end
      @method_name = self.class.get_method_name(self)
      @children = []
    end

    def add_child(child)
      @children << child
    end
  end
end
