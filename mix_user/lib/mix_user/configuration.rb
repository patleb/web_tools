module MixUser
  has_config do
    attr_writer :root
    attr_writer :json_attributes
    attr_writer :available_roles
    attr_writer :registerable
    attr_writer :restorable
    attr_writer :available_routes
    attr_writer :verification_expires_in
    attr_writer :reset_expires_in
    attr_writer :restore_expires_in
    attr_writer :min_password_length

    def root_path
      @root_path ||= "/#{root.to_s.delete_prefix('/').delete_suffix('/')}"
    end

    def root
      @root ||= '/'
    end

    # NOTE must be modified before initialization with ActiveSupport.on_load(:active_record)
    def json_attributes
      @json_attributes ||= {
        first_name: :string,
        last_name: :string,
        # login: :string
      }
    end

    # Roles
    #   null: has access to what is available without connection
    #   basic: has access to the application and parts of the admin interface
    #   admin: has access to the admin interface except for the system resources
    #   deployer: has access to all the resources
    def available_roles
      @available_roles ||= { null: -100, basic: 0, admin: 100, deployer: 200 }
    end

    def registerable?
      return @registerable if defined? @registerable
      @registerable = !!(verbs = available_routes[:users]) && verbs.include?(:new)
    end

    def restorable?
      return @restorable if defined? @restorable
      @restorable = true
    end

    # NOTE other actions are available in admin
    def available_routes
      @available_routes ||= {
        users: [:new, :create, :edit, :update],
        user_sessions: [:new, :create, :destroy]
      }
    end

    def verification_expires_in
      @verification_expires_in ||= 1.day
    end

    def reset_expires_in
      @reset_expires_in ||= 1.hour
    end

    def restore_expires_in
      @restore_expires_in ||= 1.hour
    end

    def min_password_length
      @min_password_length ||= 12
    end
  end
end
