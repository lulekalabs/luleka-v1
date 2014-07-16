module AuthenticatedTestHelper

  def with_subdomain(subdomain=nil)
    the_host_name = "luleka.local"
    the_host_name = "#{subdomain}.#{the_host_name}" if subdomain
    @request.host = the_host_name
    @request.env['SERVER_NAME'] = the_host_name
    @request.env['HTTP_HOST'] = the_host_name
  end
  
  # Sets the current user in the session from the user fixtures.
  def login_as(user)
    unless user.is_a?(User)
      user = users(user)
    end
    @request.session[:user_id] = user.id
  end
    
  def logout 
    @request.session[:user_id] = nil
  end
  
  def current_user 
    if user_id = @request.session[:user_id]
      User.find_by_id(user_id)
    end
  end
  
  def admin_login_as(user)
    @request.session[:admin_user_id] = admin_users(user).id
  end
  
  def current_admin_user 
    if user_id = @request.session[:admin_user_id]
      AdminUser.find_by_id(user_id)
    end
  end

  def admin_logout
    @request.session[:admin_user_id] = nil
  end

  def account_login_as(user)
    unless user.is_a?(User)
      user = users(user)
    end
    @request.session[:user_account_id] = user.id
  end
    
  def current_account_user 
    if user_id = @request.session[:user_account_id]
      User.find_by_id(user_id)
    end
  end

  def account_logout 
    @request.session[:user_account_id] = nil
  end
  
  def assert_requires_login *args
    get args
    assert_redirected_to :controller => 'sessions', :action => 'new'
  end
  
  def assert_requires_admin_login *args
    get args
    assert_redirected_to :controller => 'admin/sessions', :action => 'new'
  end

  def content_type(type)
    @request.env['Content-Type'] = type
  end

  def accept(accept)
    @request.env["HTTP_ACCEPT"] = accept
  end

  def authorize_as(user)
    if user
      @request.env["HTTP_AUTHORIZATION"] = "Basic #{Base64.encode64("#{users(user).login}:test")}"
      accept       'application/xml'
      content_type 'application/xml'
    else
      @request.env["HTTP_AUTHORIZATION"] = nil
      accept       nil
      content_type nil
    end
  end

  # http://project.ioni.st/post/217#post-217
  #
  #  def test_new_publication
  #    assert_difference(Publication, :count) do
  #      post :create, :publication => {...}
  #      # ...
  #    end
  #  end
  # 
  def assert_difference(object, method = nil, difference = 1)
    initial_value = object.send(method)
    yield
    assert_equal initial_value + difference, object.send(method), "#{object}##{method}"
  end

  def assert_no_difference(object, method, &block)
    assert_difference object, method, 0, &block
  end

  # Assert the block redirects to the login
  # 
  #   assert_requires_login(:bob) { |c| c.get :edit, :id => 1 }
  #
  def assert_requires_login_old(login = nil)
    yield HttpLoginProxy.new(self, login)
  end

  def assert_http_authentication_required(login = nil)
    yield XmlLoginProxy.new(self, login)
  end

  def reset!(*instance_vars)
    instance_vars = [:controller, :request, :response] unless instance_vars.any?
    instance_vars.collect! { |v| "@#{v}".to_sym }
    instance_vars.each do |var|
      instance_variable_set(var, instance_variable_get(var).class.new)
    end
  end
end

class BaseLoginProxy
  attr_reader :controller
  attr_reader :options
  def initialize(controller, login)
    @controller = controller
    @login      = login
  end

  private
    def authenticated
      raise NotImplementedError
    end
    
    def check
      raise NotImplementedError
    end
    
    def method_missing(method, *args)
      @controller.reset!
      authenticate
      @controller.send(method, *args)
      check
    end
end

class HttpLoginProxy < BaseLoginProxy
  protected
    def authenticate
      @controller.login_as @login if @login
    end
    
    def check
      @controller.assert_redirected_to :controller => @controller.account_controller.to_s, :action => 'login'
    end
end

class XmlLoginProxy < BaseLoginProxy
  protected
    def authenticate
      @controller.accept 'application/xml'
      @controller.authorize_as @login if @login
    end
    
    def check
      @controller.assert_response 401
    end
end