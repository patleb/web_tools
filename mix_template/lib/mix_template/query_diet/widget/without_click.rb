module QueryDiet
  module Widget
    module WithoutClick
      extend ActiveSupport::Concern

      class_methods do
        def html(options)
          super(options).sub(/onclick="[^"]+"/, '')
        end
      end
    end
  end
end

QueryDiet::Widget.prepend QueryDiet::Widget::WithoutClick
