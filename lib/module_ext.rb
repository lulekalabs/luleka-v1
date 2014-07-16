class Module # :nodoc:

  def mattr_translate(name, string, namespace=nil)
    class_eval(<<-EOS, __FILE__, __LINE__)

      def self.#{name}
        "#{string}".t
      end

    EOS
  end
    
end