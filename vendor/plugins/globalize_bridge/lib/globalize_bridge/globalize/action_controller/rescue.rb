module ActionController
  class Base

    protected
      # Attempts to render a static error page based on the <tt>status_code</tt> thrown,
      # or just return headers if no such file exists. For example, if a 500 error is 
      # being handled Rails will first attempt to render the file at the current locale
      # such as <tt>public/en-US/500.html</tt>. Then the file with no locale
      # <tt>public/500.html</tt>. If the files doesn't exist, the body of the response
      # will be left empty.
      #
      def render_optional_error_file(status_code)
        status = interpret_status(status_code)
        # locale_path = "#{Rails.public_path}/#{I18n.locale}/#{status[0,3]}.html" if I18n.locale
        path = locale_path = "#{Rails.public_path}/#{status[0,3]}.html"
        formatted_fallbacks = I18n.respond_to?(:fallbacks)
        
        # try I18n fallbacks 
        if I18n.locale && formatted_fallbacks
          I18n.fallbacks[I18n.locale].reject {|l| l == :root}.each do |fallback_locale|
            if File.exist?(locale_path = "#{Rails.public_path}/#{fallback_locale}/#{status[0,3]}.html")
              render :file => locale_path, :status => status, :content_type => Mime::HTML
              return
            elsif File.exist?(locale_path = "#{Rails.public_path}/#{status[0,3]}.#{fallback_locale}.html")
              render :file => locale_path, :status => status, :content_type => Mime::HTML
              return
            end
          end
        end
        
        # none of the fallback templates worked, try more
        unless performed?
          if I18n.locale && File.exist?(locale_path = "#{Rails.public_path}/#{I18n.locale}/#{status[0,3]}.html")
            render :file => locale_path, :status => status, :content_type => Mime::HTML
            return
          elsif I18n.locale && File.exist?(locale_path = "#{Rails.public_path}/#{status[0,3]}.#{I18n.locale}.html")
            render :file => locale_path, :status => status, :content_type => Mime::HTML
            return
          elsif File.exist?(path)
            render :file => path, :status => status, :content_type => Mime::HTML
            return
          else
            head status
          end
        end
      end

  end
end
