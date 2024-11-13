require "bundler/gem_tasks"

task :test do
  FileList["mittsu-*/Rakefile"].each do |project|
    # clear current tasks
    Rake::Task.clear
    #load tasks from this project
    load project
    if !Rake::Task.task_defined?(:test)
      puts "No test task defined in #{project}, aborting!"
      exit -1
    else
      dir = project.pathmap("%d")
      Dir.chdir(dir) do
        system "bundle exec rake test"
      end
    end
  end
end
