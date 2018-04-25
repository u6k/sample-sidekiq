class HelloWorker
  include Sidekiq::Worker

  def perform(*args)
    puts "hello"
  end
end
