module Sh::AuthorizedKeys
  def build_authorized_keys(deployer_name)
    keys = Secret[:authorized_keys]
    raise ':authorized_keys must be present' unless keys.present?

    "echo -e '#{keys.join("\\n")}' > /home/#{deployer_name}/.ssh/authorized_keys"
  end
end
