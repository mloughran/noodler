require 'rubygems'
require 'eventmachine'
$:.unshift('lib')
require 'noodler'

class Download < Noodler::Job
  run [:download, :report]

  node :download, :async do |node, params|
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

  node :report, :sync do |node, status, body|
    puts "I got status code #{status} and body '#{body}'"

    node.add_child(:another)
    node.add_child(:another)

    "Report done"
  end

  node :another, :sync do |node, result|
    puts result

    node.add_child(:yet_more)

    "Another result"
  end

  node :yet_more, :sync do |node, result|
    puts result
  end
end

EM.run {
  1.times {
    job = Download.new({}).run
    job.callback do
      puts "Finished everything!"
    end
    job.errback do |e|
      # raise e
      puts "Job failed with exception #{e.class}, #{e.message}"
    end
  }

  Signal.trap('INT') { EM.stop }
}
