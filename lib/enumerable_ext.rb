module Enumerable

  # returns the cartesian product
  #
  # e.g.
  #
  #   [1, 2].product([3, 4])  ->  [[1,3], [1, 4], [2, 3], [2, 4]]
  #
  def self.product(*args)
    args.inject([[]]){|old,lst|
      lst.inject([]){|new,e|
        new + old.map{|c| c.dup << e}}}
  end
  
  def product(*args, &block)
    Enumerable.product(self, *args, &block)
  end

  # returns an array of elements which is unique within 
  # the scope of the given block.
  # 
  # e.g.
  # 
  #   # color 'R', 'G', 'G', 'G', 'B'
  #   products.uniq_by(&:color_list).each |product|
  #     p product.color_list
  #   end
  #   "R"
  #   "G"
  #   "B"
  def uniq_by
    inject([]) do |groups, element|
      groups << element if groups.select {|i| yield(i) == yield(element) }.empty?
      groups
    end
  end

  # Same as group by, but not creating an ordered hash
  #
  # e.g.
  # 
  # products.group_by.each |group, values| 
  #   puts group, values
  # end
  # 'nels', [1, 2, 3]   
  #
  def unordered_group_by
    inject Hash.new do |grouped, element|
      (grouped[yield(element)] ||= []) << element
      grouped
    end
  end

  # works similar to group_by, although, the 
  # builds an array of array like
  #
  # e.g.
  #
  # products.ordered_group_by(&:style_list).each |group, values| 
  #   puts group, values
  # end
  # -> [[k1, [v1, v2, v3]], [k2, [v4, v5, v5]]]
  #
  def ordered_group_by
    inject(Array.new) do |grouped, element|
      tuples = grouped.select {|p| p.first == yield(element) }
      if tuples.empty?
        grouped.push [yield(element), [element]]
      else
        tuples[0].last.push element
      end
      grouped
    end
  end

end