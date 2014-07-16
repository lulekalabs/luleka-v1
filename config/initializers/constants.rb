#=== Global Constants

# Basics (IMPORTANT: DO NOT TRANSLATE)
# reason, these are used within strings that are already translated
SERVICE_NAME                 = "Luleka"
SERVICE_TAGLINE              = "community help desk"
SERVICE_DOMAIN               = "luleka.com"                            # refactor to SERVICE_HOST
SERVICE_URL                  = "http://www.#{SERVICE_DOMAIN}"          # ?
SERVICE_TIER_NAME            = "luleka"                                # e.g. "support" for http://support.luleka.com

SERVICE_PARTNER_NAME         = "Partner"
SERVICE_PARTNERS_NAME        = SERVICE_PARTNER_NAME.pluralize
SERVICE_FRIEND_NAME          = "Contact"
SERVICE_FRIENDS_NAME         = SERVICE_FRIEND_NAME.pluralize
SERVICE_FOLLOWER_NAME        = "Follower"
SERVICE_FOLLOWERS_NAME       = SERVICE_FOLLOWER_NAME.pluralize
SERVICE_PIGGYBANK_NAME       = "Piggy Bank"

# Tier site names, e.g. business site http://biz.luleka.com
LULEKA_TIER_SITE_NAME        = "luleka" 
LEGAL_TIER_SITE_NAME         = "legal" 
BUSINESS_TIER_SITE_NAME      = "money"
HEALTH_TIER_SITE_NAME        = "med" 
TOURISM_TIER_SITE_NAME       = "travel" 
COMPUTER_TIER_SITE_NAME      = "computer" 

MODAL_FLASH_DELAY            = 5  # in seconds

#=== Messages
PUBLISH_SUCCESS = "%{object} was successfully published."
PUBLISH_FAIL    = "%{object} could not be published."
CREATE_SUCCESS  = "%{object} was successfully created, please check your Email messages on how to proceed."


#=== Google Map keys
# see http://www.google.com/apis/maps/signup.html
# and http://www.google.com/apis/maps/documentation/#Geocoding_Examples
GOOGLE_MAPS_KEYS = {
  #--- local, http://*.luleka.local
  #'http://luleka.local/'        => 'ABQIAAAA3jIP-UwrX5YmhumykFl2_RS6GeKAKzMdFpTsuWUcAZG8FjRu3BSoE5e5jiebZhb7DBHTAavdbVBFWA',
  'http://luleka.local/'        => 'ABQIAAAA3jIP-UwrX5YmhumykFl2_RS3PQ5dDn-vYoZ50kniJ1sdbmgFzhSvdQnrUMwWfLhegjC7sk3PXmFmsQ',
  'http://luleka.local:3000'    => 'ABQIAAAA3jIP-UwrX5YmhumykFl2_RSjwkwKm0CfoFioILt_Fk_cuiIKuhSy4cjYy2llCTDEeJsatn1GTPwZ3g',

  #--- staging, http://staging.luleka.net
  'http://staging.luleka.net'   => 'ABQIAAAA3jIP-UwrX5YmhumykFl2_RQEUup_XLOI6wg6LoCVuyM34wH8VBTIL9yfQH0nEGY15ONtNKjAV4q8Bw',
  'https://staging.luleka.net'  => 'ABQIAAAA3jIP-UwrX5YmhumykFl2_RRn_O-gSpUu_q51NWPi2okgv7J3pRSM0s5qhTBsOdmCdA9s_kAw--sesg',

  #--- production
  'http://luleka.com'           => 'ABQIAAAA3jIP-UwrX5YmhumykFl2_RS1mAVhG4UZBYCZx4rGtJzInLFBeRSVPBlFCsCPLy7CYFxhMJlHqAJeOg',
  'https://luleka.com'          => 'ABQIAAAA3jIP-UwrX5YmhumykFl2_RSJebsg8vZIecHoRsihnssrGa5XqxS53FZ93rGEbhxrfY2oorseMnIxsg',
}

#--- front view
PROBONO_THEME_MAPPING = {
  :case => :issue, :kase => :issue, :issue => :issue,
  :response => :response,
  :comment => :comment,
  :sidebar => :sidebar,
  :form => :form,
  :info => :profile, :profile => :profile,
  :broken_content => :broken_content
}

