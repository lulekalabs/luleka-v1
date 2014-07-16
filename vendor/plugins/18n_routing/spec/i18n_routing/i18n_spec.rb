require 'spec_helper'

describe :localized_routes do
  before(:all) do

    if !rails3?
      ActionController::Routing::Routes.clear!
      ActionController::Routing::Routes.draw do |map|
        map.not_about 'not_about', :controller => 'not_about'
        map.resources :not_users
        map.resource  :not_contact

        map.localized do
          map.about 'about', :controller => 'about', :action => :show

          map.resources :users
          map.resource  :contact

          map.resources :authors do |m|
            m.resources :books
          end

          map.resources :universes do |m|
            m.resources :galaxies do |mm|
              mm.resources :planets
            end
          end
        end
      end
      
      @r = ActionController::Routing::Routes
      
      class UrlTester
        include ActionController::UrlWriter
      end

    else
      @r = ActionDispatch::Routing::RouteSet.new
      @r.draw do
        match 'not_about' => "not_about#show", :as => :not_about
        resources :not_users
        resource  :not_contact

        localized(I18n.available_locales, :verbose => true) do
          match 'about' => "about#show", :as => :about

          resources :users
          resource  :contact

          resources :authors do
            resources :books
          end

          resources :universes do
            resources :galaxies do
              resources :planets
            end
          end

        end
      end
           
      class UrlTester; end
      UrlTester.send :include, @r.url_helpers

    end

  end

  let(:nested_routes) { @r.named_routes.instance_eval { routes } }
  let(:routes) { UrlTester.new }

  def url_for(opts)
    @r.generate_extras(opts).first
  end

  context "do not break existing behavior" do

    it "of named_routes" do
      routes.send(:not_about_path).should == "/not_about"
    end

    it "of a singular resource" do
      routes.send(:not_contact_path).should == "/not_contact"
    end

    it "of resources" do
      routes.send(:not_users_path).should == "/not_users"
    end

  end

  context "for default routes" do

    before do
      I18n.locale = :de # Not localized
    end

    it "named_route uses default values" do
      routes.send(:about_path).should == "/about"
    end

    it "resource generates routes using default values" do
      routes.send(:contact_path).should == "/contact"
    end

    it "resources generates routes using default values" do
      routes.send(:users_path).should == "/users"
    end

    it "url_for generates route using default values" do
      url_for(:controller => :users).should == "/users"
    end

    it "nested resources generate routes using default values" do
      routes.send(:author_books_path, 1).should == "/authors/1/books"
    end

    it "deep nested resources generate routes using default values" do
      routes.send(:universes_path).should == "/universes"
      routes.send(:universe_galaxies_path, 1).should == "/universes/1/galaxies"
      routes.send(:universe_galaxy_planets_path, 1, 1).should == "/universes/1/galaxies/1/planets"
    end

  end

  context "" do

    before do
      I18n.locale = :fr
    end

    it "named_route generates route using localized values" do
      routes.send(:about_path).should == "/#{I18n.t :about, :scope => :named_routes_path}"
    end

    it "resource generates routes using localized valuess" do
      routes.send(:contact_path).should == "/#{I18n.t :contact, :scope => :resource}"
    end

    it "resources generates routes using localized values" do
      routes.send(:users_path).should == "/#{I18n.t :users, :scope => :resources}"
    end

    it "url_for generates routes using localized values" do
      url_for(:controller => :users).should == "/#{I18n.t :users, :scope => :resources}"
      url_for(:controller => :about, :action => :show).should == "/#{I18n.t :about, :scope => :named_routes_path}"
    end

    it "nested resources generate routes using localized values" do
      routes.send(:author_books_path, 1).should == "/#{I18n.t :authors, :scope => :resources}/1/#{I18n.t :books, :scope => :resources}"
    end

    it "deep nested resources generate routes using localized values" do
      routes.send(:universes_path).should == "/#{I18n.t :universes, :scope => :resources}"
      routes.send(:universe_galaxies_path, 1).should == "/#{I18n.t :universes, :scope => :resources}/1/#{I18n.t :galaxies, :scope => :resources}"
      routes.send(:universe_galaxy_planets_path, 1, 1).should == "/#{I18n.t :universes, :scope => :resources}/1/#{I18n.t :galaxies, :scope => :resources}/1/#{I18n.t :planets, :scope => :resources}"
    end

    context "when nested" do

      it "named routes should not be nil" do
        nested_routes[:author_fr_books].should_not be_nil
      end

      context "in Rails #{Rails.version}" do
        it "include the correct significant keys" do
          v = !rails3? ? :significant_keys : :segment_keys
          nested_routes[:author_books].send(v).should include(:author_id)
          nested_routes[:author_fr_books].send(v).should include(:author_id)
        end
      end

    end

    context "when deeply nested" do

      it "named routes should not be nil" do
        nested_routes[:universe_galaxy_fr_planet].should_not be_nil
      end

      context "in Rails #{Rails.version}" do
        it "include the correct significant keys" do
          v = !rails3? ? :significant_keys : :segment_keys
          nested_routes[:universe_galaxy_planet].send(v).should include(:universe_id)
          nested_routes[:universe_galaxy_fr_planet].send(v).should include(:universe_id)
          nested_routes[:universe_galaxy_planet].send(v).should include(:galaxy_id)
          nested_routes[:universe_galaxy_fr_planet].send(v).should include(:galaxy_id)
        end
      end
    end

    it "nested resources do not deep translate with multi helpers" do
      nested_routes.keys.should_not include(:fr_author_books) # Want fr_author_books
    end

  end

end
