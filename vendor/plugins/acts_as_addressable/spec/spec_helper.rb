require File.dirname(__FILE__) + '/../../../../spec/spec_helper'

plugin_spec_dir = File.dirname(__FILE__)
ActiveRecord::Base.logger = Logger.new(plugin_spec_dir + "/debug.log")

load(File.dirname(__FILE__) + '/schema.rb')

def valid_address_attributes(options={})
  {
    :first_name => "George",
    :last_name => "Bush",
    :gender => 'm',
    :street => "100 Washington St.",
    :postal_code => "95065",
    :city => "Santa Cruz",
    :province_code => "CA",
    :province => "California",
    :company_name => "Exxon",
    :phone => "+1 831 123-4567",
    :mobile => "+1 831 223-4567",
    :fax => "+1 831 323-4567",
    :country_code => "US",
    :country => "United States of America"
  }.merge(Address.middle_name? ? { :middle_name => "W." } : {}).merge(options)
end

class AddressableModel < ActiveRecord::Base
end

class HasOneSingleAddressModel < AddressableModel
  acts_as_addressable :has_one => true
end

class HasManySingleAddressModel < AddressableModel
  acts_as_addressable :has_many => true
end

class HasOneMultipleAddressModel < AddressableModel
  acts_as_addressable :billing, :shipping, :has_one => true
end

class HasManyMultipleAddressModel < AddressableModel
  acts_as_addressable :billing, :shipping, :has_many => true
end

