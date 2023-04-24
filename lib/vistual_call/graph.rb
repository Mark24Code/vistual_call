require "set"
require "tempfile"
require "yaml"
require_relative "./tracer"

module VistualCall
  # Output config
  DEFAULT_OUTPUT_FORMAT = "png"
  DEFAULT_OUTPUT = "vistual_call_result.png"
  DEFAULT_OUTPUT_PATH = File.join(Dir.home, DEFAULT_OUTPUT)

  # Jump Node
  DEFAULT_JUMP_NODE = %w[Kernel#class Kernel#frozen?]

  # Hightlight Label
  HIGHT_LIGHT_REGEX = /method_missing/

  # Core
  DIRECTIONS = %w[TB LR BT RL]

  class Graph
    @@custer_count = 0
    attr_accessor :call_tree_root

    def self.root
      File.expand_path("../../", __dir__)
    end

    def initialize(options = {})
      @title = options[:title]
      @labelloc = options[:labelloc] || "top"
      @labeljust = options[:labeljust] || "center"
      @margin = options[:margin] || "5"
      # display config
      @direction = options.fetch(:direction, :LR).to_s
      if !DIRECTIONS.include?(@direction)
        raise VistualCallError("direction must in #{DIRECTIONS}")
      end
      @format = options.fetch(:format, DEFAULT_OUTPUT_FORMAT)
      @output = options.fetch(:output, DEFAULT_OUTPUT_PATH)

      @show_path = options.fetch(:show_path, false)
      @show_dot = options.fetch(:show_dot, false)
      @show_order_number = options.fetch(:show_order_number, true)

      # node graph config
      @jump_list = options.fetch(:jump_list, DEFAULT_JUMP_NODE)
      @heightlight_match = options.fetch(:heightlight_match, HIGHT_LIGHT_REGEX)

      # theme
      @theme_name = options.fetch(:theme, :sky).to_s
      @theme_config =
        YAML.load_file(File.join(self.class.root, "theme.yml"), aliases: true)
      @theme =
        @theme_config[@theme_name] || @theme_config[@theme_config["use_theme"]]
      @node_attrs = @theme["node_attrs"]
      @edge_attrs = @theme["edge_attrs"]
      @node_waring_attrs = @theme["node_warn_attrs"]

      # working cache
      @tracer = Tracer.new

      @call_tree_root = nil
      @call_tree_hashmap = nil

      @label_hashmap = {}
      @cache_graph_nodes_set = Set.new
      @cache_graph_edges = []
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

    def get_dot_config_string(hashmap = nil)
      return if !hashmap
      config = hashmap.keys.map { |key| "#{key}=\"#{hashmap[key]}\"" }.join(",")
      return "[#{config}]"
    end

    def merge_config(*configs)
      new_config = {}
      configs.each { |conf| new_config = new_config.merge(conf) }
      return new_config
    end

    def get_label_text(node)
      result = "#{node.defined_class}##{node.method_id}"
      result << " (#{node.node_id})" if @show_order_number
      return result
    end

    def dot_node_format(node_id)
      if node_id == StartNodeID
        return("node#{node_id}#{get_dot_config_string({ label: "Start" })}")
      end

      node = @call_tree_hashmap[node_id]

      config = { label: get_label_text(node) }
      config = merge_config(config, @node_waring_attrs) if @heightlight_match =~
        node.method_name

      return("node#{node_id}#{get_dot_config_string(config)}")
    end

    def generate_node_text(graph_node_id)
      return dot_node_format(graph_node_id) + ";\n"
    end

    def generate_cluster(module_name, graph_ids)
      @@custer_count += 1

      cluster_style_config = @theme.dig("cluster", "style") || nil
      cluster_style_config_text =
        cluster_style_config && "style=\"#{cluster_style_config}\";"

      cluster_color_config = @theme.dig("cluster", "color") || nil
      cluster_color_config_text =
        cluster_color_config && "color=\"#{cluster_color_config}\";"

      cluster_node_config = @theme.dig("cluster_node") || nil
      cluster_node_config_text =
        cluster_node_config &&
          "node=#{get_dot_config_string(cluster_node_config)};"

      template = <<-CLUSTER
  subgraph cluster_#{@@custer_count} {
    label="#{module_name}";
    #{cluster_style_config_text}
    #{cluster_color_config_text}
    #{cluster_node_config_text}

    #{graph_ids.map { |graph_node_id| generate_node_text(graph_node_id) }.join("")}
}
    CLUSTER

      return template
    end

    def render_nodes_and_clusters()
      content = ""
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
      return("node#{parent_id} -> node#{child_id}")
    end

    def render_edges
      @cache_graph_edges.map { |edge| dot_edge_format(edge) }.join("\n")
    end

    def render_graph_config
      @theme.dig("graph") &&
        "graph #{get_dot_config_string(@theme.dig("graph"))}"
    end

    def render_node_config
      @node_attrs && "node #{get_dot_config_string(@node_attrs)};"
    end

    def render_edge_config
      @edge_attrs && "edge #{get_dot_config_string(@edge_attrs)};"
    end

    def render_meta_info
      meta_info = ["rankdir=#{@direction};"]
      meta_info << "margin=#{@margin};" if @margin
      meta_info << "label=\"#{@title}\";" if @title
      meta_info << "labelloc=\"#{@labelloc}\";" if @labelloc
      meta_info << "labeljust=\"#{@labeljust}\";" if @labeljust

      meta_info.join("\n")
    end
    def generate_dot_template
      dot_template = <<-DOT
digraph "virtual_call_graph"{

#{render_meta_info}
#{render_graph_config}
#{render_node_config}
#{render_edge_config}

#{render_nodes_and_clusters}

#{render_edges}

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
