class NilClass
  def to_sym
    self
  end
  
  def deep_stringify_keys!
    self
  end
end