module ActiveRecord::Base::WithList
  extend ActiveSupport::Concern

  class_methods do
    def has_list(column: :position, push_on_create: true)
      self.skip_locking_attributes += [column.to_s] # NOTE allows admin user to edit records regardless of position changes

      class_attribute :list_column, instance_writer: false, instance_predicate: false, default: column.to_sym
      class_attribute :list_push_on_create, instance_writer: false, instance_predicate: false, default: push_on_create

      attribute :list_prev_id, :integer
      attribute :list_next_id, :integer

      include ActiveRecord::Base::WithList::Position

      validate :list_change_only, if: :list_changed?
    end

    def belongs_to(name, *, **options)
      return super if options[:class_name] || !(parent = options[:list_parent])
      case parent
      when Class  then options[:class_name] = parent.name
      when String then options[:class_name] = parent
      end
      options[:optional] = true unless options.has_key?(:optional) || options.has_key?(:required)
      options[:list_parent] = true
      super
    end

    def listables
      descendants.select{ |klass| klass.base_class? && klass.listable? }
    end

    def listable?
      return @_listable if defined? @_listable
      @_listable = self < ActiveRecord::Base::WithList::Position
    end

    def list_parent_column
      return @_list_parent_column if defined? @_list_parent_column
      @_list_parent_column = reflect_on_all_associations(:belongs_to).find(&:list_parent?).foreign_key
    end
  end
end

