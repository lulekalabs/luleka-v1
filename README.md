# Welcome to Luleka

Luleka is an online community to create trusted connections with professionals (a la Angie’s List but for consultants), such as lawyers, accountants, architects, brokers, engineers.

## Setup MySQL

```
mysqladmin -u root -p create luleka_development
mysqladmin -u root -p create luleka_test
mysqladmin -u root -p create luleka_production
mysqladmin -u root -p create luleka_staging

mysql -u root -p
```

``` SQL
GRANT ALL ON luleka_production.* TO 'rails'@'localhost' IDENTIFIED BY 'password';
GRANT FILE ON *.* TO 'rails'@'localhost' IDENTIFIED BY 'password'; 
FLUSH PRIVILEGES; 

ALTER DATABASE `luleka_development` DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER DATABASE `luleka_test` DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER DATABASE `luleka_production` DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER DATABASE `luleka_staging` DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
```

## SQL dumps

    mysqldump -u root luleka_development > dump.sql

and importing

    mysql -u root luleka_development < dump.sql 

## Setup SSH keys

    ssh-keygen -t dsa

    authme production.corp.luleka.net

    ssh-agent sh -c 'ssh-add < /dev/null && bash'

    ssh production.corp.luleka.net

## Hosts

For local development and testing add the following to your etc/hosts

    luleka.local 127.0.0.1
    us.luleka.local 127.0.0.1
    de.luleka.local 127.0.0.1
    ...

## RSpec

Install rspec on your system by using

    sudo gem install rspec

or follow the instructions to install the plugins on 

http://github.com/dchelimsky/rspec-rails/wikis/home


## Command Line Fu's

    find . \( -name "*.rb" -or -name "*.rhtml" -or -name "*.erb" \) | xargs grep -l 'luleka_div' | xargs sed -i -e 's/luleka_div/div/g'

## Required Gems

    sudo gem install money
    sudo gem install backgroundrb

## Optionals

    sudo gem install sysloglogger
    sudo gem install rails_analyzer_tools

## Capistrano Tasks

    cap deploy
    cap migrations             # deploy with migrations
    cap deprec:nginx:restart   # restart nginx


## Magic grep (@gruban)

    tail -f production.log | grep 'Completed' | grep -P '[1-9]\.\d\d\d\d\d'


## Wildcard subdomains without local DNS server through proxy.pac

```
# ~.proxy.pac
#
# E.g.
#
#   Firefox > Preferences > Advanced > Network > Settings... > Automatic Proxy Configuration URL:
#     file:///Users/USERNAME/.proxy.pac
#  
#   Mac: System Preferences > Network > Proxy > Manual > Using Pac file
#
function FindProxyForURL(url, host) {
  if (shExpMatch(host, "*wak.local")) {
    return "PROXY localhost:8081";
  }
  return "DIRECT";
}

```