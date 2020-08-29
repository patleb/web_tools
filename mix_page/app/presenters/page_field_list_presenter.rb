class PageFieldListPresenter < ActionPresenter::Base[:@page, :@virtual_path]
  delegate :key, to: 'list.first.object'

  def render(&block)
    ul_ class: ["#{key}_presenter", dom_class] do
      previous_id = nil
      list.map.with_index do |presenter, i|
        current_id = presenter.object.id
        position = [previous_id, current_id, id_at(i + 1)]
        previous_id = current_id
        li_ class: presenter.dom_class, data: { position: position } do
          presenter.render(&block)
        end
      end
    end
  end

  def dom_class
    self.class.name.full_underscore.delete_suffix('_presenter')
  end

  def id_at(i)
    list[i]&.object&.id
  end
end
