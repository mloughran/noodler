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

    def run
      @synchronous ? run_sync : run_async
    end

    def run_async
      deferrable = @strategy.call
      deferrable.callback do
        puts "Deferrable strategy succeeded"
        EM.next_tick(method(:run_children))
      end
      deferrable.errback do
        puts "Deferrable strategy failed"
      end
    end

    def run_sync
      EM.defer \
        lambda { @strategy.call },
        lambda { EM.next_tick(method(:run_children)) }
    end

    def run_children
      @children.each do |child|
        child.run
      end
    end
  end
end
