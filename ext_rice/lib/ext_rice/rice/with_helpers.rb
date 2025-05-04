module Rice
  module WithHelpers
    def no_copy(class_name)
      <<~CPP
        #{class_name}(const #{class_name} &) = delete;
        #{class_name}(#{class_name} &&) = delete;
        #{class_name} & operator=(const #{class_name} &) = delete;
        #{class_name} & operator=(#{class_name} &&) = delete;
      CPP
    end
  end
end
