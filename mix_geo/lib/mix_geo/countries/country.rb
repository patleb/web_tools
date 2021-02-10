module ISO3166
  Country.class_eval do
    def self.country_enum(locale)
      (@_country_enum ||= {}.with_keyword_access)[locale] ||=
        codes.each_with_object({}){ |code, enum|
          name = find_country_by_alpha2(code).translation(locale)
          enum[name] = code
        }.sort_by{ |key, _value| I18n.transliterate(key, ' ', locale: locale) }
    end

    def self.normalized_regions_names(country_code)
      (@_regions_names ||= {}.with_keyword_access)[country_code] ||=
        find_country_by_alpha2(country_code).subdivisions.each_with_object({}) { |(code, region), regions|
          regions[code] = [region.name].concat(region.translations.values + Array.wrap(region.unofficial_names)).map{ |name|
            name.simplify.gsub(/[^a-z]/, '')
          }.uniq << code.downcase
        }
    end
  end
end
