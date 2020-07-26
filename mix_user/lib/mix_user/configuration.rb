module MixUser
  has_config do
    attr_writer :parent_model
    attr_writer :json_attributes
    attr_writer :available_roles
    attr_writer :devise_modules

    def parent_model
      @parent_model ||= '::LibRecord'
    end

    def json_attributes
      @json_attributes ||= {} # must be modified before initialization with ActiveSupport.on_load(:active_record)
    end

    def available_roles
      @available_roles ||= { guest: 0, normal: 10, admin: 100, root: 1000 }
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
