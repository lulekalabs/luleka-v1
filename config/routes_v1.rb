ActionController::Routing::Routes.draw do |map|
  
  #=== front end application

  #--- session
  map.resource :session, :controller => 'sessions'

  #--- search
  map.search "search", :controller => "searches"

  #--- user partners
  map.resource :user, :as => "users" do |partner|
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
  map.resources :users, :collection => {
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
  map.resource :voucher, :collection => {
    :verification_code => :get,
    :complete => :get
  }

  #--- communities
  [:tiers, :organizations].each do |tier_res|

    # search tiers e.g. /communities/search/:id
    map.resources :searches, :as => "search", :only => [:index],
      :path_prefix => "/#{tier_res == :tiers ? 'communities' : tier_res}",
      :name_prefix => "#{tier_res}_"

    # tags tiers e.g. /communities/tags/:id
    map.resources :tags, 
      :path_prefix => "/#{tier_res == :tiers ? 'communities' : tier_res}",
      :name_prefix => "#{tier_res}_", 
      :collection => {:autocomplete => :post}

    map.resources tier_res, :as => "#{tier_res == :tiers ? 'communities' : tier_res}", :member => {
      :claim => :get,
      :list_item_expander => :post
    }, :collection => {
      :plans => :get,
      :complete => :get,
      :recent => :get,
      :popular => :get,
      :search_field => :get,
      :select_field => :get
    } do |organizations|
      organizations.resources :people
      organizations.resources :members
      organizations.resource :widgets, :controller => 'widgets/widget_application' do |widgets|
        widgets.resource :feedback, :controller => 'widgets/feedbacks', :collection => {:lookup => :post} 
      end
      
      # topic/kases
      # e.g. /organizations/:organization_id/products/:product_id/questions/new
      [:topics, :products, :services].each do |topic_res|
        
        # search topics e.g. /communities/apple/topics/search/:id
        map.resources :searches, :as => "search", :only => [:index],
          :path_prefix => "/#{tier_res == :tiers ? 'communities' : tier_res}/:tier_id/#{topic_res}",
          :name_prefix => "#{tier_res.to_s.singularize}_#{topic_res}_"
        
        # tags topics e.g. /communities/apple/topics/tags/:id
        map.resources :tags, 
          :path_prefix => "/#{tier_res == :tiers ? 'communities' : tier_res}/:tier_id/#{topic_res}",
          :name_prefix => "#{tier_res.to_s.singularize}_#{topic_res}_",
          :collection => {:autocomplete => :post}
        
        organizations.resources topic_res, :collection => {:recent => :get, :popular => :get} do |topics|
          topics.resources :people
          topics.resources :members
          topics.resource :widgets, :controller => 'widgets/widget_application' do |widgets|
            widgets.resource :feedback, :controller => 'widgets/feedbacks', :collection => {:lookup => :post} 
          end
          
          [:kases, :problems, :questions, :ideas, :praises].each do |kase_res|

            # search kases e.g. /communities/apple/topics/imac/cases/search/:id
            map.resources :searches, :as => "search", :only => [:index],
              :path_prefix => "/#{tier_res == :tiers ? 'communities' : tier_res}/:tier_id/#{topic_res}/:topic_id/#{kase_res == :kases ? 'cases' : kase_res}",
              :name_prefix => "#{tier_res.to_s.singularize}_#{topic_res.to_s.singularize}_#{kase_res}_"

            # tags kases e.g. /communities/apple/topics/imac/cases/tags/:id
            map.resources :tags, 
              :path_prefix => "/#{tier_res == :tiers ? 'communities' : tier_res}/:tier_id/#{topic_res}/:topic_id/#{kase_res == :kases ? 'cases' : kase_res}",
              :name_prefix => "#{tier_res.to_s.singularize}_#{topic_res.to_s.singularize}_#{kase_res}_"
              
            topics.resources kase_res, :as => kase_res == :kases ? "cases" : "#{kase_res}", :collection => {
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
          end
        end
      end

      # community-kases
      # e.g. /tiers/:tier_id/problems
      [:kases, :problems, :questions, :ideas, :praises].each do |kase_res|
        
        # search kases e.g. /communities/luleka/cases/tags/:id
        map.resources :searches, :as => "search", :only => [:index],
          :path_prefix => "/communities/:tier_id/#{kase_res == :kases ? 'cases' : kase_res}",
          :name_prefix => "community_#{kase_res}_"

        # tags kases e.g. /communities/luleka/cases/tags/:id
        map.resources :tags, 
          :path_prefix => "/communities/:tier_id/#{kase_res == :kases ? 'cases' : kase_res}",
          :name_prefix => "community_#{kase_res}_"
        
        organizations.resources kase_res, :as => kase_res == :kases ? "cases" : "#{kase_res}", :collection => {
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
      end
      
      # e.g. /tiers/:tier_id/claimings
      organizations.resources :claimings, :member => {
        :confirm => :get
      }
      
      # e.g. /tiers/:tier_id/locations
      organizations.resources :locations
    end
  end
  
  #--- kases
  [:kases, :problems, :questions, :ideas, :praises].each do |kase_res|

    # search kases e.g. /cases/search/:id
    map.resources :searches, :as => "search", :only => [:index],
      :path_prefix => "/#{kase_res == :kases ? 'cases' : kase_res}",
      :name_prefix => "#{kase_res}_"

    # tags kases /cases/tags/:id
    map.resources :tags, 
      :path_prefix => "/#{kase_res == :kases ? 'cases' : kase_res}",
      :name_prefix => "#{kase_res}_", :collection => {:autocomplete => :post}

    map.resources kase_res, :as => kase_res == :kases ? "cases" : "#{kase_res}", :collection => {
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
      kases.resource :tag # for tag in place editor
    end
  end

  #--- responses
  map.activate_response "/responses/:id/activate", :controller => 'responses', :action => 'activate'
  
  #--- comments
  map.activate_comment "/comments/:id/activate", :controller => 'comments', :action => 'activate'

  #--- flags
  map.resources :flags

  #--- invitations
  map.resources :invitations, :collection => {
    :complete => :get,
    :update_message => :get
  }, :member => {
    :accept => :post,
    :decline => :post,
    :remind => :post,
    :confirm => :get,
    :list_item_expander => :post
  }
  map.open_invitation 'contacts/invite/:id', :controller => 'contacts', :action => 'invite', :id => ''
  
  #--- contacts
  map.resources :contacts, :collection => {
    :pending => :get
  }, :member => {
    :shared => :get
  }

  #--- people
  # search people e.g. /people/search/:id
  map.resources :searches, :as => "search", :only => [:index],
    :path_prefix => "/people", :name_prefix => "people_"

  # tags people e.g. /people/tags/:id
  map.resources :tags, :path_prefix => "/people", :name_prefix => "people_"
  
  # tags kases /cases/tags/:id
  map.resources :tags, 
    :path_prefix => "/people",
    :name_prefix => "people_", :collection => {:autocomplete => :post}
  
  map.resources :people, :member => {
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

  #--- static pages
  map.with_options :controller => 'pages', :action => 'show' do |page|
    page.about "/about", :id => 'about', :uri => 'about'
    page.jobs "/jobs", :id => 'jobs', :uri => 'jobs'
    page.faq "/faq", :id => 'faq', :uri => 'faq'
    page.terms_of_service "/terms-of-service", :id => 'terms-of-service', :uri => 'terms-of-service'
    page.privacy_policy "/privacy-policy", :id => 'privacy-policy', :uri => 'privacy-policy'
    page.guidelines "/guidelines", :id => 'guidelines', :uri => 'guidelines'
  end
  
  #=== account
  map.resource :account, :as => "settings", :controller => 'account/accounts', :collection => {
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
  map.namespace :admin do |admin|
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
  map.admin '/admin', :controller => 'admin/admin_application'

  #--- home page
  map.with_options :controller => 'home_pages' do |home|
    home.root :action => 'index'
    home.homepage '/', :action => 'index'
#    home.connect ':locale', :action => 'index', :requirements => {:locale => /[a-z]{2,2}/}
  end
  
  map.luleka_kases '/luleka', :controller => 'tiers', :action => 'show', :id => 'luleka', :uri => 'luleka'
  map.new_luleka_kase '/communities/luleka/cases/new', :controller => 'kases', :action => 'new', :tier => 'luleka', :uri => 'communities/luleka/cases/new'
  map.new_luleka_question '/communities/luleka/questions/new', :controller => 'questions', :action => 'new', :tier => 'luleka', :uri => 'communities/luleka/questions/new'
  map.new_luleka_problem '/communities/luleka/problems/new', :controller => 'problems', :action => 'new', :tier => 'luleka', :uri => 'communities/luleka/problems/new'
  map.new_luleka_praise '/communities/luleka/praises/new', :controller => 'praises', :action => 'new', :tier => 'luleka', :uri => 'communities/luleka/praises/new'
  map.new_luleka_idea '/communities/luleka/ideas/new', :controller => 'ideas', :action => 'new', :tier => 'luleka', :uri => 'communities/luleka/ideas/new'
  
  #--- standard routes
  map.connect ':id', :controller => 'tiers', :action => 'show'
  map.connect ':tier_id/:id', :controller => 'topics', :action => 'show'
  
  map.connect ':controller/service.wsdl', :action => 'wsdl'
  map.connect ':locale/:controller/:action/:id'
  map.connect ':controller/:action/:id'

end
