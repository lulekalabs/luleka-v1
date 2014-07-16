# Twitter user methods
#
#  Required DB fields: 
#
#    twitter_id
#    twitter_access_token
#    twitter_access_secret
#
module TwitterUserSupport

  def self.included(model)
    model.extend ClassMethods
    model.send :include, InstanceMethods
    model.class_eval do
      validates_presence_of :twitter_id, :if => :twitter_user?
      validates_uniqueness_of :twitter_id, :if => :twitter_user?
    end
  end
  
  module ClassMethods

    # load twitter configuration if not alread loaded and return as hash
    def twitter_config
      $twitter_config ||= YAML::load_file("#{RAILS_ROOT}/config/twitter_oauth.yml")[RAILS_ENV].symbolize_keys
    end
    
  end

  module InstanceMethods

    # true if is this user is linked to twitter
    def twitter_user?
      !self.twitter_id.nil? && self.twitter_id > 0
    end

    # returns a twitter instance
    def twitter
      # oauth = Twitter::OAuth.new(consumer_token[:consumer_key], consumer_token[:consumer_secret])
      # oauth.authorize_from_access(token, secret)
      consumer = OAuth::Consumer.new(twitter_config[:consumer_token], twitter_config[:consumer_secret])
      access = OAuth::AccessToken.new(consumer, self.twitter_access_token, self.twitter_access_secret)
      Twitter::Base.new(OAuth::AccessToken.new(access))
    end
    
    private
    
    # load twitter configuration if not alread loaded and return as hash
    def twitter_config
      self.class.twitter_config
    end

  end
  
end
