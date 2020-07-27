module ActiveSupport::Concern::WithAdmin
  def rails_admin(&block)
    base = eval('self', block.binding)
    if base.respond_to? :extended_record_base_class
      parent_name = base.extended_record_base_class.name
    end
    base.rails_admin_blocks.each do |base_block|
      base.rails_admin(&base_block)
    end
    base.rails_admin{ parent parent_name } if parent_name
    base.rails_admin(&block)
  end
end

ActiveSupport::Concern.include ActiveSupport::Concern::WithAdmin
