require File.dirname(__FILE__) + '/lib/friendship_plugin'
ActiveRecord::Base.send( :include, FriendshipPlugin::UserExtensions )