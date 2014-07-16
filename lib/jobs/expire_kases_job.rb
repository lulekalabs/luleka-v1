# Expires kases who may have expired already
class ExpireKasesJob

  def perform

    Kase.find_in_batches(Kase.find_in_batches_options_for_expired) do |group|
      group.each do |kase|
        kase.class.transaction do 
          kase.lock!
          kase.expire!
        end
      end
    end

  end

end  