PROBONO_STYLE_THEMES = {
  :issue => {
    :type => 'case', 
    :color => 'blue',
    :theme => 'tabBoxBlue',
    :headline => {
      :stars_theme => 'tabBoxBlueHeadRating'
    },
    :contact_container => {
      :class => "tabBoxBlueContentContact",
      :color => 'Blue', 
      :theme => 'tabBoxBlue',
      :background_color => '#C9E9F8'
    },
    :primary_content => {
      :class => 'tabBoxBluePrimaryContent', # 'tabBoxBlueContentMain'
      :background_color => '#D5EFFB',
      :bottom => { :class => 'tabBoxBlueBottom' }
    },
    :secondary_content => {
      :theme => 'Blue', 
      :class => 'tabBoxBlueContentSub',
      :class_container => 'tabBoxBlueContentSub',  # TODO obsolete test!
      :background_color => '#B6E5F8',
      :bottom => { :class => 'tabBoxBlueBottomSub' }
    },
    :sort_control => {
      :class => "listBoxBlueSortOptions",
      :active => { :class => "listBoxBlueSortOptionsActive" },
      :arrow_img_path => 'css/',
      :up => { :image_active => 'sort_blue_up_over.gif', :image_inactive => 'sort_blue_up.gif' },
      :down => { :image_active => 'sort_blue_down_over.gif', :image_inactive => 'sort_blue_down.gif' }
    },
    :navigation_control => {
      :class => 'listBoxBlueFooterNumberNavi',
      :active => { :class => 'listBoxBlueFooterNumberNaviActive' }
    },
    :slider_control => {
      :class => "tabBoxBlueSliderControl"
    },
    :tabs_box_container => {
      :theme => 'Blue', 
      :class => 'tabBoxBlueTab'
    },
    :tab => { :theme => 'Blue' }
  },
  :response => {
    :type => 'response', 
    :color => 'green',
    :theme => 'greenBox',
    :contact_container => {
      :class => "greenBoxContentContact",
      :color => 'Green',
      :theme => 'greenBox'
    },
    :primary_content => {
      :class => 'greenBoxPrimaryContent', # 'greenBoxMiddleContent'
      :bottom => { :class => 'greenBoxBottom' }
    },
    :secondary_content => {
      :theme => 'Green',
      :class => 'greenBoxContentSub',
      :class_container => 'greenBoxContentSub', # 'greenBoxContentSub' TODO obsolete test!
      :bottom => { :class => 'greenBoxBottomSub' }
    },
    :sort_control => {
      :class => "listBoxBlueSortOptions",
      :active => { :class => "listBoxBlueSortOptionsActive" },
      :arrow_img_path => 'css/',
      :up => { :image_active => 'sort_green_up_over.gif', :image_inactive => 'sort_green_up.gif' },
      :down => { :image_active => 'sort_green_down_over.gif', :image_inactive => 'sort_green_down.gif' }
    },
    :navigation_control => {
      :class => 'listBoxBlueFooterNumberNavi',
      :active => { :class => 'listBoxBlueFooterNumberNaviActive' }
    },
    :slider_control => {
      :class => "greenBoxSliderControl"
    },
    :tabs_box_container => {
      :theme => 'Green',
      :class => 'greenBoxTab'
    },
    :tab => { :theme => 'Green' }
  },
  # comment
  :comment => {
    :type => 'comment', 
    :color => 'blue',
    :theme => 'commentsBox',
    :headline => { :stars_theme => 'tabBoxBlueHeadRating' }, 
    :contact_container => { :color => 'Blue', :theme => 'tabBoxBlue' },
    :primary_content => {
      :class => 'commentsPrimaryContent',
      :background_color => '#F1F9FD',
      :bottom => { :class => 'commentsBoxBottom' }
    },
    :secondary_content => {
      :theme => 'comment',
      :class => 'commentsContentSub',
      :class_container => 'commentsContentSub',   # obsolete 
      :background_color => '#DCF0FB',
      :bottom => { :class => 'commentsBoxBottomSub' }
    },
    :slider_control => {
      :class => "commentsSliderControl"
    },
    :tabs_box_container => {
      :theme => 'comment', 
      :class => 'tabCommentsTab'
    },
    :tab => {
      :theme => 'comment', 
      :class1 => 'tabCommentsLeft', 
      :class2 => 'commentsTab'
    }
  },
  # sidebar
  :sidebar => {
    :type => 'sidebar', 
    :color => 'gray', 
    :theme => 'sideBarBoxGray',
    :bracket_container => 'Small',
    :primary_content => {
      :class => 'sideBarBoxGrayPrimaryContent',
      :background_color => '#f6f6f6',
      :bottom => { :class => 'sideBarBoxGrayBottom' }
    },
    :secondary_content => {
      :theme => 'Gray',
      :class => 'sideBarBoxGrayContentSub',
      :class_container => 'sideBarBoxGrayContentSub',  # TODO obsolete test
      :background_color => '#ededef',
      :bottom => { :class => 'sideBarBoxGrayBottomSub' }
    },
    :slider_control => {
      :class => "sideBarBoxGraySliderControl"
    },
    :tabs_box_container => {
      :theme => 'Gray',
      :class => 'sideBarBoxGrayTab'
    },
    :tab => {
      :theme => 'Gray',
      :class1 => "tabSideBarGrayLeft",
      :class2 => "tabSideBarGrayContent"
    }
  },
  # half size truquoise box
  :broken_content => {
    :type => 'broken_content', 
    :color => 'turquoise', 
    :theme => 'turquoiseBoxHalf',
    :bracket_container => 'Half',
    :primary_content => {
      :class => 'turquoiseBoxHalfPrimaryContent',
      :background_color => '#E7FCFE'
    },
    :secondary_content => {
      :theme => 'turquoiseBoxHalf', 
      :class => 'sideBarBoxGrayContentSub',
      :class_container => 'sideBarBoxGrayContentSub'
    },
    :tabs_box_container => {
      :theme => 'turquoiseBoxHalf', 
      :class => 'sideBarBoxGrayTab'
    },
    :tab => {
      :theme => 'turquoiseBoxHalf', 
      :class1=>"tabSideBarGrayLeft", 
      :class2=>"tabSideBarGrayContent"
    }
  },
  # forms
  :form => {
    :type => 'form',
    :theme => 'form',
    :color => 'turquoise',
    :headline => {
      :theme => 'none'
    },
    :primary_content => {
      :theme => 'none'
    },
    :secondary_content => {
      :theme => 'comment',
      :class_container => 'commentsBoxSubContent'
    },
    :tabs_box_container => {
      :theme => 'form',
      :class => 'tabCommentsTab'
    },
    :tab => {
      :theme => 'form',
      :class1 => 'tabCommentsLeft',
      :class2 => 'commentsTab'
    }
  },
  # profile
  :profile => {
    :type => 'info', 
    :color => 'turquoise',
    :theme => 'turquoiseBox',
    :headline => {:theme => 'turquoiseBox', :stars_theme => 'turquoiseBox'}, 
    :contact_container => {
      :class => "turquoiseBoxContentContact",
      :color => 'Turquoise',
      :theme => 'turquoiseBox'
    },
    :primary_content => {
      :class => 'turquoiseBoxPrimaryContent',
      :background_color => '#EEFCFE',
      :bottom => { :class => 'turquoiseBoxBottom' }
    },
    :secondary_content => {
      :theme => 'turquoise',
      :class => 'turquoiseBoxContentSub',
      :class_container => 'turquoiseBoxContentSub',  # TODO obsolete
      :background_color => '#C3F489',
      :bottom => { :class => 'turquoiseBoxBottomSub' }
    },
    :sort_control => {
      :class => "listBoxTurquoiseSortOptions",
      :active => { :class => "listBoxTurquoiseSortOptionsActive" },
      :arrow_img_path => 'css/',
      :up => { :image_active => 'sort_turquoise_up_over.gif', :image_inactive => 'sort_turquoise_up.gif' },
      :down => { :image_active => 'sort_turquoise_down_over.gif', :image_inactive => 'sort_turquoise_down.gif' }
    },
    :navigation_control => {
      :class => 'listBoxTurquoiseFooterNumberNavi',
      :active => { :class => 'listBoxTurquoiseFooterNumberNaviActive' }
    },
    :slider_control => {
      :class => "turquoiseBoxSliderControl"
    },
    :tabs_box_container => { :theme => 'turquoise', :class => 'turquoiseBoxTab' },
    :tab => { :theme => 'turquoise', :class1 => 'tabTurquoiseLeft', :class2 => 'tabTurquoiseContent'}
  }
}
