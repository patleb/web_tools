module MixPage
  module Routes
    FRAGMENT = 'page'

    def self.draw(mapper)
      mapper.get "/:slug/#{FRAGMENT}(/:uuid)" => 'pages#show', as: :page
      mapper.post "/#{FRAGMENT}/:uuid/field" => 'pages#field_create', as: :new_page_field
      mapper.post "/#{FRAGMENT}/:uuid/field/:id" => 'pages#field_update', as: :edit_page_field
    end

    def self.root_path(**params)
      append_query '/', params
    end

    def self.page_path(slug:, uuid: nil, **params)
      build_path slug, FRAGMENT, uuid, **params
    end

    def self.new_page_field_path(uuid:, **params)
      build_path FRAGMENT, uuid, 'field', **params
    end

    def self.edit_page_field_path(uuid:, id:, **params)
      build_path FRAGMENT, uuid, 'field', id, **params
    end

    include ExtRails::WithRoutes
  end
end
