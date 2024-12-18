module MixFile
  has_config do
    attr_writer   :available_records
    attr_writer   :available_associations
    attr_writer   :image_limit
    attr_accessor :draw_active_storage_routes

    def available_records
      @available_records ||= { 'ActiveStorage::Blob' => 0 }
    end

    def available_associations
      @available_associations ||= {
        image:          0,
        preview_image: 10,
        embeds:        20,
        raw_email:     30,
      }.with_indifferent_access
    end

    ### References
    # https://cft.vanderbilt.edu/wp-content/uploads/sites/59/Image_resolutions.pdf
    # actiontext/app/views/active_storage/blobs/_blob.html.erb
    def image_limit
      @image_limit ||= [1024, 768]
    end
  end
end
