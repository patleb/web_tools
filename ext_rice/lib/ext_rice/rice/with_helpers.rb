module Rice
  module WithHelpers
    def no_copy(class_name, indent: 2)
      indent = ' ' * indent
      <<~CPP.rstrip
        #{class_name}(const #{class_name} &) = delete;
        #{indent}#{class_name}(#{class_name} &&) = delete;
        #{indent}#{class_name} & operator=(const #{class_name} &) = delete;
        #{indent}#{class_name} & operator=(#{class_name} &&) = delete;
      CPP
    end
  end
end
