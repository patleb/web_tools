# frozen_string_literal: true

module MixUser
  module Routes
    def self.draw(mapper)
      MixUser.config.available_routes.each do |controller, actions|
        mapper.simple_resources path: MixUser.config.root / controller, controller: controller, only: actions
      end
    end

    def self.root_path(**params)
      append_query MixUser.config.root, params
    end

    def self.new_path(**params)
      build_path 'users/new', **params
    end

    def self.edit_path(id:, **params)
      build_path 'users', id, 'edit', **params
    end

    def self.new_session_path(**params)
      build_path 'user_sessions/new', **params
    end

    def self.delete_session_path(**params)
      build_path 'user_sessions/current/delete', **params
    end

    def self.edit_verified_path(**params)
      edit_path(id: 'verified', **params)
    end

    def self.edit_deleted_path(**params)
      edit_path(id: 'deleted', **params)
    end

    def self.edit_password_path(**params)
      edit_path(id: 'password', **params)
    end

    def self.verified_path(**params)
      new_session_path(edit: 'verified', **params)
    end

    def self.deleted_path(**params)
      new_session_path(edit: 'deleted', **params)
    end

    def self.password_path(**params)
      new_session_path(edit: 'password', **params)
    end

    include ExtRails::WithRoutes
  end
end
