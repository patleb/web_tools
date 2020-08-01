module MixUser
  has_config do
    attr_writer :parent_model
    attr_writer :json_attributes
    attr_writer :available_roles
    attr_writer :devise_modules
    attr_accessor :scramble_on_discard

    def parent_model
      @parent_model ||= '::LibRecord'
    end

    def json_attributes
      @json_attributes ||= {} # must be modified before initialization with ActiveSupport.on_load(:active_record)
    end

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
