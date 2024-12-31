module MixFile
  module Routes
    def self.root_path(**params)
      append_query '/', params
    end

    def self.public_path(root:, key:, **params)
      if key.start_with? ':'
        build_path root, ':key_0_1', ':key_2_3', key, **params
      else
        build_path root, key[0..1], key[2..3], key, **params
      end
    end

    include ExtRails::WithRoutes
  end
end
