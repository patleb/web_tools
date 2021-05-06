class Check < VirtualRecord::Base
  attribute :type
  attribute :details

  def self.list
    Checks::Base.descendants.each_with_object([]) do |klass, memo|
      next if klass.name.end_with? '::Base'
      issues, warnings = klass.issues, klass.warnings
      scope = klass.name.deconstantize.underscore.tr('/', '.')
      { issue: issues, warning: warnings }.each do |type, collection|
        collection.each do |name, triggered|
          next unless triggered
          memo << { id: "#{scope}.#{name}", type: type.to_s, details: i18n_details(name, scope: scope) }
        end
      end
    end
  end

  def self.i18n_details(name, scope:)
    I18n.t("#{name}_html", scope: scope, default: I18n.t(name, scope: scope))
  end
end
