# adds translations to credit card
module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class CreditCard
      
      private
      
      def validate_card_number #:nodoc:
        errors.add :number, I18n.t('activerecord.errors.messages.invalid') unless CreditCard.valid_number?(number)
        unless errors.on(:number) || errors.on(:type)
          errors.add :type, I18n.t('activerecord.errors.messages.invalid_credit_card') unless CreditCard.matching_type?(number, type)
        end
      end
      
      def validate_card_type #:nodoc:
        errors.add :type, I18n.t('activerecord.errors.messages.blank') if type.blank?
        errors.add :type, I18n.t('activerecord.errors.messages.invalid') unless CreditCard.card_companies.keys.include?(type)
      end
      
      def validate_essential_attributes #:nodoc:
        errors.add :first_name, I18n.t('activerecord.errors.messages.blank') if @first_name.blank?
        errors.add :last_name,  I18n.t('activerecord.errors.messages.blank') if @last_name.blank?
        errors.add :month,      I18n.t('activerecord.errors.messages.invalid') unless valid_month?(@month)
        errors.add :year,       I18n.t('activerecord.errors.messages.expired') if expired?
        errors.add :year,       I18n.t('activerecord.errors.messages.invalid') unless valid_expiry_year?(@year)
      end
      
      def validate_switch_or_solo_attributes #:nodoc:
        if %w[switch solo].include?(type)
          unless valid_month?(@start_month) && valid_start_year?(@start_year) || valid_issue_number?(@issue_number)
            errors.add :start_month,  I18n.t('activerecord.errors.messages.invalid') unless valid_month?(@start_month)
            errors.add :start_year,   I18n.t('activerecord.errors.messages.invalid') unless valid_start_year?(@start_year)
            errors.add :issue_number, I18n.t('activerecord.errors.messages.empty') unless valid_issue_number?(@issue_number)
          end
        end
      end
      
      def validate_verification_value #:nodoc:
        if CreditCard.requires_verification_value?
          errors.add :verification_value, I18n.t('activerecord.errors.messages.empty') unless verification_value? 
        end
      end
    end
  end
end
