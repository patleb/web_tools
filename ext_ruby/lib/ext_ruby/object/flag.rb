def flag_on?(args, name)
  return unless args.respond_to? :key?
  value = args[name]
  (value.to_s == name.to_s) || value.to_b
end
