# Creates a captcha code and matching image
require 'RMagick'

module SessionCaptcha
  # Most of the image generation code for this class was taken from the simple_captcha plugin.
  class CaptchaImage
    CHARS = ('a'..'z').to_a - ['a','e','i','o','u']
    IMAGE_STYLES = [
                    "embosed_silver",
                    "simply_red",
                    "simply_green",
                    "simply_blue",
                    "distorted_black",
                    "all_black",
                    "charcoal_grey",
                    "almost_invisible"
                   ]
    
    DISTORTIONS = {
      :low => [0, 100],
      :medium => [3, 50],
      :high => [5, 30]
    }
  
    attr_reader :code, :code_image    
    
    # Ceates a new captcha image and code. Please see simple_captcha docs for information
    # on what options are supported.
    def initialize options = {}
      create_image options
    end    
    
    private
    
    def add_text(options) #:nodoc
      options[:color] = "darkblue" unless options.has_key?(:color)
      text = Magick::Draw.new
      text.annotate(options[:image], 0, 0, 0, 5, options[:string]) do
        self.font_family = 'arial'
        self.pointsize = 22
        self.fill = options[:color]
        self.gravity = Magick::NorthGravity 
      end
      return options[:image]
    end
    
    def add_text_and_effects(options={}) #:nodoc
      image = Magick::Image.new(110, 35){self.background_color = 'white'}
      options[:image] = image
      distortion = DISTORTIONS[options[:distortion].to_sym] || DISTORTIONS[:medium]
      amp, freq = distortion[0], distortion[1]
      case options[:image_style]
      when "embosed_silver"
        image = add_text(options)
        image = image.wave(amp, freq).shade(true, 20, 60)
      when "simply_red"
        options[:color] = "darkred"
        image = add_text(options)
        image = image.wave(amp, freq)
      when "simply_green"
        options[:color] = "darkgreen"
        image = add_text(options)
        image = image.wave(amp, freq)
      when "simply_blue"
        options[:color] = "#009ee0"
        image = add_text(options)
        image = image.wave(amp, freq)
      when "distorted_black"
        image = add_text(options)
        image = image.wave(amp, freq).edge(10)
      when "all_black"
        image = add_text(options)
        image = image.wave(amp, freq).edge(2)
      when "charcoal_grey"
        image = add_text(options)
        image = image.wave(amp, freq).charcoal
      when "almost_invisible"
        options[:color] = "red"
        image = add_text(options)
        image = image.wave(amp, freq).solarize
      else
        image = add_text(options)
        image = image.wave(amp, freq)
      end
      return image
    end
    
    def create_image(options) #:nodoc
      image_style = options[:image_style] || "simply_blue"
      distortion = options[:distortion] || "medium"
      image_style = IMAGE_STYLES[rand(IMAGE_STYLES.length)] if image_style=="random"
      @code = create_code
      options = {
        :image_style => image_style,
        :distortion => distortion,
        :string => @code
      }
      image = add_text_and_effects(options)
      image.implode(0.2)           
      
      @code_image = image.to_blob{ self.format = "JPG" }
    end

    
    # Creates a captcha code with the given length
    def create_code len = 6
      code_array = []
      1.upto(len) {code_array << CHARS[rand(CHARS.length)]}
      code_array.to_s
    end
  
  end
end