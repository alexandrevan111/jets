# Simple initial implementation of a prewarmer
class Jets::PrewarmJob < ApplicationJob
  timeout 300
  memory 3008
  rate '5 minutes'
  def heat
    # load all classes
    # loop through all methods
    # make the special prewarm call to keep them warm

    threads = []
    Jets::Commands::Build.app_files.each do |path|
      puts "path #{path}"
      next if path.include?("prewarm_job.rb") # dont want to cause an infinite loop
      next if path =~ %r{app/functions} # dont support app/functions
      class_path = path.sub(%r{.*app/\w+/},'').sub(/\.rb$/,'')
      class_name = class_path.classify
      klass = class_name.constantize # load app/**/* class definition
      # IE: PostsController

      klass.all_tasks.keys.each do |meth|
        underscored = class_name.underscore.gsub('/','-')
        function_name = "#{underscored}-#{meth}"
        puts "function_name #{function_name}"
        threads << Thread.new do
          Jets::Commands::Call.new(function_name, '{"_prewarm": "1"}').run unless ENV['TEST']
        end
      end
    end
    threads.each { |t| t.join }
  end
end
