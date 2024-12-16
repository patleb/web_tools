require './test/test_helper'

class PagesControllerTest < ActionDispatch::IntegrationTest
  fixtures :users

  let!(:page){ Page.create_home! }

  test '#show' do
    get "/accueil-fr/page/#{page.uuid}"
    assert_response :ok
    assert_equal 'pages', self[:@page].layout.view.to_s
    assert_equal 'pages/home', self[:@page].template
  end

  context '#show' do
    test 'with invalid :slug' do
      get '/not/page'
      assert_response :not_found
    end

    test 'with unauthorized :slug' do
      page.update! published_at: nil
      get '/home/page'
      assert_response :not_found
    end

    test 'with stale :slug' do
      get "/not/page/#{page.uuid}"
      assert_redirected_to page.to_url
    end

    test 'redirect to :uuid' do
      get "/home/page"
      assert_redirected_to page.to_url
    end

    test 'with :_locale to :en' do
      get "/home-en/page/#{page.uuid}?_locale=en"
      assert_response :ok
    end
  end

  context 'with admin user' do
    let(:current_user){ users(:admin) }

    test '#field_create' do
      post "/page/#{page.uuid}/field", params: { page: { field: { type: 'PageFields::Html', name: 'list_texts' } } }
      id = PageFields::Html.order(created_at: :desc).pick(:id)
      assert_redirected_to MixAdmin::Routes.edit_url(model_name: 'PageFields::Html'.to_class_param, id: id)
    end

    test '#field_update' do
      link_prev = page.sidebar
      link_next = page.links.create! page_id: page.layout_id, name: :sidebar
      assert link_next.position > link_prev.position
      post "/page/#{page.uuid}/field/#{link_next.id}", params: { page: { field: { list_next_id: link_prev.id } } }
      link_prev.reload; link_next.reload
      assert link_next.position < link_prev.position
      assert body.dig(:flash, :notice)
      assert_response :ok
    end
  end

  context '#field_create' do
    test 'with invalid :name' do
      post "/page/#{page.uuid}/field", params: { page: { field: { type: 'PageFields::Link', name: 'unknown' } } }
      assert_redirected_to page.to_url
    end

    test 'with unauthorized user' do
      post "/page/#{page.uuid}/field", params: { page: { field: { type: 'PageFields::Link', name: 'sidebar' } } }
      assert_redirected_to page.to_url
    end
  end
end
