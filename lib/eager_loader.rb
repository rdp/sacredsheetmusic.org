# from http://squaremasher.blogspot.com/2009/08/rails-threadsafe-and-engines.html
class EagerLoader < Rails::Plugin::Loader
  def add_plugin_load_paths
    super
    engines.each do |engine|
      configuration.eager_load_paths += engine.load_paths
    end
  end
end