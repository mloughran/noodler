require 'node'

def create_deferrable(id)
  deferrable = EM::DefaultDeferrable.new
  deferrable.callback do
    puts "Finished node #{id}"
  end
  EM::Timer.new(1) do
    deferrable.succeed
  end
  deferrable
end

EM.run {
  n1 = Node.new do
    create_deferrable(1)
  end
  
  n2 = Node.new do
    create_deferrable(2)
  end
  
  n3 = Node.new do
    create_deferrable(3)
  end
  
  n1 << n2
  n1 << n3
  
  n1.run
}
