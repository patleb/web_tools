module ActiveSupport::Concern::WithAdmin
  # TODO test/adjust after bringing LocalRecord
  def rails_admin(name = :self, &block)
    base = eval('self', block.binding)
    if base.respond_to? :extended_record_base_class
      parent_name = base.extended_record_base_class.name
    end
    base.rails_admin_blocks[:before].each do |base_name, base_blocks|
      base_blocks.each{ |base_block| base.rails_admin(base_name, &base_block) }
    end
    base.rails_admin_blocks[:after].each do |base_name, base_blocks|
      base_blocks.each{ |base_block| base.rails_admin(base_name, &base_block) }
    end
    base.rails_admin(name){ navigation_parent parent_name } if parent_name
    base.rails_admin(name, &block)
  end
end

ActiveSupport::Concern.include ActiveSupport::Concern::WithAdmin
