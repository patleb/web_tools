module ActionView
  module Helpers
    module AssetUrlHelper::WithMemoize
      def path_to_asset(source, options = {})
        ((@@path_to_asset ||= {})[source] ||= {})[options] ||= super
      end
    end
  end
end

ActionView::Base.include ActionView::Helpers::AssetUrlHelper::WithMemoize
