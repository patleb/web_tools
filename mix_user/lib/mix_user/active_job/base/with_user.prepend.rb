module ActiveJob::Base::WithUser
  extend ActiveSupport::Concern

  prepended do
    attr_accessor :user
  end

  class_methods do
    def context
      @context ||= super << :user
    end
  end

  def initialize(*arguments)
    super
    @user = Current.user || User::Null.new
  end

  def serialize
    super.merge!(
      "user" => user.to_global_id.to_s
    )
  end

  def deserialize(job_data)
    super
    self.user = GlobalID::Locator.locate(job_data["user"]) rescue User::Null.new
  end
end
