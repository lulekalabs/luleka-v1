class Notifier < ActionMailer::Base
  include ActionController::UrlWriter
  include ActionView::Helpers::DateHelper

  #--- accessors
  # set in environment.rb
  cattr_accessor :site_url     # http://luleka.net

  cattr_accessor :service_email  # e.g. <service@luleka.net>
  cattr_accessor :admin_email    # e.g. <admin@luleka.net>
  cattr_accessor :noreply_email  # e.g. <noreply@luleka.net>
  cattr_accessor :info_email     # e.g. <info@luleka.net>
  cattr_accessor :support_email  # e.g. <support@luleka.net>
  cattr_accessor :error_email    # e.g. <error@luleka.net>
  
  #--- class method
  class << self

    # necessary to be able to render partials in mailer views
    def controller_path
      ''
    end
    
    # e.g. www.luleka.net or http://www.luleka.net
    def site_url=(page)
      unless page.blank?
        uri = URI.parse(page)
        if [URI::HTTP, URI::HTTPS].include?(uri.class)
          @@site_url = page
        else
          @@site_url = "http://#{page}"
        end
        if uri = URI.parse(@@site_url)
          default_url_options[:host] = uri.host if uri.host
        end
      end
    rescue URI::InvalidURIError => ex
      logger.error "Exception #{ex.message} caught when assigning Notifier.site_url #{page}"
      @@site_url = nil
    end
    
    # tries to return a regular email address from a pretty printed email
    #
    # e.g.
    #
    #   "John Smith <j@s.com>" -> "j@s.com"
    #
    def unprettify(email)
      email && email.match(/\<(.*)\>/) ? $1 : email
    end
    
  end
  
  #--- generic instance methods
  
  protected

  # override in subclasses
  def setup_email(record = nil, sent_at = nil)
    from    self.service_email
    sent_on sent_at || Time.now.utc
    subject "#{self.site_url} "
  end
  
end
