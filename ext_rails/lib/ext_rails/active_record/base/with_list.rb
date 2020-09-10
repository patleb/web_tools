# TODO subqueries
# http://joshfrankel.me/blog/constructing-a-sql-select-from-subquery-in-activerecord/
# https://pganalyze.com/blog/active-record-subqueries-rails
# TODO ActiveRecord::RecordNotUnique or reshuffle elements (move and replace by integers)
module ActiveRecord::Base::WithList
  extend ActiveSupport::Concern

  class_methods do
    def has_list
      class_attribute :list_column, instance_writer: false, default: :position
      class_attribute :list_push_on_create, instance_writer: false, default: true

      ### NOTE
      # cannot update position with other attributes --> lock prevents it
      attribute :list_previous_id, :integer
      attribute :list_next_id, :integer

      include ActiveRecord::Base::WithList::Position
    end
  end
end

module ActiveRecord::Base::WithList::Position
  def create_or_update(*)
    if list_column
      if new_record?
        if list_previous_id
          list_with_previous_record do |previous_record|
            list_insert_after(previous_record){ super }
          end
        elsif list_next_id
          list_with_next_record do |next_record|
            list_insert_before(next_record) { super }
          end
        else
          list_push_on_create ? list_push { super } : list_unshift { super }
        end
      else
        if list_previous_id
          list_with_previous_record do |previous_record|
            list_move_after(previous_record) { super }
          end
        elsif list_next_id
          list_with_next_record do |next_record|
            list_move_before(next_record) { super }
          end
        else
          super
        end
      end
    else
      super
    end
  end

  private

  def list_with_previous_record
    clear_attribute_changes [:list_next_id]
    previous_record = self.class.without_default_scope { self.class.base_class.find(list_previous_id) }
    old_id = list_previous_id
    self.list_previous_id = nil
    result = yield(previous_record)
  ensure
    self.list_previous_id = old_id unless result
  end

  def list_with_next_record
    clear_attribute_changes [:list_previous_id]
    next_record = self.class.without_default_scope { self.class.base_class.find(list_next_id) }
    old_id = list_next_id
    self.list_next_id = nil
    result = yield(next_record)
  ensure
    self.list_next_id = old_id unless result
  end

  def list_move_between(previous_record, next_record)
    id = send(self.class.primary_key)
    return yield if previous_record.send(self.class.primary_key) == id || next_record.send(self.class.primary_key) == id
    self.class.transaction do
      [previous_record, self, next_record].sort_by{ |record| record.send(self.class.primary_key) }.each(&:lock!)
      list_between(previous_record, next_record) { yield }
    end
  end

  def list_move_after(previous_record)
    return yield if previous_record.send(self.class.primary_key) == send(self.class.primary_key)
    next_record = list_next_record(previous_record)
    if next_record
      return yield if next_record.send(self.class.primary_key) == send(self.class.primary_key)
      list_move_between(previous_record, next_record) { yield }
    else
      self.class.transaction do
        [previous_record, self].sort_by{ |record| record.send(self.class.primary_key) }.each(&:lock!)
        list_after(previous_record) { yield }
      end
    end
  end

  def list_move_before(next_record)
    return yield if next_record.send(self.class.primary_key) == send(self.class.primary_key)
    previous_record = list_previous_record(next_record)
    if previous_record
      return yield if previous_record.send(self.class.primary_key) == send(self.class.primary_key)
      list_move_between(previous_record, next_record) { yield }
    else
      self.class.transaction do
        [self, next_record].sort_by{ |record| record.send(self.class.primary_key) }.each(&:lock!)
        list_before(next_record) { yield }
      end
    end
  end

  def list_insert_between(previous_record, next_record)
    self.class.transaction do
      [previous_record, next_record].sort_by{ |record| record.send(self.class.primary_key) }.each(&:lock!)
      list_between(previous_record, next_record) { yield }
    end
  end

  def list_insert_after(previous_record)
    next_record = list_next_record(previous_record)
    if next_record
      list_insert_between(previous_record, next_record) { yield }
    else
      previous_record.with_lock do
        list_after(previous_record) { yield }
      end
    end
  end

  def list_insert_before(next_record)
    previous_record = list_previous_record(next_record)
    if previous_record
      list_insert_between(previous_record, next_record) { yield }
    else
      next_record.with_lock do
        list_before(next_record) { yield }
      end
    end
  end

  def list_push
    previous_record = list_last_record
    if previous_record
      previous_record.with_lock do
        list_after(previous_record) { yield }
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

  def list_next_record(previous_record)
    self.class.without_default_scope do
      self.class.where(self.class.base_class.column(list_column) > previous_record.send(list_column)).order(list_column).first
    end
  end

  def list_previous_record(next_record)
    self.class.without_default_scope do
      self.class.where(self.class.base_class.column(list_column) < next_record.send(list_column)).order(list_column).last
    end
  end

  def list_last_record
    self.class.without_default_scope { self.class.base_class.order(list_column).last }
  end

  def list_first_record
    self.class.without_default_scope { self.class.base_class.order(list_column).first }
  end

  def list_between(previous_record, next_record)
    limits = [previous_record.send(list_column), next_record.send(list_column)].sort
    self[list_column] = Rational.intermediate(*limits).to_f
    yield
  end

  def list_after(previous_record)
    self[list_column] = Rational.intermediate(previous_record.send(list_column), nil).to_f
    yield
  end

  def list_before(next_record)
    self[list_column] = Rational.intermediate(nil, next_record.send(list_column)).to_f
    yield
  end

  def list_begin
    self[list_column] = Rational::INTERMEDIATE_BEGIN.to_f
    yield
  end
end
