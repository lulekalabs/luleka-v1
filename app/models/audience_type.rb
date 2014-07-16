# Provides a set of options for the kase offer_audience_type or
# the "viewability" of the kase
class AudienceType < ActiveRecord::Base
  #--- constants
  OFFER_KINDS = [:open, :matching_partner, :matching_friend, :matching_member]
  FIXED_OFFER_KINDS = [:open, :friend, :matching_friend]
  PROBONO_OFFER_KINDS = [:open, :partner, :matching_partner, :friend, :matching_friend]
  
  #--- associations
  has_many :kases
  
  #--- mixins
  self.keep_translations_in_model = true
  translates :name, :base_as_default => true
  
  #--- class variables
  @@open = nil
  @@partner = nil
  @@matching_partner = nil
  @@friend = nil
  @@matching_friend = nil
  @@member = nil
  @@matching_member = nil
  
  @@offer_types = nil
  @@offer_type_ids = nil

  #--- class methods
  class << self
    
    def open_id
      open ? open.id : nil
    end

    def open
      @@open || @@open = find_by_kind('open')
    end

    def partner_id
      partner ? partner.id : nil
    end

    def partner
      @@partner || @@partner = find_by_kind('partner')
    end

    def matching_partner_id
      matching_partner ? matching_partner.id : nil
    end

    def matching_partner
      @@matching_partner || @@matching_partner = find_by_kind('matching_partner')
    end
    
    def friend_id
      friend ? friend.id : nil
    end

    def friend
      @@friend || @@friend = find_by_kind('friend')
    end

    def matching_friend_id
      matching_friend ? matching_friend.id : nil
    end

    def matching_friend
      @@matching_friend || @@matching_friend = find_by_kind('matching_friend')
    end

    # member in the sence of employee for organizations, member for tiers
    def member_id
      member ? member.id : nil
    end

    def member
      @@member || @@member = find_by_kind('member')
    end

    # member in the sence of employee for organizations, member for tiers
    def matching_member_id
      matching_member ? matching_member.id : nil
    end

    def matching_member
      @@matching_member || @@matching_member = find_by_kind('matching_member')
    end


    def find_for_offer
      @offer_types || @offer_types = find(:all, find_for_offer_options)
    end

    def find_for_offer_ids
      @offer_type_ids || @offer_type_ids = find(:all, find(:all, find_for_offer_options)).map(&:id)
    end

    def find_for_offer_options(options={})
      {:conditions => ["audience_types.kind IN (?)", OFFER_KINDS.map(&:to_s)]}.merge(options)
    end

    def find_for_probono_offer
      @probono_offer_types || @probono_offer_types = find(:all, find_for_probono_offer_options)
    end
    
    def find_for_probono_offer_ids
      @probono_offer_type_ids || @probono_offer_type_ids = find(:all, find(:all, find_for_probono_offer_options)).map(&:id)
    end
    
    def find_for_probono_offer_options(options={})
      {:conditions => ["audience_types.kind IN (?)", PROBONO_OFFER_KINDS.map(&:to_s)]}.merge(options)
    end

    def find_for_fixed_offer
      @fixed_offer_types || @fixed_offer_types = find(:all, find_for_fixed_offer_options)
    end
    
    def find_for_fixed_offer_ids
      @fixed_offer_type_ids || @fixed_offer_type_ids = find(:all, find(:all, find_for_fixed_offer_options)).map(&:id)
    end
    
    def find_for_fixed_offer_options(options={})
      {:conditions => ["audience_types.kind IN (?)", FIXED_OFFER_KINDS.map(&:to_s)]}.merge(options)
    end

  end
  
  #--- instant methods
  
  def kind
    self[:kind].to_sym
  end

  def kind=(a_kind)
    self[:kind] = a_kind.to_s if a_kind
  end
  
  def to_s
    self.name
  end
  
  def to_sym
    self.kind
  end
  
end
