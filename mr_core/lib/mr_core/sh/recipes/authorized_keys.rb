module Sh::AuthorizedKeys
  def build_authorized_keys(deployer_name)
    keys = Setting[:authorized_keys]
    raise ':authorized_keys must be present' unless keys.any?

    if (admin_key = Setting[:admin_public_key]).present? # TODO not working
      keys = [admin_key].concat(keys)
    end

    "echo -e '#{keys.join("\\n")}' > /home/#{deployer_name}/.ssh/authorized_keys"
  end
end
