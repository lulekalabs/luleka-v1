# This cache sweeper connects with the view_translations_controller
# and expires all fragments with a local specific name
#
class TranslationsSweeper < ActionController::Caching::Sweeper
  observe Translation

  # if our sweeper detects that a Page was created call this
  def after_create(translation)
    expire_cache_for(translation)
  end

  # if our sweeper detects that a Page was updated call this
  def after_update(translation)
    expire_cache_for(translation)
  end

  # if our sweeper detects that a Page was deleted call this
  def after_destroy(translation)
    expire_cache_for(translation)
  end

  private
  
  def expire_cache_for(record)
    # sweep all fragments, no matter what
    expire_fragment(%r{.*})
  end
  
end
