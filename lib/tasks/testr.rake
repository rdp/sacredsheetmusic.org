  require 'os' # gem
  desc "really run the local tests, though each in own proc [sigh]"
  task :testr do
    failed = []
    for file in  Dir['test/**/*_test.rb'] 
      command = "#{OS.ruby_bin} #{file}"
      p 'running', command
      if !system(command)
        failed << file
      end
    end
    p 'failed', failed
  end