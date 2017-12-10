require 'ostruct'

class Filter
  attr_accessor :filter

  class FilterError < StandardError; end

  def initialize
    @filter = OpenStruct.new
  end

  def empty?
    filter.to_h.empty?
  end

  def months_ago(months = nil)
    filter[:months_ago] = months if months
    filter[:months_ago]
  end

  def repeats(repeats = nil)
    filter[:repeats] = repeats if repeats
    filter[:repeats]
  end

=begin
  def datetime_range(from: nil, to: nil)
    filter[:datetime_range] = { period_start: from, period_end: to } if (from && to)
    filter[:datetime_range]
  end
=end

  def archetype(archetype = nil)
    filter[:archetype] = archetype if archetype
    filter[:archetype]
  end

  def distinct(distinct = nil)
    filter[:distinct] = distinct if distinct
    filter[:distinct]
  end

  def exclude_topic(exclude_topic = nil)
    filter[:exclude_topic] = exclude_topic if exclude_topic
    filter[:exclude_topic]
  end

  def action_type(action_type = nil)
    filter[:action_type] = action_type if action_type
    filter[:action_type]
  end

  def method_missing(method_sym, *arguments, &block)
    if filter.respond_to?(method_sym)
      begin
        filter.send(method_sym, *arguments, &block)
      rescue ArgumentError
        filter.send(method_sym)
      end
    else
      raise NoMethodError, "#{method_sym.to_s} method is undefined"
    end
  end

end
