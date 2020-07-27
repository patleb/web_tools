class RailsAdmin.Form.DirectorySelectConcept
  constants: =>
    INPUT: 'CLASS'

  document_on: => [
    'change', @INPUT, (event, target) =>
      event.preventDefault()
      try
        directory = target[0].files[0].webkitRelativePath.split('/')[0]
      catch
        return false
      input = target.data('input')
      $(input).val(directory)
  ]
