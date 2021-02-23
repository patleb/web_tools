module Current::WithJob
  extend ActiveSupport::Concern

  included do
    attribute :job
  end
end
