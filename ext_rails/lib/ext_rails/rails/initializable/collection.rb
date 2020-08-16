module Rails::Initializable::Collection::FasterCompare
  def initialize(*)
    super
    @select_before = {}; each{ |i| (@select_before[i.before] ||= []) << i }
    @select_name = {}; each{ |i| (@select_name[i.name] ||= []) << i }
  end

  def tsort_each_child(initializer)
    all = (@select_before[initializer.name] || []) + (@select_name[initializer.after] || [])
    all.each do |i|
      yield i
    end
  end
end

Rails::Initializable::Collection.prepend Rails::Initializable::Collection::FasterCompare
