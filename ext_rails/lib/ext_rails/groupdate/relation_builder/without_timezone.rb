module Groupdate::RelationBuilder::WithoutTimezone
  private

  def group_clause
    super.gsub(/::timestamptz/, '').gsub(%r{ AT TIME ZONE '[^']+'}, '')
  end
end

Groupdate::RelationBuilder.prepend Groupdate::RelationBuilder::WithoutTimezone
