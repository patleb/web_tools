h_(
  form_tag('/coffee/new', remote: true, method: :get) do
    submit_tag 'Create'
  end,
)
