require File.dirname(__FILE__) + '/../test_helper'

class PiggyBankAccountTransactionTest < ActiveSupport::TestCase

  def test_number
    assert create_transaction.number
  end
  
  def test_strip_number_formatting
    assert_equal "0c77727804f3b943bd455d61441d7d76a789e4f7",
      PiggyBankAccountTransaction.strip_number_formatting(
        "0c77727804-f3b943-bd455d-61441d-7d76a7-89e4f7"
      )
  end
  
  def test_should_get_short_number
    assert /TA-*/i.match(PiggyBankAccountTransaction.new.short_number)
  end
  
  protected 
  
  def create_piggy_bank_account_transaction(options={})
    PiggyBankAccountTransaction.create(valid_piggy_bank_account_transaction_attributes(options))
  end
  alias_method :create_transaction, :create_piggy_bank_account_transaction

  def build_piggy_bank_account_transaction(options={})
    PiggyBankAccountTransaction.new(valid_piggy_bank_account_transaction_attributes(options))
  end
  alias_method :build_transaction, :build_piggy_bank_account_transaction
  
  def valid_piggy_bank_account_transaction_attributes(options={})
    {
      :amount => Money.new(100, 'EUR'),
      :action => 'withdraw',
    }
  end
  
end
