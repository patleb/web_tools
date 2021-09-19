module ActiveStorage::Blob::WithOptimize
  extend ActiveSupport::Concern

  class OptimizeError < ::StandardError; end

  included do
    store_accessor :metadata, :optimized

    delegate :image_optim, to: :class
  end

  class_methods do
    def image_optim
      @image_optim ||= ImageOptim.new(image_optim_options)
    end

    def image_optim_options
      @image_optim_options ||= {
        config_paths: [
          MixFile::Engine.root.join('config/image_optim.yml'),
          Rails.root.join('config/image_optim.yml'),
          Rails.root.join("config/image_optim/#{Rails.env}.yml"),
        ],
      }
    end
  end

  def optimize
    data = image_optim.optimize_image_data(download)
    raise OptimizeError, "blob id [#{id}]" if data.nil?

    io = StringIO.new(data)
    self.byte_size, self.checksum = io.size, Digest::MD5.base64digest(data)
    upload_without_unfurling(io)
    update! metadata: metadata.merge(optimized: true)
  end

  def optimize_later
    ActiveStorage::OptimizeJob.perform_later(self)
  end

  def optimized?
    optimized
  end

  def optimizable?
    image? && !optimized?
  end
end
