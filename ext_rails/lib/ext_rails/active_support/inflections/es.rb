### References
# https://github.com/davidcelis/inflections/blob/master/lib/inflections/es.rb
ActiveSupport::Inflector.inflections(:es) do |inflect|
  inflect.clear

  inflect.plural(/$/, 's')
  inflect.plural(/([^aeéiou])$/i, '\1es')
  inflect.plural(/([aeiou]s)$/i, '\1')
  inflect.plural(/z$/i, 'ces')
  inflect.plural(/á([sn])$/i, 'a\1es')
  inflect.plural(/é([sn])$/i, 'e\1es')
  inflect.plural(/í([sn])$/i, 'i\1es')
  inflect.plural(/ó([sn])$/i, 'o\1es')
  inflect.plural(/ú([sn])$/i, 'u\1es')

  inflect.singular(/s$/, '')
  inflect.singular(/es$/, '')
  inflect.singular(/([sfj]e)s$/, '\1')
  inflect.singular(/ces$/, 'z')

  inflect.irregular('el', 'los')
end
