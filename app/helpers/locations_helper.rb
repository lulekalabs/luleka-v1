module LocationsHelper
  #--- constants
  BASE_ICON_PATH = "icons/markers"
  
  #--- helpers
  
  # creates a json structure of objects and collects the
  # markers, blurp information
  def json_for_map(objects)
    result = []
    objects.each_with_index do |object, index|
      if object && object.lat && object.lng
        result << {
          :id => dom_id(object),
          :attributes => {:lat => object.lat, :lng => object.lng, :name => marker_title_name(object)},
          :icon => {
            :url => map_icon_url(object),
            :size => icon_size(object),
            :anchor => icon_anchor(object)
          },
          :shadow => {
            :url => icon_shadow_url(object),
            :size => icon_shadow_size(object)
          },
          :info_window => {
            :anchor => info_window_anchor(object),
            :html => render(:partial => partial_for(object), :object => object, :link => true)
          }
        }
      end
    end if objects
    result.to_json
  end

  def partial_for(object)
    if object.is_a?(Person)
      "people/sidebar_item_content"
    elsif object.is_a?(Kase)
      "kases/sidebar_item_content"
    elsif object.is_a?(Organization)
      "organizations/sidebar_item_content"
    end
  end

  # returns google icon url for type of instance
  # http://labs.google.com/ridefinder/images/mm_20_yellow.png
  def map_icon_url(object, print=false)
    if object.is_a?(Person) && current_user_me?(object)
      image_path("#{BASE_ICON_PATH}/small_red.png")
    elsif object.is_a?(Person) && object.partner?
      image_path("#{BASE_ICON_PATH}/small_green.png")
    elsif object.is_a?(Kase)
      image_path("#{BASE_ICON_PATH}/small_blue.png")
    elsif object.is_a?(Organization)
      image_path("#{BASE_ICON_PATH}/small_yellow.png")
    else
      image_path("#{BASE_ICON_PATH}/small_white.png")
    end
  end
  
  def icon_size(object)
    [12, 20]
  end

  def icon_shadow_size(object)
    [22, 20]
  end
  
  def icon_anchor(object)
    [6, 20]
  end
  
  def info_window_anchor(object)
    [5, 1]
  end
  
  def icon_shadow_url(object)
    image_path("#{BASE_ICON_PATH}/small_shadow.png")
  end

  def marker_title_name(object)
    case object.class.base_class.name
    when /Kase/ then h(object.title)
    else
      h(object.name)
    end
  end

  # returns the javascript function that trigger to open the marker window
  def trigger_marker_function(object)
    "triggerMarkerByObjectId('#{dom_id(object)}')" if object
  end
  
end
