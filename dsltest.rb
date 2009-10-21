require 'rubygems'
require 'eventmachine'
$:.unshift('lib')
require 'noodler'

class Download < Noodler::Job
  run [:download, :report]

  node :download, :async do |params|
    puts "Downloading..."
    deferrable = EM::DefaultDeferrable.new
    deferrable.callback do
      puts "Finished downloading"
    end
    EM::Timer.new(1) do
      deferrable.succeed [200, 'Download result']
    end
    deferrable
  end

  node :report, :sync do |status, body|
    puts "I got status code #{status} and body '#{body}'"
    'Report result'
  end
end

EM.run {
  1.times {
    job = Download.new({}).run
  }
}
