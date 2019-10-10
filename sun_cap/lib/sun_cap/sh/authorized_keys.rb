module Sh::AuthorizedKeys
  def build_authorized_keys(deployer_name)
    keys = [admin_public_key].concat(Array.wrap(Setting[:authorized_keys])).reject(&:blank?)
    raise ':admin_public_key or :authorized_keys must be present' unless keys.any?

    "echo -e '#{keys.join("\\n")}' > /home/#{deployer_name}/.ssh/authorized_keys"
  end

  def admin_public_key
    @_admin_public_key ||= Setting[:admin_public_key] || `ssh-keygen -f #{vagrant_pkey} -y`.strip
  end

  def admin_private_key
    @_admin_private_key ||= Setting[:admin_private_key] || `cat #{vagrant_pkey}`.strip
  end
end
