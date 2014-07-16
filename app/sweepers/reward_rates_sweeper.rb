# This cache sweeper connects with the reward rates
# whenever one is updated the effect should appear
# on the FAQ page, etc.
#
class RewardRatesSweeper < ActionController::Caching::Sweeper
  include CacheKeys
  observe RewardRate

  # if our sweeper detects that a Page was created call this
  def after_save(page)
    expire_cache_for(page)
  end

  # if our sweeper detects that a Page was deleted call this
  def after_destroy(page)
    expire_cache_for(page)
  end

  private
  
  def expire_cache_for(record)
    expire_fragment(%r{#{faq_page_fragment_cache_key(record.tier, true)}*})
  end
  
end
