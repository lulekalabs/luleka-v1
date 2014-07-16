# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "http://luleka.com"
controller.request.host = "luleka.com"

SitemapGenerator::Sitemap.add_links do |sitemap|
  # Put links creation logic here.
  #
  # The root path '/' and sitemap index file are added automatically.
  # Links are added to the Sitemap in the order they are specified.
  #
  # Usage: sitemap.add path, options
  #        (default options are used if you don't specify)
  #
  # Defaults: :priority => 0.5, :changefreq => 'weekly', 
  #           :lastmod => Time.now, :host => default_host

  #--- static pages
  sitemap.add about_path, :lastmod => Time.now, :changefreq => 'always', :priority => 1.0
  sitemap.add jobs_path, :lastmod => Time.now, :changefreq => 'always', :priority => 1.0
  sitemap.add terms_of_service_path, :lastmod => Time.now, :changefreq => 'always', :priority => 1.0
  sitemap.add privacy_policy_path, :lastmod => Time.now, :changefreq => 'always', :priority => 1.0
  sitemap.add guidelines_path, :lastmod => Time.now, :changefreq => 'always', :priority => 1.0
  sitemap.add faq_path, :lastmod => Time.now, :changefreq => 'always', :priority => 1.0

  #--- people
  sitemap.add people_path, :priority => 0.7, :changefreq => 'daily'
  Person.find_in_batches(:batch_size => 100) do |people|
    people.each do |record|
      sitemap.add person_path(record), :lastmod => record.updated_at, :changefreq => 'daily'
    end
  end
  
  #--- kases
  sitemap.add kases_path, :priority => 0.7, :changefreq => 'daily'
  sitemap.add problems_path, :priority => 0.7, :changefreq => 'daily'
  sitemap.add questions_path, :priority => 0.7, :changefreq => 'daily'
  sitemap.add ideas_path, :priority => 0.7, :changefreq => 'daily'
  sitemap.add praises_path, :priority => 0.7, :changefreq => 'daily'

  Kase.find_in_batches(:batch_size => 100, :include => [:tiers, :topics]) do |kases|
    kases.each do |record|
      if record.topics.empty?
        sitemap.add path_for([record.tier, record]), :lastmod => record.updated_at
      else
        record.topics.each do |topic|
          sitemap.add path_for([record.tier, topic, record]), :lastmod => record.updated_at
        end
      end
    end
  end
  
  #--- tiers & topics
  Tier.find_in_batches(:batch_size => 100) do |tiers|
    tiers.each do |tier|
      sitemap.add path_for([tier]), :lastmod => tier.updated_at
      
      tier.topics.each do |topic|
        sitemap.add path_for([tier, topic]), :lastmod => topic.updated_at
      end
    end
  end

end
