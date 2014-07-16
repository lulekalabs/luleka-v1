# holds the helpers to identify all cache keys, e.g. for fragment caching
module CacheKeys
  
  def self.included(base)
    base.extend(ClassMethods)
    base.send :include, InstanceMethods
    if base.respond_to?(:helper_method)
      base.send :helper_method,
        :application_i18n_javascript_fragment_cache_key,
        :feedback_widget_fragment_cache_key,
        :page_fragment_cache_key,
        :membership_plans_fragment_cache_key,
        :partner_benefits_fragment_cache_key,
        :faq_page_fragment_cache_key,
        :home_page_widget_fragment_cache_key,
        :footer_navigation_fragment_cache_key
    end  
  end
  
  module ClassMethods
    
  end
  
  module InstanceMethods
    
    protected
    
    #--- fragment cache keys
    
    def application_i18n_javascript_fragment_cache_key
      "application-i18n-javascript-#{I18n.locale}"
    end
    
    def feedback_widget_fragment_cache_key(tier=@tier, topic=@topic)
      "feedback-widget-#{tier ? tier.permalink : 'generic'}-#{topic ? topic.permalink : 'generic'}-#{I18n.locale}"
    end

    def page_fragment_cache_key(page_or_permalink=@page, locale_code=I18n.locale)
      if page_or_permalink.is_a?(Page)
        "#{page_or_permalink.permalink}-#{locale_code}"
      elsif page_or_permalink.is_a?(String)
        "#{page_or_permalink}-#{locale_code}"
      end
    end
    
    def membership_plans_fragment_cache_key
      "membership-plans-#{I18n.locale}"
    end

    def partner_benefits_fragment_cache_key
      "partner-benefits-#{I18n.locale}"
    end

    def faq_page_fragment_cache_key(tier=nil, without_locale=false)
      unless without_locale
        tier ? "#{tier.site_name}-faq-page-#{I18n.locale}" : "faq-page-#{I18n.locale}"
      else
        tier ? "#{tier.site_name}-faq-page" : "faq-page"
      end
    end
    
    def footer_navigation_fragment_cache_key(tier=@tier, without_locale=false)
      unless without_locale
        tier && tier.name ? "#{tier.site_name}-footer-navigation-#{I18n.locale}" : "footer-navigation-#{I18n.locale}"
      else
        tier && tier.name ? "#{tier.site_name}-navigation-footer" : "footer-navigation"
      end
    end
    
    def home_page_widget_fragment_cache_key
      "home-page-widget-#{I18n.locale}"
    end
    
  end
  
end
