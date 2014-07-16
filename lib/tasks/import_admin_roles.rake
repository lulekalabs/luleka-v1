namespace :data do
  
  namespace :import do

    desc "create admin roles"
    task :admin_roles => :environment do 
      puts 'importing admin roles...'
      
      AdminRole.create(:kind => "admin", :name => "Admin (superuser)", :description => "Admin is the superuser role.") unless AdminRole.find_by_kind("admin")
      AdminRole.create(:kind => "translator", :name => "Translator", :description => "Is only allowed to change translation text.") unless AdminRole.find_by_kind("translator")
      AdminRole.create(:kind => "moderator", :name => "Moderator", :description => "Can adminstrate user generated content.") unless AdminRole.find_by_kind("moderator")
      AdminRole.create(:kind => "copywriter", :name => "Copywriter", :description => "Is allowed to change page content and sometimes translate text.") unless AdminRole.find_by_kind("copywriter")
      
      puts "adding admin role to 'admin' admin user"
      if au = AdminUser.find_by_login("admin")
        au.roles << AdminRole.find_by_kind("admin")
        au.save!
      end
      
      puts 'done.'
    end
    
  end
  
  namespace :purge do

    desc "purges admin roles"
    task :admin_roles => :environment do 
      puts 'purging admin roles...'
      AdminRole.destroy_all({:kind => "admin"})
      AdminRole.destroy_all({:kind => "translator"})
      AdminRole.destroy_all({:kind => "moderator"})
      AdminRole.destroy_all({:kind => "copywriter"})
      puts 'done.'
    end

  end
  
end