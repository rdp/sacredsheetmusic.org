AdminData::Config.set = {
  :is_allowed_to_view => lambda {|controller| return true if controller.session[:user] },
  :is_allowed_to_update => lambda {|controller| return true if controller.session[:user] },
}
