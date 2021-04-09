# frozen_string_literal: true

require 'singleton'

##
# Toki Pona dictionary
class TPDict
  include Singleton

  attr_accessor :tp_inli, :pu

  SOURCES = [
    'http://tokipona.org/compounds.txt',
    'http://tokipona.org/nimi_pi_pu_ala.txt',
    'http://tokipona.org/nimi_pu.txt'
  ].freeze

  def sourcelist
    SOURCES.join(', ')
  end

  def get_all(urls)
    urls.map { YAML.safe_load(URI.open(_1)) }
  end

  def merge_defs(yamls)
    yamls.each_with_object({}) { _2.merge! _1 }
  end

  def process_tp_inli(input)
    input.transform_values do |v|
      v.map do |usage|
        *w, c = usage.split
        [w.join(' '), c.to_i]
      end
    end
  end

  def load_tp_inli
    process_tp_inli(merge_defs(get_all(SOURCES)))
  end

  def load_pu
    YAML
      .load_file('./lib/resources/tokipona/pu.yml')
      .transform_values(&:symbolize_keys)
  end

  def initialize
    @tp_inli = load_tp_inli
    @pu = load_pu
  end

  FREQ_MAP = {
    81..100 => '⁵',
    61..80 => '⁴',
    41..60 => '³',
    21..40 => '²',
    11..20 => '¹',
    0..10 => '⁰'
  }.freeze

  def freq_char(freq)
    FREQ_MAP.select { _1.include? freq }.values.first
  end

  def freqlist(vals)
    vals.map { "#{_1}#{freq_char _2}" }.join(', ')
  end

  def query_tp_inli(query, limit: 0, overflow_text: '[...]')
    data = @tp_inli[query] || (return nil)

    if limit.zero? || data.size <= limit
      freqlist(data)
    else
      "#{freqlist(data.first(8))}, #{overflow_text}"
    end
  end

  def query_pu(query)
    data = @pu[query] || (return nil)

    data.map do |(type, desc)|
      "*~#{type}~* #{desc}"
    end.join("\n")
  end
end
