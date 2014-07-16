# Facebook
#
#  Required DB fields: 
#
#    fb_user_id
#    fb_email_hash
#
module FacebookUserSupport

  def self.included(model)
    model.extend ClassMethods
    model.send :include, InstanceMethods
    model.class_eval do
      validates_uniqueness_of :fb_user_id, :if => :facebook_user?
      after_create :register_user_to_fb_connect
    end
  end
  
  module ClassMethods

    #--- facebook class methods
    
    # find the user in the database, first by the facebook user id and if that fails through the email hash
    def find_by_fb_user(fb_user)
      User.find_by_fb_user_id(fb_user.id) # || User.find_by_fb_email_hash(fb_user.email_hashes)
    end

    # build new users from facebook user instance
    #
    # E.g.
    # 
    #   User.new_from_fb_user(current_facebook_user)
    #
    def new_from_fb_user(fb_user, options={})
      # fb_user.hometown_location
      # fb_user.pic_square_with_logo  * pic_big_with_logo
      # catch Facebooker::Session::SessionExpired
      new_user = User.new({
        :login         => "#{fb_user.first_name}_#{fb_user.last_name}",
        :first_name    => fb_user.first_name,
        :last_name     => fb_user.last_name,
        :fb_locale     => fb_user.locale,
        :fb_tz_offset  => fb_user.timezone,
        :fb_gender     => fb_user.gender,
        :password      => "",
        :email         => fb_user.email || ""
      }.merge(options))
      new_user.fb_user_id = fb_user.id.to_i
      new_user
    end
    
    # Take the data returned from facebook and create a new user from it.
    # We don't get the email from Facebook because a facebooker can only login through Connect we just generate a unique login name for them.
    # If you were using username to display to people you might want to get them to select one after registering through Facebook Connect
    def create_from_fb_connect(fb_user)
      new_user = User.new(:name => fb_user.name, :login => "facebooker_#{fb_user.uid}", :password => "", :email => "")
      
      new_user.fb_user_id = fb_user.uid.to_i
      # we need to save without validations
      new_user.save(false)
      new_user.register_user_to_fb_connect
    end
    
  end

  module InstanceMethods

    # We are going to connect this user object with a facebook id. But only ever one account.
    def link_fb_connect(fb_user)
      if fb_user
        # check for existing account
        existing_fb_user = User.find_by_fb_user(fb_user)
        # unlink the existing account
        unless existing_fb_user.nil?
          existing_fb_user.fb_user_id = nil
          existing_fb_user.save(false)
        end
        # link the new one
        self.fb_user_id = fb_user.id
        self.register_user_to_fb_connect
        save(false)
      end
    end

    # unlink facebook account
    def unlink_fb_connect
      if self.facebook_user? #&& self.fb_email_hash
        # Facebooker::User.unregister([self.fb_email_hash])
        self.fb_user_id = nil
        self.fb_email_hash = nil
        self.save(false)
      end
    end

    # The Facebook registers user method is going to send the users email hash and our account id to Facebook
    # We need this so Facebook can find friends on our local application even if they have not connect through connect
    # We then use the email hash in the database to later identify a user from Facebook with a local user
    def register_user_to_fb_connect
      if self.facebook_user? && !self.new_record? && self.email
        users = {:email => self.email, :account_id => self.id}
        # deprecated call to connect.registerUsers
        # http://developers.facebook.com/docs/reference/rest/connect.registerusers/
        # Facebooker::User.register([users])
        # self.fb_email_hash = Facebooker::User.hash_email(self.email)
        # save(false)
      end
    end

    # true if is this user is linked to facebook
    def facebook_user?
      !fb_user_id.nil? && fb_user_id > 0
    end

    # converts fb locale to language and person.default_country
    # fb locales use "_" instead of "-" are like "en_US"
    def fb_locale=(value)
      self[:language] = Utility.language_code(value.gsub(/_/, "-")) if value 
      self.person.default_country = Utility.country_code(value.gsub(/_/, "-")) if value && self.person
    end

    # converts fb gender to gender, "male" and "female"
    def fb_gender=(value)
      if value && value =~ /^female/i
        self.gender = "f"
      elsif value && value =~ /^male/i
        self.gender = "m"
      end
    end

    # offset from fb are "-3" for "Brasilia"
    def fb_tz_offset=(fb_offset)
      if zone = ::ActiveSupport::TimeZone[fb_offset.to_i]
        self.tz = zone
      end
    end

  end
  
end
