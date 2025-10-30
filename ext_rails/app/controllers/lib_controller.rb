class LibController < ActionController::Base
  before_render :set_meta_values

  private

  def render?
    return true if Rails.env.local?
    stale? weak_etag: etag_context
  end

  def etag_entries
    []
  end

  def etag_context
    entries = etag_entries
    context = [
      Current.locale,
      Current.timezone,
      Current.theme,
    ]
    return context if entries.empty?
    models, values = entries.partition(&:is_a?.with(Class))
    context.concat(values)
    return context if models.empty?
    timestamps  = models.map do |model|
      "SELECT MAX(#{model.timestamp_attributes_for_update_in_model.first}) FROM #{model.table_name}"
    end
    context << ActiveRecord::Base.connection.select_value(<<-SQL.strip_sql)
      SELECT MAX(updated_at) FROM (#{timestamps.join(' UNION ')}) t(updated_at)
    SQL
  end

  def set_meta_values
    title = Rails.application.title
    (@meta ||= {}).merge!(
      root: root_path,
      app: title,
      title: title,
      description: title
    )
  end
end
