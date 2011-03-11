slow = true
file_name = File.expand_path('./yo.rb')
File.open(file_name, 'w') do |f| f.write '33333'; end

if !slow
  1000.times { eval File.read(file_name) } # ascii mode
else
  1000.times { load file_name } # ascii mode
end