# update chache
namespace :data do
  namespace :update do
    
    desc "update counter caches"
    task :counters => :environment do 
      
      #--- tier counters
      Tier.find_in_batches do |tiers|
        tiers.each do |tier|
          tier.update_kases_count
          tier.update_members_count
          tier.update_people_count
          tier.update_topics_count
        end
      end

      #--- tier counters
      Topic.find_in_batches do |topics|
        topics.each do |topic|
          topic.update_kases_count
          topic.update_people_count
        end
      end

      #--- kase associations counters
      Kase.find_in_batches do |kases|
        kases.each do |kase|
          kase.update_associated_count
          kase.update_followers_count
          kase.update_voteable_cache
        end
      end
      
      #--- responses assocations counters
      Response.find_in_batches do |responses|
        responses.each do |response|
          response.update_voteable_cache
        end
      end
      
      #--- person counters
      Person.find_in_batches do |people|
        people.each do |person|
          person.update_kases_count
          person.update_responses_count
          person.update_friends_count
          person.update_followers_count
          person.update_received_votes_cache
        end
      end
      
    end
    
  end
end