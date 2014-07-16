# FileAsset is a sublcass of Asset and holds file assets in secure S3 storage
#
# File extensions to be used:
#   mov wmv avi
#   pdf ps
#   ppt
#   xls csv
#   doc rtf
#   txt gif png jpg jpeg
#   mp3 wma wav
#
class FileAsset < Asset
  #--- constants
  MAXIMUM_FILE_SIZE_IN_KB       = 256
  
  # default mime-types to file extension
  MIME_EXTENSIONS = {
    "image/gif" => "gif",
    "image/jpeg" => "jpg",
    "image/pjpeg" => "jpg",
    "image/png" => "png",
    "image/x-png" => "png",
    "image/jpg" => "jpg",
    "application/x-shockwave-flash" => "swf",
    "application/pdf" => "pdf",
    "application/pgp-signature" => "sig",
    "application/futuresplash" => "spl",
    "application/msword" => "doc",
    "application/postscript" => "ps",
    "application/x-bittorrent" => "torrent",
    "application/x-dvi" => "dvi",
    "application/x-gzip" => "gz",
    "application/x-ns-proxy-autoconfig" => "pac",
    "application/x-shockwave-flash" => "swf",
    "application/x-tgz" => "tar.gz",
    "application/x-tar" => "tar",
    "application/zip" => "zip",
    "audio/mpeg" => "mp3",
    "audio/x-mpegurl" => "m3u",
    "audio/x-ms-wma" => "wma",
    "audio/x-ms-wax" => "wax",
    "audio/x-wav" => "wav",
    "image/x-xbitmap" => "xbm",             
    "image/x-xpixmap" => "xpm",             
    "image/x-xwindowdump" => "xwd",             
    "text/css" => "css",             
    "text/html" => "html",                          
    "text/javascript" => "js",
    "text/plain" => "txt",
    "text/xml" => "xml",
    "video/mpeg" => "mpeg",
    "video/quicktime" => "mov",
    "video/x-msvideo" => "avi",
    "video/x-ms-asf" => "asf",
    "video/x-ms-wmv" => "wmv"
  }
  
  #--- mixins
  has_attached_file :file, 
    :storage => %w(development test).include?(RAILS_ENV) ? :filesystem : :s3,
    :s3_credentials => "#{RAILS_ROOT}/config/amazon_s3.yml",
    :s3_permissions => 'private',
    :bucket => "#{SERVICE_DOMAIN}-#{RAILS_ENV}",
    :styles => {:thumb => "35x35#", :profile => "113x113#", :portrait => "320x200>"},
    :url => "#{RAILS_ROOT}/storage/:class/:attachment/:id/:style_:basename.:extension",
    :path => "storage/:class/:attachment/:id/:style_:basename.:extension"

  #--- validations
  validates_attachment_size :file, :in => 1..MAXIMUM_FILE_SIZE_IN_KB.kilobyte
  validates_attachment_content_type :file, :content_type => Utility.image_content_types

  #--- class methods
  class << self
    
    def kind
      :file
    end
    
    # Returns the extension in lowercase, like "doc", "ppt", etc.
    def file_ext(filename)
      File.extname( filename ).gsub(".", "") rescue nil
    end

    def file_name_without_ext(filename)
      parse_file_name(filename)[1] rescue nil
    end

    private
    
    # returns array for filename, like "/public/images", "lebenslauf", "doc"
    def parse_file_name(filename)
      dir = File.dirname(filename.to_s)
      name = File.basename(filename.to_s).gsub(File.extname(filename.to_s), "")
      ext = File.extname(filename.to_s).gsub(".", "")
      return [dir, name, ext]
    end
    
  end
  
  #--- instance methods

  def empty?
    self.file?
  end
  
  # Is this asset an image?
  def image?
    self.content_type.to_s.index(/image/).nil?
  end
  
  # accessor for paperclip column
  def file?
    self.file.file?
  end

  # accessor for paperclip column
  def file_name
    self.file_file_name
  end

  # accessor for paperclip column
  def file_size
    self.file_file_size
  end
  
  # accessor for paperclip column
  def content_type
    self.file_content_type
  end
  
  def file_with_details=(f)
    if self.name.blank? && fn = self.file_name_without_ext
      self.name = fn.humanize.titleize
    end
    self.file_without_details=(f)
  end
  alias_method_chain :file=, :details
  
  # Returns the extension in lowercase, like "doc", "ppt", etc.
  def file_ext
    Asset.file_ext(self.file_name) if self.file?
  end

  # Returns "my_great_file"
  def file_name_without_ext
    self.class.file_name_without_ext(self.file_name)
  end
  
end
