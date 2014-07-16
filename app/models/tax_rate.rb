class TaxRate < ActiveRecord::Base

  #--- class methods
  class << self
    
    # find tax rate depending on orgin and destination
    def find_tax_rate(options={})
      defaults = {:origin => {}, :destination => {}}
      options = defaults.merge(options).symbolize_keys
      options[:origin].symbolize_keys!
      options[:destination].symbolize_keys!
    
      destination = Address.new(options[:destination])
      tax_lines = self.find(:all, :conditions => {:country_code => destination.country_code})

      # wildcard matches have priority
      tax_lines.each {|l| return l.rate if l.province_code.to_s.index('*') }
      
      # exact province code match
      tax_lines.each do |l|
        l.province_code.to_s.split(',').map(&:strip).reject {|r| r.empty?}.map(&:upcase).each do |p|
          return l.rate if p == destination.province_code.to_s.upcase
        end
      end

      # otherwise no tax
      0.0
    end
    
  end
  
  #--- instance methods
  
  # each tax line has a qualifier, e.g. :vat for value added tax
  def kind
    self[:kind] ? self[:kind].to_sym : nil
  end
  
  def kind(a_kind)
    self[:kind] = a_kind if self[:kind]
  end
  
end
