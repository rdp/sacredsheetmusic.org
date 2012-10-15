# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode
# (Use only when you can't set environment variables through your web/app server)
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.8' unless defined? RAILS_GEM_VERSION
$: << '.' if RUBY_VERSION >= '1.9.0'

# Bootstrap the Rails environment, frameworks, and default configuration
#require File.dirname(__FILE__) + "/../lib/faster_require-0.9.2/lib/faster_require" # faster require speeds all around...

require 'thread'
require File.join(File.dirname(__FILE__), 'boot')
require File.join(File.dirname(__FILE__), '../vendor/plugins/engines/boot')

#require the plugin loader, for threadsafe engines...
require File.join(File.dirname(__FILE__), '..', 'lib', 'eager_loader')

::SQLITE3_LOCATION=YAML.load_file(RAILS_ROOT + '/config/database.yml')[RAILS_ENV]['sqlite3_location']
# unused for now...
# raise 'need sqlite3_location IN DB' unless SQLITE3_LOCATION.present?
Rails::Initializer.run do |config|
  # Necessary for us to run legacy engine migrations
  # DO NOT CHANGE THIS
  config.active_record.timestamped_migrations = false
  # Settings in config/environments/* take precedence over those specified here
  config.load_paths += %W( #{RAILS_ROOT}/vendor/plugins/substruct )
  config.action_controller.session_store = :active_record_store

  # It seems Rack 1.1.0 SPECIFICALLY is required by Rails 2.3.8
  config.gem "rack", :version => '1.1.0'
  
  config.gem 'RedCloth', :lib => 'redcloth'
  config.gem 'fastercsv' if RUBY_VERSION < '1.9.0'
  config.gem 'mime-types', :lib => 'mime/types'
  config.gem 'mini_magick', :version => '1.3.3'
  config.gem 'ezcrypto'
  config.gem 'subexec'
  
  # All of these gems are just so we can attach inline-css styles
  # to the order receipt HTML email! :(
  config.gem 'css_parser'
  config.gem 'text-hyphen', :lib => 'text/hyphen'
  config.gem 'text-reform', :lib => 'text/reform'
  config.gem 'htmlentities'
  # http://github.com/SunDawg/premailer
  config.gem 'sundawg_premailer', :lib => 'premailer'
  
  #override the default loader
  # ? config.plugin_loader = EagerLoader
  config.after_initialize { Cache.warmup_in_other_thread }
  config.action_controller.page_cache_directory = RAILS_ROOT+"/public/cache/" 
end

if RUBY_VERSION >= '1.9.0'
  # use the new CSV for CSV generation...
  require 'csv'
  FasterCSV = CSV
end

Substruct.override_ssl_production_mode = true
