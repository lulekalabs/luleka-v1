class Admin::PeopleController < Admin::AdminApplicationController

  #--- active scaffold
  active_scaffold :person do |config|
    #--- columns
    standard_columns = [
      :id,
      :academic_title_id,
      :first_name,
      :middle_name,
      :last_name,
      :email,
      :home_page_url,
      :blog_url,
      :personal_status_id,
      :summary,
      :tax_code,
      :default_response_quota,
      :current_response_quota,
      :response_quota_updated_at,
      :lat,
      :lng,
      :prefers_casual,
      :status,
      :created_at,
      :updated_at,
      :visits_count,
      :notify_on_newsletter,
      :notify_on_promotion,
      :notify_on_clarification_request,
      :notify_on_clarification_response,
      :notify_on_kase_matching,
      :notify_on_kase_status,
      :notify_on_comment_posted,
      :notify_on_comment_received,
      :notify_on_follower,
      :notify_on_following,
      :notify_on_response_posted,
      :notify_on_response_received,
      :voucher_quota,
      :gender,
      :permalink,
      :permalink_at,
      :avatar_file_name,
      :avatar_content_type,
      :avatar_file_size,
      :avatar_updated_at,
      :partner_at,
      :twitter_name,
      :show_name,
      :featured,
      # fake columns
      :name,
      :avatar,
      :avatar_url,
      # associations
      :personal_address,
      :business_address,
      :billing_address
    ]
    crud_columns = [
      :first_name,
      :middle_name,
      :last_name,
      :gender,
      :email,
      :avatar,
      :personal_status,
      :summary,
      :tax_code,
      :home_page_url,
      :visits_count,
      :current_response_quota,
      :default_response_quota,
      :prefers_casual,
      :voucher_quota,
      :show_name,
      :featured,
=begin      
      :personal_address,
      :business_address,
      :billing_address
=end      
    ]
    config.columns = standard_columns
    config.create.columns = crud_columns
    config.update.columns = crud_columns
    config.show.columns = crud_columns + [:status]
    config.list.columns = [:avatar_url, :name, :email, :status, :updated_at]
    
    config.create.multipart = true
    config.update.multipart = true
    
    #--- labels
    columns[:avatar_url].label = "Avatar"
    
  end  

  protected
  
  def list_authorized?
    current_user && current_user.has_role?(:moderator)
  end

  def create_authorized?
    current_user && current_user.has_role?(:moderator)
  end

  def update_authorized?
    current_user && current_user.has_role?(:moderator)
  end

  def delete_authorized?
    current_user && current_user.has_role?(:moderator)
  end
  
end
