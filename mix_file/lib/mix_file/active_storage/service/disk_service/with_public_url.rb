module ActiveStorage::Service::DiskService::WithPublicUrl
  extend ActiveSupport::Concern

  prepended do
    attr_reader :public_root
  end

  def initialize(...)
    super
    public_dir = Rails.root.join("public/").to_s
    if root.start_with? public_dir
      raise "disk service must be set to 'public' if #{public_dir} is used" unless @public
      @public_root = root.delete_prefix(public_dir)
    end
  end

  private

  def public_url(key, **options)
    if public_root
      MixFile::Routes.public_url root: public_root, key: key
    else
      super
    end
  end
end

ActiveStorage::Service::DiskService.prepend ActiveStorage::Service::DiskService::WithPublicUrl
