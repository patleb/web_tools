module MixUser
  has_config do
    attr_writer :parent_model
    attr_writer :json_attributes
    attr_writer :available_roles
    attr_writer :devise_modules
    attr_accessor :scramble_on_discard

    def parent_model
      @parent_model ||= '::LibMainRecord'
    end

    def json_attributes # must be modified before initialization with ActiveSupport.on_load(:active_record)
      @json_attributes ||= {
        first_name: :string,
        last_name: :string,
        login: :string
      }
    end

    # Roles
    #   null: has access to what is available without connection
    #   user: has access to the application
    #   admin: has access to the admin interface
    #   deployer: has access to all the resources
    def available_roles
      @available_roles ||= { null: -100, user: 0, admin: 100, deployer: 200 }
    end

    # Include default devise modules. Others available are:
    # :lockable, :timeoutable and :omniauthable
    # :encryptable
    def devise_modules
      @devise_modules ||= [
        :confirmable, :database_authenticatable, :registerable,
        :recoverable, :rememberable, :trackable, :validatable
      ]
    end
  end
end
