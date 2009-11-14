module Noodler
  class Job
    include EM::Deferrable

    class << self
      attr_reader :_jobs, :_nodes

      def run(jobs)
        @_jobs = jobs
      end

      def node(name, type, &strategy)
        @_nodes ||= {}
        @_nodes[name] = {
          :type => type,
          :strategy => strategy
        }
      end
    end

    def initialize(options = {})
      @options = options
    end

    def run
      root = construct_graph
      root.run
      root.callback do
        succeed
      end
      root.errback do |e|
        fail e
      end
      self
    end

    def create_named_node(name)
      n = self.class._nodes[name]
      Noodler::Node.new(n[:type], n[:strategy])
    end

    private

    def construct_graph
      jobs = self.class._jobs.dup

      root = nil
      current = nil

      while !jobs.empty?
        n = self.class._nodes[jobs.shift]
        node = Noodler::Node.new(n[:type], n[:strategy])
        if current
          current << node
          current = node
        else
          current = root = node
          root.job = self
        end
      end

      root
    end
  end
end
