class LibMainRecord < LibRecord
  self.abstract_class = true
  establish_main_connection
end
