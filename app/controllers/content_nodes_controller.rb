require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/controllers/content_nodes_controller"

class ContentNodesController < ApplicationController

  # Shows an entire page of content by name
  def show_by_name

    @content_node = ContentNode.find(:first, :conditions => ["name = ?", params[:name]])
    if !@content_node then
      render :file => "#{RAILS_ROOT}/public/404.html", :layout => false, :status => 404
      return
    end
    # Set a title
    if @content_node.title == "home"
      # use the default which is the full name
    elsif @content_node.title.blank? then
      @title = @content_node.name.capitalize
    else
      @title = @content_node.title
    end
    # Render special template for blog posts
    if @content_node.type == 'Blog' then
      render(:template => 'content_nodes/blog_post')
    else # Render basic template for regular pages
      render(:layout => 'main')
    end
  end

end
