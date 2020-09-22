# Configuration of the list view
class RailsAdmin::Config::Model::Sections::Index < RailsAdmin::Config::Model::Sections::Base
  register_instance_option :checkboxes? do
    true
  end

  register_instance_option :filters do
    []
  end

  register_instance_option :query?, memoize: true do
    true
  end

  # Number of items listed per page
  register_instance_option :items_per_page do
    RailsAdmin.config.default_items_per_page
  end

  register_instance_option :max_items_per_page do
    RailsAdmin.config.default_max_items_per_page
  end

  # TODO use model_class.size with a cutoff
  # Positive value shows only prev, next links in pagination.
  # This is for avoiding count(*) query.
  register_instance_option :limited_pagination? do
    false
  end

  register_instance_option :sort_by do
    klass.column_names.include?('updated_at') ? :updated_at : abstract_model.primary_key
  end

  register_instance_option :sort_reverse? do
    true # By default show latest first
  end

  register_instance_option :sort_paginate do
    [abstract_model.primary_key.to_sym]
  end

  register_instance_option :scopes do
    []
  end

  register_instance_option :truncate_length do
    RailsAdmin.config.default_truncate_length
  end

  register_instance_option :row_css_class do
    ''
  end

  register_instance_option :frozen_column?, memoize: true do
    true
  end

  register_instance_option :dynamic_columns?, memoize: true do
    false
  end

  register_instance_option :include_columns do
    nil
  end

  register_instance_option :exclude_columns do
    nil
  end

  register_instance_option :exists? do
    true
  end

  def no_filters?
    if !(list = objects)
      true
    elsif (values = list.values).has_key? :where
      values[:where].send(:predicates).size <= 1
    else
      true
    end
  end
end
