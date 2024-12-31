extends 'layouts/application' do
  div_ '.card.card-compact', [
    div_('.card-title', area(:title)),
    yield,
    div_('.card-actions', user_links),
  ]
end
