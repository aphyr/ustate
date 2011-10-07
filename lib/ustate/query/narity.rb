module UState::Query::Narity
  def initialize(*as)
    @as = as.to_set
  end
 
  def ==(o)
    self.class == o.class and
    a == o.a
  end

  def as
    @as
  end

  def as=(as)
    @as = as.to_set
  end
  
  def children
    @as
  end

  def children=(c)
    @as = c.to_set
  end

  def inspect
    inspect_helper *@as
  end

  def mass
    @as.inject(1) do |sum, a|
      sum + (a.mass rescue 1)
    end
  end
  
  def to_s
    "(" + @as.map do |a|
      a.to_s
    end.join(" #{self.class.to_s.split("::").last.downcase} ") + ")"
  end
end
