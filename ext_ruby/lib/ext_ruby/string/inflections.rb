class NilClass
  def upcase_first
    ''
  end
end

class String
  def dehumanize
    parameterize(separator: '_')
  end

  def slugify
    parameterize.dasherize.downcase
  end

  def titlefy
    parameterize.humanize.squish.gsub(/([[:word:]]+)/u){ |word| word.downcase.capitalize }
  end

  def full_underscore
    underscore.tr('/', '_').delete_prefix('_').delete_suffix('_')
  end
end
