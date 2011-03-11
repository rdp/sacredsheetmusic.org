$FAST_REQUIRE_DEBUG = 1
a = File.dirname(File.expand_path(__FILE__)) + '/../../lib/faster_require.rb'
p 'first pass'
load a
p 'second pass'
load a
