import '@@/mix_template/packs/base'
import Chartkick from 'chartkick'
import Chart from 'chart.js'
import Hamster from 'hamsterjs'

import '@@/mix_admin/all'

Chartkick.use(Chart)

document.addEventListener('DOMContentLoaded', function () {
  window.Chartkick = Chartkick
  window.Hamster = Hamster
})
