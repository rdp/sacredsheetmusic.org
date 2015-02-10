class Comment < ActiveRecord::Base
  belongs_to :product

  belongs_to :created_admin_user, :class_name => 'User' # has a reference to a User

  
  def user_name_with_url_and_colon
    return '' unless user_name && user_name.length > 0
    if user_url.present?
      "<a href=\"#{user_url}\">" + user_name + "</a>:"
    else
      user_name + ":"
    end
  end
end
