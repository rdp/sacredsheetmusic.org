require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/models/preference"

class Preference

  def self.competition_end_time
    Time.parse(Preference.get_value('competition_end_date'))
  end

  def self.competition_start_time
    Time.parse(Preference.get_value('competition_start_date'))
  end

  def self.competition_live_voting?
    now = Time.now
    now < competition_end_time && now > competition_end_time
  end

end


