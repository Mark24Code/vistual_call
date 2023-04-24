require "set"
require "tempfile"
require_relative "./tracer"

module VistualCall
  DEFAULT_OUTPUT = "vistual_call_result.png"
  class Graph
    @@custer_count = 0
    attr_accessor :call_tree_root
    def initialize(options = {})
      @show_dot = options[:show_dot] || false
      @direction = options[:direction] || "LR"

      @default_config = { fontname: "wqy-microhei", fontcolor: "black" }

      @global_node_attributes =
        options[:global_node_attributes] || @default_config
      @global_edge_attributes =
        options[:global_edge_attributes] || @default_config

      @default_node_config = { shape: "box", style: "rounded", peripheries: 1 }
      @warn_node_config = { style: "filled", fillcolor: "#DD4A68" }

      @node_attributes = options[:node_attributes] || @default_node_config
      # @edge_attributes = options[:edge_attributes] || nil

      @show_path = options.fetch(:show_path, false)
      @format = options.fetch(:format, "png")
      @output = options.fetch(:output, "#{Dir.pwd}/#{DEFAULT_OUTPUT}")

      @stop_trace_methods = options.fetch(:stop_trace_methods, [])
      @tracer = Tracer.new(stop_trace_methods: @stop_trace_methods)

      @call_tree_root = nil
      @call_tree_hashmap = nil

      @label_hashmap = {}
      @cache_graph_nodes_set = Set.new
      @cache_graph_edges = []

      @jump_list = %w[Kernel#class Kernel#frozen?]
      @heightlight_method = /method_missing/
    end

    def get_call_tree_root
      @call_tree_root = @tracer.call_tree_root
    end

    def get_call_tree_hashmap
      @call_tree_hashmap = @tracer.call_tree_hashmap
    end

    def track(&block)
      @tracer.track(&block)
    end

    def get_graph_node_id(node)
      label_name = node.method_name
      if !@label_hashmap.key?(label_name)
        @label_hashmap[label_name] = node.node_id
      end
      return @label_hashmap[label_name]
    end

    def collect_graph_nodes_edges(node)
      return if node == nil
      return if @jump_list.include?(node.method_name)

      graph_node_id = get_graph_node_id(node)

      # build node
      @cache_graph_nodes_set.add(graph_node_id)

      # buid edges
      if node.parent_node_id
        parent_node = @call_tree_hashmap[node.parent_node_id]
        parent_graph_node_id = get_graph_node_id(parent_node)
        @cache_graph_edges.push([parent_graph_node_id, graph_node_id])
      end

      # Make recurse call
      if node.children.size > 0
        node.children.each do |one_child_node|
          collect_graph_nodes_edges(one_child_node)
        end
      end
    end

    def create_or_set(obj, key, value)
      obj[key] = [] if !obj.key?(key)
      obj[key].push(value)
    end

    def collect_group_cluster
      @cluster_group = {}
      @label_hashmap.keys.each do |label_name|
        if label_name.count("::") == 0
          create_or_set(@cluster_group, "_single", @label_hashmap[label_name])
        else
          module_name = label_name.split("#")
          module_name.pop
          module_name = module_name.join("#")
          create_or_set(@cluster_group, module_name, @label_hashmap[label_name])
        end
      end
    end

    def get_dot_config_string(hashmap)
      config = hashmap.keys.map { |key| "#{key}=\"#{hashmap[key]}\"" }.join(",")
      return "[#{config}]"
    end

    def dot_node_format(node_id)
      if node_id == StartNodeID
        config = { label: "Start" }
        return(
          "node#{node_id}#{get_dot_config_string(config.merge(@default_node_config))}"
        )
      end

      node = @call_tree_hashmap[node_id]
      config = { label: "#{node.defined_class}##{node.method_id}" }
      config = config.merge(@default_node_config)

      config = config.merge(@warn_node_config) if @heightlight_method =~
        node.method_name

      return("node#{node_id}#{get_dot_config_string(config)}")
    end

    def generate_node_text(graph_node_id)
      return dot_node_format(graph_node_id) + ";\n"
    end

    def generate_cluster(module_name, graph_ids)
      @@custer_count += 1

      template = <<-CLUSTER
  subgraph cluster_#{@@custer_count} {
    label = "#{module_name}";
    style=filled;
    color=lightgrey;

    #{graph_ids.map { |graph_node_id| generate_node_text(graph_node_id) }.join("")}
}
    CLUSTER

      return template
    end

    def generate_nodes_and_clusters()
      content = ""
      p "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
      p @cluster_group.keys.sort!
      @cluster_group.keys.each do |key|
        if key == "_single"
          graph_node_ids = @cluster_group[key]

          graph_node_ids.each do |graph_node_id|
            content << generate_node_text(graph_node_id)
          end
        else
          module_name = key
          module_graph_node_ids = @cluster_group[key]

          content << generate_cluster(module_name, module_graph_node_ids)
        end
      end

      return content
    end

    def dot_edge_format(edge)
      parent_id, child_id = edge
      return "node#{parent_id} -> node#{child_id}"
    end

    def generate_edges
      @cache_graph_edges.map { |edge| "\t" + dot_edge_format(edge) }.join("\n")
    end

    def generate_dot_template
      dot_template = <<-DOT
digraph "virtual_call_graph"{
  rankdir = #{@direction};
  node #{get_dot_config_string(@global_node_attributes)};
  edge #{get_dot_config_string(@global_edge_attributes)};

  #{generate_nodes_and_clusters}

  #{generate_edges}

}
DOT

      return dot_template
    end

    def create_dot_file(content)
      dot_file_path = nil
      dot_file = Tempfile.new("vistual_call")
      dot_file_path = dot_file.path
      dot_file.write content
      dot_file.close
      return dot_file_path
    end

    def output
      get_call_tree_root()
      get_call_tree_hashmap()

      collect_graph_nodes_edges(@call_tree_root)
      collect_group_cluster()
      content = generate_dot_template()
      dot_file_path = create_dot_file(content)
      system("cat #{dot_file_path}") if @show_dot
      system("dot #{dot_file_path} -T #{@format} -o '#{@output}'")
    end
  end
end
