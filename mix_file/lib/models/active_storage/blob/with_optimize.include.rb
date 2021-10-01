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
    transform(resize_to_limit: MixFile.config.image_limit) do |file|
      file = image_optim.optimize_image! file
      raise OptimizeError, "blob id [#{id}]" if file.nil?

      self.byte_size, self.checksum = File.size(file), Digest::MD5.file(file).base64digest
      file.open do |io|
        upload_without_unfurling(io)
      end
    end
    ratio = (byte_size_was.to_f / byte_size).floor(2)
    save!
    with_lock do
      update! metadata: metadata.merge(optimized: true, compression: ratio)
    end
  end

  def transform(**transformations)
    open do |file|
      if transformations.compact.present?
        variation = ActiveStorage::Variation.wrap(transformations)
        variation.transform(file) do |output|
          yield output
        end
      else
        yield file
      end
    end
  end

  def optimize_later
    ActiveStorage::OptimizeJob.perform_later(self)
  end

  def optimizable?
    image? && !optimized?
  end

  def optimized?
    optimized
  end
end
