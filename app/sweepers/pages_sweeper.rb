# This cache sweeper connects with the pages_controller
# and expires static pages loaded from the database
#
class PagesSweeper < ActionController::Caching::Sweeper
  observe Page

  # if our sweeper detects that a Page was created call this
  def after_create(page)
    expire_cache_for(page)
  end

  # if our sweeper detects that a Page was updated call this
  def after_update(page)
    expire_cache_for(page)
  end

  # if our sweeper detects that a Page was deleted call this
  def after_destroy(page)
    expire_cache_for(page)
  end

  private
  
  def expire_cache_for(record)
    expire_fragment(%r{#{record.permalink}-*})
  end
  
end
