module MixFile
  has_config do
    attr_writer :available_records
    attr_writer :available_associations

    def available_records
      @available_records ||= { 'ActiveStorage::Blob' => 0 }
    end

    def available_associations
      @available_associations ||= {
        image:          0,
        preview_image: 10,
        embeds:        20,
        raw_email:     30,
      }.with_keyword_access
    end
  end
end
