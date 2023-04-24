require "yaml"
require "json"

data = YAML.load_file("./theme.yml", aliases: true)

puts JSON.pretty_generate(data)
