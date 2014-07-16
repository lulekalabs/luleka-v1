module Admin::ViewTranslationsHelper

  # returns a number
  def percent(count, total)
    return Integer(Float(count)/Float(total)*10000) / Float(100) unless total == 0
    0
  end

end
