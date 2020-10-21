extends('layouts/pages/pjax') {[
  yield,
  div_('.footer.col-sm-12') {[
    paginate_sidebar,
    hr_,
    div_('.copyright') { t('application.copyright', year: Time.current.year) },
  ]}
]}
