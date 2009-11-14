module Noodler
  class Node
    include EM::Deferrable

    # attr_accessor :parent
    attr_accessor :job

    VALID_TYPES = [:sync, :evented, :threaded]

    def initialize(run_method, strategy = nil, &strategy_block)
      unless VALID_TYPES.include?(run_method)
        raise ArgumentError, "type must be #{VALID_TYPES.join(', ')}"
      end
      @run_method = run_method
      @children = []
      @children_complete = 0
      @strategy = strategy || strategy_block
    end

    def <<(child)
      # child.parent = self
      child.job = self.job
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

    def add_child(name)
      node = job.create_named_node(name)
      self << node
    end

    def run(input = nil)
      case @run_method
      when :sync: run_sync(input)
      when :evented: run_evented(input)
      when :threaded: run_threaded(input)
      else
        raise "#{@run_method} not supported"
      end
    end

    def run_sync(input)
      @output = @strategy.call(self, input)
      EM.next_tick(method(:run_children))
    rescue => e
      puts "Exception in sync code"
      fail e
    end

    def run_evented(input)
      deferrable = @strategy.call(self, input)
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

    def run_threaded(input)
      EM.defer do
        begin
          @output = @strategy.call(self, input)
          EM.next_tick(method(:run_children))
        rescue => e
          puts "exception caught in thread - propagating back"
          fail e
        end
      end
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
