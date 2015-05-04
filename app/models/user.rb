require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/models/user"

class User
  belongs_to :composer_tag, :class_name => 'Tag' # has a reference to a tag
  has_many :comments, :foreign_key => :created_admin_user_id

  def validate
          if (self.new_record? || (!self.password.blank? && !self.password_confirmation.blank?))
            if (3 > self.password.length || 40 < self.password.length)
                errors.add(:password, " must be between 3 and 40 characters.") # this is redundant to another validation anyway ??
            end
           end

            # check presence of password & matching if they both aren't blank
        if (self.password != self.password_confirmation) then
                errors.add(:password, " and confirmation don't match.")
        end
  end
 
  def is_admin?
    roles.detect{|role| role.name == 'Administrator'}
  end

end
