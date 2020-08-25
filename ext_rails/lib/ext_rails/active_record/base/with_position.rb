# TODO subqueries
# http://joshfrankel.me/blog/constructing-a-sql-select-from-subquery-in-activerecord/
# https://pganalyze.com/blog/active-record-subqueries-rails
# TODO ActiveRecord::RecordNotUnique or reshuffle elements (move and replace by integers)
module ActiveRecord::Base::WithPosition
  extend ActiveSupport::Concern

  included do
    class_attribute :list_column, instance_writer: false, default: :position
  end

  def list_insert_between(previous_record, next_record)
    first, middle, last = [previous_record, self, next_record].sort_by{ |record| record.send(self.class.primary_key) }
    first.with_lock do
      middle.with_lock do
        last.with_lock do
          limits = [first.send(list_column), last.send(list_column)].sort
          update! list_column => Rational.intermediate(*limits).to_f
        end
      end
    end
  end

  def list_insert_after(previous_record)
    next_record = _list_next_record(previous_record)
    if next_record
      list_insert_between(previous_record, next_record)
    else
      _list_insert_after(previous_record)
    end
  end

  def list_insert_before(next_record)
    previous_record = _list_previous_record(next_record)
    if previous_record
      list_insert_between(previous_record, next_record)
    else
      _list_insert_before(next_record)
    end
  end

  def list_push
    if (last_record = _list_last_record)
      _list_insert_after(last_record)
    else
      with_lock do
        update! list_column => 1.0
      end
    end
  end

  def list_unshift
    if (first_record = _list_first_record)
      _list_insert_before(first_record)
    else
      with_lock do
        update! list_column => 1.0
      end
    end
  end

  def _list_insert_before(next_record)
    first, last = [self, next_record].sort_by{ |record| record.send(self.class.primary_key) }
    first.with_lock do
      last.with_lock do
        first_position = next_record.send(list_column)
        update! list_column => Rational.intermediate(nil, first_position).to_f
      end
    end
  end

  def _list_insert_after(previous_record)
    first, last = [previous_record, self].sort_by{ |record| record.send(self.class.primary_key) }
    first.with_lock do
      last.with_lock do
        last_position = previous_record.send(list_column)
        update! list_column => Rational.intermediate(last_position, nil).to_f
      end
    end
  end

  def _list_previous_record(next_record = nil)
    position = next_record ? next_record.send(list_column) : send(list_column)
    self.class.where(self.class.column(list_column) < position).order(list_column => :desc).first if position
  end

  def _list_next_record(previous_record = nil)
    position = previous_record ? previous_record.send(list_column) : send(list_column)
    self.class.where(self.class.column(list_column) > position).order(list_column => :asc).first if position
  end

  def _list_first_record
    self.class.order(list_column => :asc).first
  end

  def _list_last_record
    self.class.order(list_column => :desc).first
  end
end
