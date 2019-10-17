module Sh::AuthorizedKeys
  def build_authorized_keys(deployer_name)
    keys = [Setting[:admin_public_key]].concat(Array.wrap(Setting[:authorized_keys])).reject(&:blank?)
    raise ':admin_public_key or :authorized_keys must be present' unless keys.any?

    "echo -e '#{keys.join("\\n")}' > /home/#{deployer_name}/.ssh/authorized_keys"
  end
end
