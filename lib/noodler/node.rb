module Noodler
  class Node
    attr_accessor :parent

    def initialize(type, strategy = nil, &strategy_block)
      unless type == :sync || type == :async
        raise ArgumentError, "type must be :sync or :async"
      end
      @synchronous = (type == :sync)
      @children = []
      @strategy = strategy || strategy_block
    end

    def <<(child)
      child.parent = self
      @children << child
    end

    def run(input = nil)
      @synchronous ? run_sync(input) : run_async(input)
    end

    def run_async(input)
      deferrable = @strategy.call(input)
      deferrable.callback do |output|
        @output = output
        puts "Deferrable strategy succeeded"
        EM.next_tick(method(:run_children))
      end
      deferrable.errback do
        puts "Deferrable strategy failed"
      end
    end

    def run_sync(input)
      EM.defer \
        lambda { @output = @strategy.call(input); },
        lambda { EM.next_tick(method(:run_children)) }
    end

    def run_children
      @children.each do |child|
        child.run(@output)
      end
    end
  end
end
