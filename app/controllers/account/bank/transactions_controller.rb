# Handles the account bank transactions
class Account::Bank::TransactionsController < Account::Bank::BanksController

  def index
    @bank = @person.piggy_bank
    @transactions = do_search_transactions(@bank.transactions)
  end
  
  def show
    @bank = @person.piggy_bank
    unless @transaction = @bank.transactions.find_by_number(PiggyBankAccountTransaction.strip_number_formatting(params[:id]))
      redirect_to account_bank_transactions_path
      return
    end
  end
  
end
