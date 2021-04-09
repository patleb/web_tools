class LibMainRecord < ActiveRecord::Main
  include AsLibRecord

  self.abstract_class = true
end
