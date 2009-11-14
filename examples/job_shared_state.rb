# An example with nodes sharing a variable on job (not threadsafe yet) and 
# controlling excecution with a case statement

require 'rubygems'
require 'eventmachine'
$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'noodler'

class Job < Noodler::Job
  attr_accessor :retries
  
  def initialize
    @retries = 0
  end
  
  run [:case_statement]
  
  node :case_statement, :sync do |node, status|
    puts node.job.retries
    if status == 200 || node.job.retries > 5
      node.add_child :complete
    else
      node.add_child :download
    end
    status
  end
  
  node :download, :evented do |node, state|
    puts "Downloading..."
    deferrable = EM::DefaultDeferrable.new
    EM::Timer.new(1) do
      status = (rand < 0.3) ? 200 : 500
      puts "Finished downloading (status #{status})"
      node.job.retries += 1
      deferrable.succeed status
    end
    node.add_child :case_statement
    deferrable
  end
  
  node :complete, :threaded do |node, status|
    puts "Finished with status #{status}"
  end
end

EM.run {
  job = Job.new.run
  job.callback do
    puts "Job done"
  end
}
