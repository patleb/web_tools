module Sh::AuthorizedKeys
  def build_authorized_keys
    if (keys = Setting.authorized_keys).empty?
      raise ':owner_public_key or :authorized_keys must be present'
    end
    "echo -e '#{keys.join("\\n")}' > /home/#{Setting[:deployer_name]}/.ssh/authorized_keys"
  end
end
