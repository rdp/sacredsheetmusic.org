require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/models/orders_mailer"

class OrdersMailer
 
  def composer_stats composer_object
    email_addy_from=Preference.get_value('mail_username')
    setup_defaults
#    @bcc = nil # uncomment if I don't want extra copies to me...
    subject "freeldssheetmusic.org composer individual song stats"
    # renders a .rhtml file...
    body         :composer => composer_object
    recipients   composer_object.composer_email_if_contacted
    from         email_addy_from
  end

  def spam_composer composer_object
    email_addy_from=Preference.get_value('mail_username')
    setup_defaults
#    @bcc = nil # uncomment if I don't want extra copies to me...
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
  # email_addy_from is "their submitted form email addy" for questions...
  def inquiry(subjectt, email_text, email_addy_from, extra_email_to=nil)
    setup_defaults
    @email_addy_from = email_addy_from
    # @bcc = nil # uncomment to not send copy to us...
    subject(subjectt)
    # renders a .rhtml file...
    body :from => email_addy_from, :email_text => email_text
    #recipients   Preference.get_value('mail_copy_to').split(',')
    if extra_email_to.present?
      recipients [extra_email_to]
      # @bcc = nil
    end
    from email_addy_from
  end

end
