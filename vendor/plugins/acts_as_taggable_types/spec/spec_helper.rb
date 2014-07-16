require File.dirname(__FILE__) + '/../../../../spec/spec_helper'

module Spec::Example::ExampleGroupMethods
  alias :context :describe
end

plugin_spec_dir = File.dirname(__FILE__)
ActiveRecord::Base.logger = Logger.new(plugin_spec_dir + "/debug.log")

load(File.dirname(__FILE__) + '/schema.rb')

class TaggableModel < ActiveRecord::Base
  acts_as_taggable_types :skills, :languages
end

class OtherTaggableModel < ActiveRecord::Base
  acts_as_taggable_types :languages
end

class InheritingTaggableModel < TaggableModel
end

class AlteredInheritingTaggableModel < TaggableModel
  acts_as_taggable_types :parts
end

class TaggableUser < ActiveRecord::Base
#  acts_as_tagger
end

class UntaggableModel < ActiveRecord::Base
end