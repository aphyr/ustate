module UState::Query::Binarity
  def initialize(a, b)
    @a = a
    @b = b
  end

  def ==(o)
    self.class == o.class and
    a == o.a and
    b == o.b
  end

  def a
    @a
  end
  
  def b
    @b
  end

  def children
    [@a, @b]
  end

  def children=(c)
    raise ArgumentError unless c.size == 2
    @a, @b = c
  end

  def inspect
    inspect_helper @a, @b
  end

  def mass
    1 + (@a.mass rescue 1) + (@b.mass rescue 1)
  end

  def to_s
    "(#{@a} #{self.class.to_s.split('::').last.downcase} #{@b})"
  end
end
