class Comment < ActiveRecord::Base
  belongs_to :product
  
  def user_name_with_url_and_colon
    return '' unless user_name && user_name.length > 0
    if user_url.present?
      "<a href=\"#{user_url}\">" + user_name + "</a>:"
    else
      user_name + ":"
    end
  end
end
