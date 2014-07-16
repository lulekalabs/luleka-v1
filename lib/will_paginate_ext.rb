module WillPaginate
  module Finder
    module ClassMethods

      # override due to find_by_sql bug
      # http://sod.lighthouseapp.com/projects/17958/tickets/120-paginate-association-with-finder_sql-raises-typeerror
      #
      # ...
      # WillPaginate::Collection.create(page, per_page, total_entries) do |pager|
      #   count_options = options.except :page, :per_page, :total_entries, :finder
      #   find_options = count_options.except(:count).update(:offset => pager.offset, :limit => pager.per_page) 
      #   
      #   args << find_options
      #   # @options_from_last_find = nil
      #   pager.replace send(finder, *args, &block)
      #   
      #   # magic counting for user convenience:
      #   pager.total_entries = wp_count(count_options, args, finder) unless pager.total_entries
      # end
      # ...
      def paginate(*args, &block)
        options = args.pop
        page, per_page, total_entries = wp_parse_options(options)
        finder = (options[:finder] || 'find').to_s

        if finder == 'find'
          # an array of IDs may have been given:
          total_entries ||= (Array === args.first and args.first.size)
          # :all is implicit
          args.unshift(:all) if args.empty?
        end

        WillPaginate::Collection.create(page, per_page, total_entries) do |pager|
          count_options = options.except :page, :per_page, :total_entries, :finder
          find_options = count_options.except(:count).update(:offset => pager.offset, :limit => pager.per_page)

          if proxy_reflection.options[:finder_sql].nil?
            args << find_options
            # @options_from_last_find = nil

            pager.replace send(finder, *args, &block)
          else
            sql = @finder_sql
            sql += sanitize_sql [" LIMIT ?", pager.per_page]
            sql += sanitize_sql [" OFFSET ?", pager.offset]

            pager.replace send("find_by_sql", sql, &block)
          end

          # magic counting for user convenience:
          pager.total_entries = wp_count(count_options, args, finder) unless pager.total_entries
        end
      end

    end
  end
end
