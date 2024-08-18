# frozen_string_literal: true

MonkeyPatch.add{['actionview', 'lib/action_view/helpers/output_safety_helper.rb', '46e1dae16ff52d38bb99cc9c2d59382260eecf25ce3b5bb19152df5ae93d6b23']}

module ActionView::Helpers::OutputSafetyHelper
  def safe_join(array, sep = $,, options = {})
    options.assert_valid_keys(:sanitize)
    sep = ERB::Util.unwrapped_html_escape(sep)

    array.flatten.map! do |i|
      options[:sanitize] ? sanitize(i) : ERB::Util.unwrapped_html_escape(i)
    end.join(sep).html_safe
  end

  def to_sentence(array, options = {})
    options.assert_valid_keys(:words_connector, :two_words_connector, :last_word_connector, :locale, :sanitize)

    default_connectors = {
      words_connector: ", ",
      two_words_connector: " and ",
      last_word_connector: ", and "
    }
    if defined?(I18n)
      i18n_connectors = I18n.translate(:'support.array', locale: options[:locale], default: {})
      default_connectors.merge!(i18n_connectors)
    end
    options = default_connectors.merge!(options)

    case array.length
    when 0
      "".html_safe
    when 1
      options[:sanitize] ? sanitize(array[0]) : ERB::Util.html_escape(array[0])
    when 2
      safe_join([array[0], array[1]], options[:two_words_connector], sanitize: options[:sanitize])
    else
      safe_join(
        [safe_join(
           array[0...-1],
           options[:words_connector],
           sanitize: options[:sanitize]
         ),
         options[:last_word_connector],
         array[-1]
        ],
        nil,
        sanitize: options[:sanitize]
      )
    end
  end
end
