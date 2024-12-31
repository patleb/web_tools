module Sh::AuthorizedKeys
  def build_authorized_keys
    keys = [Setting[:owner_public_key]].concat(Setting[:authorized_keys]).reject(&:blank?)
    raise ':owner_public_key or :authorized_keys must be present' unless keys.any?

    "echo -e '#{keys.join("\\n")}' > /home/deployer/.ssh/authorized_keys"
  end
end
