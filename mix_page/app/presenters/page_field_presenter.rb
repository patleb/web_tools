class PageFieldPresenter < ActionPresenter::Base[:@page, :@virtual_path]
  attr_accessor :list

  def render
    h_(
      div_('.show_object') do
        yield
      end,
      ul_('.member_actions', if: Current.user.admin?) {[
        li_('.edit_object') do
          a_(href: edit_path){ 'edit' }
        end,
        li_('.delete_object') do
          a_(href: delete_path){ 'delete' }
        end
      ]}
    )
  end

  def dom_class
    [super(object), super(object.class.base_class)].uniq
  end

  def edit_path
    authorized_path_for(:edit, object.class, object)
  end

  def delete_path
    authorized_path_for(:delete, object.class, object)
  end
end
