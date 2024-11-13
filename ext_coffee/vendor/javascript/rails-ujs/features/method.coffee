# Handles "data-method" on links such as:
# <a href="/users/5" data-method="delete" rel="nofollow" data-confirm="Are you sure?">Delete</a>
Rails.merge
  handle_method: (e) ->
    link = this
    method = link.getAttribute('data-method')
    return unless method

    href = Rails.href(link)
    token = Rails.csrf_token()
    param = Rails.csrf_param()
    form = document.createElement('form')
    data = "<input name='_method' value='#{method}' type='hidden' />"

    if param? and token? and not Rails.is_cross_domain(href)
      data += "<input name='#{param}' value='#{token}' type='hidden' />"

    # Must trigger submit by click on a button, else "submit" event handler won't work!
    # https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/submit
    data += '<input type="submit" />'

    form.method = 'post'
    form.action = href
    form.target = link.target
    form.innerHTML = data
    form.style.display = 'none'

    document.body.appendChild(form)
    form.find('[type="submit"]').click()

    Rails.stop_everything(e)