module ActiveRecord::Base::WithList::Position
  extend ActiveSupport::Concern

  class_methods do
    def list_reorganize(force: false)
      without_default_scope do
        decimals = maximum("scale(#{list_column})") || 0
        return unless force || decimals >= 32 # postgres numeric max is 16383, but storage size and ruby conversion speed is a concern, 38 decimals is about 128 bits
        with_table_lock do
          connection.exec_query(<<-SQL.strip_sql(table_name: quoted_table_name, position: list_column, pk: primary_key))
            UPDATE {{ table_name }} t_updated SET {{ position }} = t_ordered.i
              FROM (
                SELECT {{ pk }} AS id, (-row_number() OVER (ORDER BY {{ position }})) + 1.0 AS i
                FROM {{ table_name }}
                ORDER BY id
              ) t_ordered
              WHERE t_updated.id = t_ordered.id
          SQL
          connection.exec_query(<<-SQL.strip_sql(table_name: quoted_table_name, position: list_column))
            UPDATE {{ table_name }} SET {{ position }} = -{{ position }}
          SQL
        end
      end
    end
  end

  def create_or_update(...)
    return super unless list_column
    if new_record?
      if list_prev_id
        list_with_prev_record do |prev_record|
          list_insert_after(prev_record) { super }
        end
      elsif list_next_id
        list_with_next_record do |next_record|
          list_insert_before(next_record) { super }
        end
      else
        list_push_on_create ? list_push { super } : list_unshift { super }
      end
    else
      if list_prev_id
        list_with_prev_record do |prev_record|
          list_move_after(prev_record) { super }
        end
      elsif list_next_id
        list_with_next_record do |next_record|
          list_move_before(next_record) { super }
        end
      else
        super
      end
    end
  end

  def list_changed?
    list_prev_id_changed? || list_next_id_changed?
  end

  private

  def list_change_only
    errors.add(:base, :list_change_only) unless changes.except(:list_prev_id, :list_next_id).empty?
  end

  def list_with_prev_record
    clear_attribute_changes [:list_next_id]
    prev_record = self.class.without_default_scope { self.class.base_class.find(list_prev_id) }
    old_id = list_prev_id
    self.list_prev_id = nil
    result = yield(prev_record)
  ensure
    self.list_prev_id = old_id unless result
  end

  def list_with_next_record
    clear_attribute_changes [:list_prev_id]
    next_record = self.class.without_default_scope { self.class.base_class.find(list_next_id) }
    old_id = list_next_id
    self.list_next_id = nil
    result = yield(next_record)
  ensure
    self.list_next_id = old_id unless result
  end

  def list_move_between(prev_record, next_record)
    id = send(self.class.primary_key)
    return yield if prev_record.send(self.class.primary_key) == id || next_record.send(self.class.primary_key) == id
    self.class.transaction do
      [prev_record, self, next_record].sort_by{ |record| record.send(self.class.primary_key) }.each(&:lock!)
      list_between(prev_record, next_record) { yield }
    end
  end

  def list_move_after(prev_record)
    return yield if prev_record.send(self.class.primary_key) == send(self.class.primary_key)
    next_record = list_next_record(prev_record)
    if next_record
      return yield if next_record.send(self.class.primary_key) == send(self.class.primary_key)
      list_move_between(prev_record, next_record) { yield }
    else
      self.class.transaction do
        [prev_record, self].sort_by{ |record| record.send(self.class.primary_key) }.each(&:lock!)
        list_after(prev_record) { yield }
      end
    end
  end

  def list_move_before(next_record)
    return yield if next_record.send(self.class.primary_key) == send(self.class.primary_key)
    prev_record = list_prev_record(next_record)
    if prev_record
      return yield if prev_record.send(self.class.primary_key) == send(self.class.primary_key)
      list_move_between(prev_record, next_record) { yield }
    else
      self.class.transaction do
        [self, next_record].sort_by{ |record| record.send(self.class.primary_key) }.each(&:lock!)
        list_before(next_record) { yield }
      end
    end
  end

  def list_insert_between(prev_record, next_record)
    self.class.transaction do
      [prev_record, next_record].sort_by{ |record| record.send(self.class.primary_key) }.each(&:lock!)
      list_between(prev_record, next_record) { yield }
    end
  end

  def list_insert_after(prev_record)
    next_record = list_next_record(prev_record)
    if next_record
      list_insert_between(prev_record, next_record) { yield }
    else
      prev_record.with_lock do
        list_after(prev_record) { yield }
      end
    end
  end

  def list_insert_before(next_record)
    prev_record = list_prev_record(next_record)
    if prev_record
      list_insert_between(prev_record, next_record) { yield }
    else
      next_record.with_lock do
        list_before(next_record) { yield }
      end
    end
  end

  def list_push
    prev_record = list_last_record
    if prev_record
      prev_record.with_lock do
        list_after(prev_record) { yield }
      end
    else
      self.class.with_table_lock do
        list_begin { yield }
      end
    end
  end

  def list_unshift
    next_record = list_first_record
    if next_record
      next_record.with_lock do
        list_before(next_record) { yield }
      end
    else
      self.class.with_table_lock do
        list_begin { yield }
      end
    end
  end

  def list_next_record(prev_record)
    self.class.without_default_scope do
      self.class.base_class.where(self.class.base_class.column(list_column) > prev_record.send(list_column))
        .order(list_column)
        .first
    end
  end

  def list_prev_record(next_record)
    self.class.without_default_scope do
      self.class.base_class.where(self.class.base_class.column(list_column) < next_record.send(list_column))
        .order(list_column)
        .last
    end
  end

  def list_last_record
    self.class.without_default_scope { self.class.base_class.order(list_column).last }
  end

  def list_first_record
    self.class.without_default_scope { self.class.base_class.order(list_column).first }
  end

  def list_between(prev_record, next_record)
    limits = [prev_record.send(list_column), next_record.send(list_column)].sort
    self[list_column] = (limits[1] - limits[0]) / 2.0 + limits[0]
    yield
  end

  def list_after(prev_record)
    self[list_column] = prev_record.send(list_column).floor + 1.0
    yield
  end

  def list_before(next_record)
    self[list_column] = next_record.send(list_column).ceil - 1.0
    yield
  end

  def list_begin
    self[list_column] = 0.0
    yield
  end
end
