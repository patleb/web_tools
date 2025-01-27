module Sh::Rbenv
  def rbenv_ruby
    %{eval "$(/home/#{Setting[:deployer_name]}/.rbenv/bin/rbenv init - --no-rehash bash)";}
  end
end
