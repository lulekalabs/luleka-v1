module TwitterAuthenticatedSystem

  def twitter_consumer_config
    User.twitter_config
  end

  def twitter_consumer
    @twitter_consumer ||= OAuth::Consumer.new(
      twitter_consumer_config[:consumer_token],
        twitter_consumer_config[:consumer_secret],
          {:site => 'http://twitter.com', :authorize_path => '/oauth/authenticate'})
  end

  def twitter_consumer_authorized?
    begin
      request_token = twitter_consumer.get_request_token
      reset_session
      session[:twitter_user_request_token] = request_token.token
      session[:twitter_user_request_secret] = request_token.secret
    rescue OAuth::Unauthorized
      reset_session
      return false
    end
    true
  end

  def redirect_to_twitter_login
    request_token = OAuth::RequestToken.new(consumer, 
      session[:twitter_user_request_token], 
        session[:twitter_user_request_secret])
    redirect_to request_token.authorize_url
  end

  def handle_twitter_callback
    request_token = OAuth::RequestToken.new(consumer, 
      session[:twitter_user_request_token], 
        session[:twitter_user_request_secret])

    session[:twitter_user_request_token] = nil
    session[:twitter_user_request_secret] = nil

    access_token = request_token.get_access_token

    twitter = Twitter::Base.new(access_token)

    # Twitter user credentials will be resaved to the database on every login
    credentials = twitter.verify_credentials.to_hash

    # Clean some attribute names
    credentials['twitter_id'] = credentials.delete('id')
#    credentials['login'] = credentials.delete('screen_name')
#    credentials['member_since'] = credentials.delete('created_at')

    # Remove extra attributes from credentials
    credentials.delete_if { |k, v| !User.column_names.include? k }

    # Add access token to credentials
    credentials.merge({:twitter_access_token => access_token.token, :twitter_access_secret => access_token.secret}).symbolize_keys
  end

end
