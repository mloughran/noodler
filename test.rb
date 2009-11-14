require 'rubygems'
require 'eventmachine'
$:.unshift('lib')
require 'noodler'

Node = Noodler::Node

def create_deferrable(id)
  deferrable = EM::DefaultDeferrable.new
  deferrable.callback do
    puts "Finished node #{id} in thread #{Thread.current.object_id}"
  end
  EM::Timer.new(1) do
    deferrable.succeed "finished #{id}"
  end
  deferrable
end

EM.threadpool_size = 5

EM.run {
  n1 = Node.new(:evented) do
    create_deferrable(1)
  end
  
  n2 = Node.new(:threaded) do
    puts "About to sleep for a while"
    sleep 2
    puts "Finished sleeping in thread #{Thread.current.object_id}"
  end
  
  n3 = Node.new(:evented) do
    create_deferrable(3)
  end
  
  n4 = Node.new(:threaded) do |node, input|
    puts "About to sleep for a while after getting input #{input}"
    sleep 2
    puts "Finished sleeping in thread #{Thread.current.object_id}"
  end
  
  n5 = Node.new(:evented) do
    create_deferrable(5)
  end
  
  n6 = Node.new(:evented) do
    create_deferrable(6)
  end
  
  n1 << n2
  n1 << n3
  n1 << n4
  
  n2 << n5
  n3 << n6
  
  n1.run(nil)
}
