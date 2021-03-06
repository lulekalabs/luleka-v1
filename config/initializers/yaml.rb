#--- YAML configuration
# fixing YAML bug described in
# http://itsignals.cascadia.com.au/?p=10
YAML.add_domain_type("ActiveRecord,2007", "") do |type, val|
  klass = type.split(':').last.constantize
  YAML.object_maker(klass, val)
end

class ActiveRecord::Base
  def to_yaml_type
    "!ActiveRecord,2007/#{self.class}"
  end
end

class ActiveRecord::Base
  def to_yaml_properties
    ['@attributes']
  end
end
