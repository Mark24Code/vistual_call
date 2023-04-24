# frozen_string_literal: true

require_relative "vistual_call/version"
require_relative "./vistual_call/graph"

module VistualCall
  class VistualCallError < StandardError
  end

  class << self
    def trace(options = {})
      unless block_given?
        puts "Block required!"
        return
      end

      proxy = ::VistualCall::Graph.new(options)
      proxy.track { yield }
      proxy.output
    end
  end
end
