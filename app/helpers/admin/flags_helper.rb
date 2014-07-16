module Admin::FlagsHelper

  def flaggable_column(record)
    flaggable = record.flaggable
    link_to(flaggable.class.human_name, member_path([flaggable]), :popup => true)
  end

  def user_column(record)
    link_to(record.user.person.username_or_name, person_path(record.user.person), :popup => true)
  end

  def flaggable_user_column(record)
    link_to(record.flaggable_user.person.username_or_name, person_path(record.flaggable_user.person), :popup => true)
  end
  
end
