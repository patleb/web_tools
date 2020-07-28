class Array
  def to_h
    super
  rescue
    map{ |item| [item, item] }.to_h
  end
end
