require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/controllers/admin/content_nodes_controller"

class Admin::ContentNodesController < Admin::BaseController
  # Lists content nodes by type
  #
  def list
    @title = "Content List"
    # Get all content node types
    @list_options = ContentNode::TYPES

    # Set currently viewing by key
    if params[:key] then
      @viewing_by = params[:key]
    else
      @viewing_by = ContentNode::TYPES[0]
    end

    if params[:sort] == 'name' then
      sort = "name ASC"
    else
      sort = "created_on DESC"
    end

    @title << " - #{@viewing_by}"
    @content_nodes = ContentNode.paginate(
      :order => sort,
      :page => params[:page],
      :conditions => ["type = ?", @viewing_by],
      :per_page => 2000
    )
    session[:last_content_list_view] = @viewing_by
  end
end

