module ActionView #:nodoc:
  module Acts #:nodoc:
    module TaggableTypes #:nodoc:

      # Generates tag cloud
      # Controller:
      #   @tags = Tag.tags(:limit => 100, :order => "name desc")
      #
      # View:
      #   <% tag_cloud @tags, %w(nube1 nube2 nube3 nube4 nube5) do |name, css_class| %>
      #      <%= link_to name, {:action => :tag, :id => name},
      #                  :class => css_class %>
      #   <% end %>
      #      
      # CSS:
      #   .nube1 {font-size: 1.0em;}
      #   .nube2 {font-size: 1.2em;}
      #   .nube3 {font-size: 1.4em;}
      #   .nube4 {font-size: 1.6em;}
      #   .nube5 {font-size: 1.8em;}
      #   .nube6 {font-size: 2.0em;}
      #
      def tag_cloud(tags, classes)
        max, min = 0, 0
        tags.each { |t|
          max = t.count.to_i if t.count.to_i > max
          min = t.count.to_i if t.count.to_i < min
        }

        divisor = ((max - min) / classes.size) + 1

        tags.each { |t|
          yield t, classes[(t.count.to_i - min) / divisor]
        }
      end
      
    end
  end
end