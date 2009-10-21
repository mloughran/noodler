require 'rubygems'
require 'eventmachine'

class Node
  attr_accessor :parent
  
  def initialize(&strategy)
    @children = []
    @strategy = strategy
  end
  
  def <<(child)
    child.parent = self
    @children << child
  end
  
  def run
    deferrable = @strategy.call
    deferrable.callback do
      puts "Strategy succeeded"
      EM.next_tick(method(:run_children))
    end
    deferrable.errback do
      puts "Strategy failed"
    end
  end
  
  def run_children
    @children.each do |child|
      child.run
    end
  end
end
