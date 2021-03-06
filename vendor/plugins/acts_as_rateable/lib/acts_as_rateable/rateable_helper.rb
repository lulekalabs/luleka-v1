module Acts
  module Rateable #:nodoc:
    module Helper #:nodoc:

      # Generates stars for an object that acts_as_rateable (or anything that responds_to 'rating')
      #
      # The first argument is anything that responds_to?("rating")
      #
      # If given a block, the container element and content, star index, and whether or not the star
      # is filled will be yielded each star (so options[:max] times).  The result of the block
      # will be used as the ultimate content for the star.  You can use this feature to
      # make the stars "active" to allow users to update ratings.
      #
      # Example:
      # 
      # stars(my_rateable_thing, :filled_star => "X", :empty_star => "x") do |content,rating,filled|
      #   link_to content, :controller => "rater", :action => "rate_me", :id => my_rateable_thing.id, :rating => rating
      # end
      #
      # will return 5 of something like "<a href="/rater/1/rate_me?rating=1"><span class='filled_star'>X</span></a>"
      # 
      # Available options:
      #
      # :max (default: 5) : The maximum number of stars (and therefore the maximum allowable rating) to show
      # :filled_star (default: "*") : The content to use for a filled star 
      #                               (example: if ratable.rating is 3, stars 1-3 will be filled, stars 4 and 5 will be empty) 
      # :empty_star (default: "") : The content to use for an empty star (see above)
      # :filled_class (default: "star_filled") : The CSS class to associate with a filled star's container
      # :empty_class (default: "star_empty") : The CSS class to associate with an empty star's container
      #
      # Any additional options will be passed to ActionView::Helpers::TagHelper#content_tag
      #
      def stars(rateable, opts={})
        options = options_for_stars(opts)
        the_content = String.new
        filled_class = options.delete(:filled_class)
        empty_class = options.delete(:empty_class)
        filled_star = options.delete(:filled_star)
        empty_star = options.delete(:empty_star)
        1.upto(options.delete(:max)) do |i|
          is_filled = rateable.rating >= i
          star_content = (is_filled ? filled_star : empty_star)
          star_content = yield star_content, i, is_filled if block_given?
          the_content << content_tag(:span,
            star_content, {
              :id => "rateable_#{rateable.id}_star_#{i}",
              :class => (is_filled ? filled_class : empty_class)
            }.update(options))
        end
        return the_content
      end
    
      private

      def options_for_stars(opts={})
        {:max => 5,
         :filled_star => "*",
         :empty_star => "",
         :filled_class => "star_filled",
         :empty_class => "star_empty"}.merge(opts)
      end
    
    end
  end
end