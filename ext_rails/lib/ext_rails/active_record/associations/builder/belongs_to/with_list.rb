module ActiveRecord::Associations::Builder::BelongsTo::WithList
  extend ActiveSupport::Concern

  class_methods do
    private

    def valid_options(options)
      super + [:list_parent]
    end
  end
end

ActiveRecord::Associations::Builder::BelongsTo.include ActiveRecord::Associations::Builder::BelongsTo::WithList
