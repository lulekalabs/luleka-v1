ActionController::Routing::Routes.draw do |map|

  #=== front end application
  map.subdomains nil, :www, :us, :es, :de, :ar, :cl, :name => '::' do |front|

    #--- session
    front.resource :session, :controller => 'sessions'

    #--- user partners
    front.resource :user, :as => "users" do |partner|
      partner.resource :partner, :as => "partners", :member => {
        :amend => :get,
        :payment => :get,
        :complete => :get
      }, :collection => {
        :plans => :get,
        :benefits => :get
      }
    end

    #--- user
    front.resources :users, :collection => {
      :confirm => :get,
      :complete => :get,
      :validates_uniqueness => :post,
      :forgot => :get,
      :forgot_password => :get,
      :create_reset_password => :post,
      :update_address_province => :post,
      :link_fb_connect => :get
    }, :member => {
      :confirm => :get,
      :activate => :get,
      :resend => :get,
      :reset => :get,
      :update_password => :put
    }

    #--- voucher
    front.resource :voucher, :collection => {
      :verification_code => :get,
      :complete => :get
    }

    #=== tiers
    front.resources :tiers, :as => Tier.human_resources_name, :except => [:index, :show], :collection => {
      :plans => :get,
      :complete => :get,
      :recent => :get,
      :popular => :get,
      :search_field => :get,
      :select_field => :get
    }, :member => {
      :claim => :get,
      :list_item_expander => :post
    } do |tiers|
      #--- tier_widgets_feedback_path(@tier, :subdomain => "de") 
      # e.g. http://de.luleka.com/communities/apple/widget/feedback/lookup
      tiers.resource :widgets, :only => [], :controller => 'widgets/widget_application' do |widgets|
        widgets.resource :feedback, :controller => 'widgets/feedbacks', :collection => {:lookup => :post} 
      end

      #--- tier_topic_widgets_feedback_path(@tier, @topic, :subdomain => "de") 
      # e.g. http://de.luleka.com/communities/apple/widget/feedback/lookup
      tiers.resources :topics, :only => [] do |topics|
        topics.resource :widgets, :controller => 'widgets/widget_application' do |widgets|
          widgets.resource :feedback, :controller => 'widgets/feedbacks', :collection => {:lookup => :post} 
        end
      end
    end

    #--- kases only, e.g. http://www.luleka.com/questions
    [Kase, Problem, Question, Idea, Praise].each do |kase_class|
      front.resources kase_class.resources_name, :as => kase_class.human_resources_name, :collection => {
        :my => :get,
        :recent => :get,
        :open => :get,
        :open_rewarded => :get,
        :popular => :get,
        :solved => :get,
        :lookup => :post,
        :select_location => :get
      }, :member => {
        :vote_up => :put,
        :vote_down => :put,
        :participants => :get,
        :followers => :get,
        :matching_people => :get,
        :visitors => :get,
        :toggle_follow => :put,
        :location => :get,
        :activate => :get
      } do |kases|
        kases.resources :responses, :collection => {
          :popular => :get
        }, :member => {
          :vote_up => :put,
          :vote_down => :put,
          :accept => :put
        } do |responses|
          responses.resources :comments do |comments|
            comments.resources :flags
          end
          responses.resources :flags
        end
        kases.resources :comments do |comments|
          comments.resources :flags
        end
        kases.resources :locations
        kases.resources :flags
        kases.resources :emails, :controller => 'email_kases', :collection => {
          :verification_code => :get
        }
        kases.resources :rewards
      end

      # kase_search_url(:id => "foo") e.g. http://www.luleka.com/kases/search/foo
      # kase_tag_url(:id => "bar") e.g. http://www.luleka.com/kases/tags/bar
      front.resource kase_class.resource_name, :as => kase_class.human_resources_name do |kase|
        kase.resources :searches, :as => "search", :only => :show
        kase.resources :tags, :collection => {:autocomplete => :get}
      end
    end

    #--- search
    front.search "search", :controller => "searches"

    #--- responses
    front.activate_response "/responses/:id/activate", :controller => 'responses', :action => 'activate'

    #--- comments
    front.activate_comment "/comments/:id/activate", :controller => 'comments', :action => 'activate'

    #--- flags
    front.resources :flags

    #--- invitations
    front.resources :invitations, :collection => {
      :complete => :get,
      :update_message => :get
    }, :member => {
      :accept => :post,
      :decline => :post,
      :remind => :post,
      :confirm => :get,
      :list_item_expander => :post
    }
    front.open_invitation 'contacts/invite/:id', :controller => 'contacts', :action => 'invite', :id => ''

    #--- contacts
    front.resources :contacts, :collection => {
      :pending => :get
    }, :member => {
      :shared => :get
    }

    #--- people
    front.resources :people, :member => {
      :follow => :put,
      :stop_following => :put,
      :followers => :get,
      :destroy_contact => :delete,
      :kases => :get,
      :visitors => :get,
      :contacts => :get,
      :shared_contacts => :get,
      :invite => :post,
      :list_item_expander => :post,
      :edit_avatar => :get,
      :update_avatar => :put,
      :destroy_avatar => :delete
    }, :collection => {
      :me => :get,
      :reputable => :get,
      :popular => :get
    } do |people|
      people.resources :invitations
      people.resources :flags
      people.resources :locations
      people.resources :emails, :controller => 'email_people', :collection => {
        :verification_code => :get
      }
    end

    # people_tag_path(:id => "foo+bar") e.g. http://www.luleka.com/people/tags/foo+bar
    # people_search_path(:id => "foo") e.g. http://www.luleka.com/people/search/foo
    front.resource :person, :as => :people do |person|
      person.resources :searches, :as => "search", :only => :show
      person.resources :tags, :collection => {:autocomplete => :get}
    end

    #--- static pages
    front.with_options :controller => 'pages', :action => 'show' do |page|
      page.about "/about", :id => 'about', :uri => 'about'
      page.jobs "/jobs", :id => 'jobs', :uri => 'jobs'
      page.faq "/faq", :id => 'faq', :uri => 'faq'
      page.terms_of_service "/terms-of-service", :id => 'terms-of-service', :uri => 'terms-of-service'
      page.privacy_policy "/privacy-policy", :id => 'privacy-policy', :uri => 'privacy-policy'
      page.guidelines "/guidelines", :id => 'guidelines', :uri => 'guidelines'
    end

    #=== account
    front.resource :account, :as => "settings", :controller => 'account/accounts', :collection => {
      :unlink_fb_connect => :get
    }, :member => {
      :statistics => :get
    } do |account|
      account.resource :session, :controller => 'account/sessions'
      account.resources :orders, :controller => 'account/orders'
      account.resources :purchase_orders, :controller => 'account/purchase_orders'
      account.resources :sales_orders, :controller => 'account/sales_orders'
      account.resources :invoices, :controller => 'account/invoices'
      account.resources :purchase_invoices, :controller => 'account/purchase_invoices'
      account.resources :sales_invoices, :controller => 'account/sales_invoices'

      account.resource :email, :controller => 'account/emails'
      account.resource :password, :controller => 'account/passwords'
      account.resource :personal, :controller => 'account/personals'
      account.resource :international, :controller => 'account/internationals'
      account.resource :notification, :controller => 'account/notifications'
      account.resource :close, :controller => 'account/closes'
      account.resource :vanity, :controller => 'account/vanities'
      account.resource :address, :controller => 'account/addresses', :member => {
        :personal => :get,
        :business => :get,
        :billing => :get
      }
      # account/bank
      account.resource :bank, :controller => 'account/bank/banks' do |bank|
        bank.resource :deposit, :controller => 'account/bank/deposits', :member => {
          :complete => :get
        }
        bank.resource :transfer, :controller => 'account/bank/transfers', :member => {
          :complete => :get
        }
        bank.resources :transactions, :controller => 'account/bank/transactions'
      end
    end

    #=== admin application
    front.namespace :admin do |admin|
      admin.resource :session
      admin.resource :translation do |translation|
        translation.resources :view_translations, :member => {:locate => :get}
        translation.resources :model_translations
      end
      admin.with_options :active_scaffold => true do |admin_with_scaffold|
        admin_with_scaffold.resources :admin_users, :controller => 'admin_users', :member => {
          :toggle_suspend   => :post
        }
        admin_with_scaffold.resources :users, :controller => 'users', :member => {
          :toggle_suspend   => :post
        }
        admin_with_scaffold.resources :beta_users, :controller => 'beta_users', :member => {
          :toggle   => :post
        }
        admin_with_scaffold.resources :people

        [:tiers, :organization].each do |tier_res|
          admin_with_scaffold.resources tier_res, :member => {
            :toggle_suspend => :post,
            :activate => :post,
            :erase => :post
          }
        end

        admin_with_scaffold.resources :topics, :member => {
          :toggle_suspend => :post,
          :activate => :post,
          :erase => :post
        }

        admin_with_scaffold.resources :claimings, :member => {
          :accept => :post,
          :decline => :post,
        }

        admin_with_scaffold.resources :kases, :member => {
          :toggle_suspend => :post,
          :activate => :post,
          :erase => :post
        }

        admin_with_scaffold.resources :pages
        admin_with_scaffold.resources :academic_titles
        admin_with_scaffold.resources :personal_statuses

        admin_with_scaffold.resources :severities
        admin_with_scaffold.resources :spoken_languages
        admin_with_scaffold.resources :tier_categories
      end
    end
    front.admin '/admin', :controller => 'admin/admin_application'

    #--- home page
    front.with_options :controller => 'home_pages' do |home|
      home.root :action => 'index'
      home.homepage '/', :action => 'index'
  #    home.connect ':locale', :action => 'index', :requirements => {:locale => /[a-z]{2,2}/}
    end

  end

  #=== tier application
  map.subdomain :model => :tier do |tier|
    tier.root :action => "index", :controller => "tiers"
    tier.resources :searches, :as => "search", :only => :show
    tier.resources :tags, :collection => {:autocomplete => :get}
    tier.resources :people
    tier.resources :members
    tier.resources :locations
  
    #--- tier/claimings e.g. /tiers/:tier_id/claimings/2ab4c2d/confirm
    tier.resources :claimings, :member => {
      :confirm => :get
    }
  
    #--- tier_topics_path(@tier, @topic), e.g. http://apple.luleka.com/topics/mac-mini
    tier.resources :topics do |topics|
      topics.resources :people
      topics.resources :members
    
      #--- new_tier_topic_problem_path(@tier, @topic) e.g. http://apple.luleka.com/topics/imac/problems/new
      [Kase, Problem, Question, Idea, Praise].each do |kase_class|

        # e.g. http://apple.luleka.com/topics/imac/ideas/recent
        topics.resources kase_class.resources_name, :as => kase_class.human_resources_name, :collection => {
          :recent => :get,
          :open => :get,
          :open_rewarded => :get,
          :popular => :get,
          :solved => :get,
          :lookup => :post
        }, :member => {
          :vote_up => :put,
          :vote_down => :put,
          :participants => :get,
          :followers => :get,
          :matching_people => :get,
          :visitors => :get,
          :location => :get
        }
      
        # e.g. http://apple.luleka.com/topics/imac/problems/search/foo
        # e.g. http://apple.luleka.com/topics/imac/problems/tags/bar+camp
        topics.resource kase_class.resource_name, :as => kase_class.human_resources_name do |kase|
          kase.resources :searches, :as => "search", :only => :show
          kase.resources :tags, :collection => {:autocomplete => :get}
        end
      end
    end
  
    # e.g. tier_topic_search_path(@tier, :id => "foo"), e.g. http://apple.luleka.com/topics/search/foo
    # e.g. tier_topic_tag_path(@tier, :id => "foo"), e.g. http://apple.luleka.com/topics/search/foo
    tier.resource :topic, :as => :topics do |topic|
      topic.resources :searches, :as => "search", :only => :show
      topic.resources :tags, :collection => {:autocomplete => :get}
    end

    #--- tier_problems_path(@tier) e.g. http://apple.luleka.com/problems
    [Kase, Problem, Question, Idea, Praise].each do |kase_class|
      tier.resources kase_class.resources_name, :as => kase_class.human_resources_name, :collection => {
        :recent => :get,
        :open => :get,
        :open_rewarded => :get,
        :popular => :get,
        :solved => :get,
        :lookup => :post
      }, :member => {
        :vote_up => :put,
        :vote_down => :put,
        :participants => :get,
        :followers => :get,
        :matching_people => :get,
        :visitors => :get,
        :location => :get
      } do |kases|
        kases.resources :locations
      end
      
      # e.g. http://apple.luleka.com/topics/imac/problems/search/foo
      tier.resource kase_class.resource_name, :as => kase_class.human_resources_name do |kase|
        kase.resources :searches, :as => "search", :only => :show
        kase.resources :tags, :collection => {:autocomplete => :get}
      end
      
    end

    #--- overrides tier_topic_path(:id) e.g. http://apple.luleka.com/imac
    tier.topic ':id', :controller => 'topics', :action => 'show'
  end
  
  #--- standard routes
  map.connect ':controller/service.wsdl', :action => 'wsdl'
  map.connect ':locale/:controller/:action/:id'
  map.connect ':controller/:action/:id'

end
