namespace :refactor do

  desc "Refactor all text using F=... T=... in all *.rb and *.rhtml files."
  task :replace do
    if ENV['F'] && ENV['T']
      puts 'creating file list for refactoring...'
      from = ENV['F'].gsub('"', '\"').gsub("'", "\'")
      to = ENV['T'].gsub('"', '\"').gsub("'", "\'")
      puts "(F)ROM=#{from}"
      puts "(T)O=#{to}"
      cmd = "find . \\( -path \"./db\" -prune \\) -or \\( -name \"*.rb\" -or -name \"*.rhtml\" -or -name \"*.rjs\" -or -name \"*.erb\" -or -name \"*.js\" \\) | xargs grep -l '#{from}'"
      puts cmd
      puts `#{cmd}`
    
      puts "\nconfirm (Y)es to continue:\n"
      confirm = STDIN.gets.chop
    
      if confirm == 'Y'
        # find and replaces
        cmd = "find . \\( -path \"./db\" -prune \\) -or \\( -name \"*.rb\" -or -name \"*.rhtml\" -or -name \"*.rjs\" -or -name \"*.erb\" -or -name \"*.js\" \\) | xargs grep -l '#{ENV['F']}' | xargs sed -i -e 's/#{from}/#{to}/g'"
        puts cmd
        puts `#{cmd}`
      
        # removes all file backups ending in *.rb-e or *.rhtml-e
        puts "cleanup..."
        cmd = "find . \\( -name \"*.rb-e\" -or -name \"*.rhtml-e\" -or -name \"*.rjs-e\" -or -name \"*.erb-e\" -or -name \"*.js-e\" \\) | xargs rm -r"
        puts cmd
        puts `#{cmd}`
      
        puts 'complete.'
      else
        puts 'nothing changed.'
      end
    else
      puts "Error: You need to specify F(rom) and T(o) parameters."
    end
  end

  task :find do
    if ENV['F']
      from = ENV['F']#.gsub('"', '\"').gsub("'", "\'")
      puts "(F)ROM=#{from}"
      puts 'finding...'
      cmd = "find . \\( -path \"./db\" -prune \\) -or \\( -name \"*.rb\" -or -name \"*.rhtml\" -or -name \"*.rjs\" -or -name \"*.erb\" -or -name \"*.js\" \\) | xargs grep -l '#{from}'"
      puts cmd
      puts `#{cmd}`
    else
      puts "Error: You need to specify F parameter for the search string."
    end
  end


end