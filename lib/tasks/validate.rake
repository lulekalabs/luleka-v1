namespace :validate do
  task :people => :environment do
    puts "Validating all people..."
    Person.all.each do |person|
      unless person.valid?
        puts "Do you want to purge '#{person.user.login}'? (Y)es to proceed."
        puts "Reason: #{person.errors.full_messages}"
        confirm = STDIN.gets.chop
        if confirm == "Y"
          person.destroy
          puts "'#{person.user.login}' destroyed."
        end
      end
    end
    puts "done."
  end
end
