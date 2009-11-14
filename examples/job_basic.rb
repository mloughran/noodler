require 'rubygems'
require 'eventmachine'
$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'noodler'

class Download < Noodler::Job
  run [:download, :report]

  node :download, :evented do |node, params|
    puts "Downloading..."
    # raise 'foo'
    deferrable = EM::DefaultDeferrable.new
    deferrable.callback do
      puts "Finished downloading"
    end
    EM::Timer.new(1) do
      deferrable.succeed [200, 'Download result']
    end
    deferrable
  end

  node :report, :threaded do |node, status, body|
    puts "I got status code #{status} and body '#{body}'"

    node.add_child(:another)
    node.add_child(:another)

    "Report done"
  end

  node :another, :sync do |node, result|
    puts result

    puts "Sleeping in the reactor thread is bad"
    sleep 1

    node.add_child(:yet_more)

    "Another result"
  end

  node :yet_more, :threaded do |node, result|
    puts "But sleeping in a thread is ok"
    sleep 1

    puts result
  end
end

EM.run {
  2.times do |i|
    job = Download.new({}).run
    job.callback do
      puts "Finished job #{i}"
    end
    job.errback do |e|
      # raise e
      puts "Job failed with exception #{e.class}, #{e.message}"
    end
  end

  Signal.trap('INT') { EM.stop }
}
