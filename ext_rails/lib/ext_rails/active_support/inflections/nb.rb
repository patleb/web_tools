### References
# https://github.com/davidcelis/inflections/blob/master/lib/inflections/nb.rb
ActiveSupport::Inflector.inflections(:nb) do |inflect|
  inflect.clear

  inflect.plural(/$/, 'er')
  inflect.plural(/r$/i, 're')
  inflect.plural(/e$/i, 'er')

  inflect.singular(/er$/i, '')
  inflect.singular(/re$/i, 'r')

  inflect.irregular('konto', 'konti')
end
