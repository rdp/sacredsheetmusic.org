  require 'os' # gem
  desc "really run the local tests, though each in own proc [sigh]"
  task :testr do
    for file in  Dir['test/**/*_test.rb'] 
      command = "#{OS.ruby_bin} #{file}"
      p 'running', command
      system command
    end
  end