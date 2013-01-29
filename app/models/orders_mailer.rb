require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/models/orders_mailer"

class OrdersMailer
 
  # called like... deliver_inquiry(...)...I guess... 
  def spam_composer composer_object
    email_addy_from=Preference.get_value('mail_username')
    setup_defaults
#    @bcc = nil
    subject "freeldssheetmusic.org update"
    # renders a .rhtml file...
    body         :composer => composer_object
    recipients   composer_object.composer_email_if_contacted
    from         email_addy_from
  end

  def setup_defaults
      @bcc        = Preference.get_value('mail_copy_to').split(',')
      @from       = Preference.get_value('mail_username')
      @sent_on    = Time.now
      @headers    = {}
  end

  # called like... deliver_inquiry(...)...I guess... 
  def inquiry(subjectt, email_text, email_addy_from=Preference.get_value('mail_username'))
    setup_defaults
    subject(subjectt)      
    # renders a .rhtml file...
    body         :from => email_addy_from, :email_text => email_text
    recipients   Preference.get_value('mail_copy_to').split(',')
    from         email_addy_from
  end

end
