module Noodler
  class Node
    include EM::Deferrable

    # attr_accessor :parent

    def initialize(type, strategy = nil, &strategy_block)
      unless type == :sync || type == :async
        raise ArgumentError, "type must be :sync or :async"
      end
      @synchronous = (type == :sync)
      @children = []
      @children_complete = 0
      @strategy = strategy || strategy_block
    end

    def <<(child)
      # child.parent = self
      child.callback do
        @children_complete += 1
        if @children_complete == @children.size
          succeed
        end
      end
      child.errback do |e|
        fail e
      end
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
    rescue => e
      fail e
    end

    def run_sync(input)
      EM.defer \
        lambda {
          begin
            @output = @strategy.call(input);
          rescue => e
            puts "exception caught in thread - propagating back"
            fail e
          end
        },
        lambda { EM.next_tick(method(:run_children)) }
    end

    def run_children
      if @children.any?
        @children.each do |child|
          child.run(@output)
        end
      else
        succeed
      end
    end
  end
end
