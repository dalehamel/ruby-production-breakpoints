# frozen_string_literal: true

require 'logger'
# require 'ruby-static-tracing'

require 'ruby-production-breakpoints/version'
require 'ruby-production-breakpoints/parser'

module ProductionBreakpoints
  extend self

  BaseError = Class.new(StandardError)
  InternalError = Class.new(BaseError)

  attr_accessor :logger

  self.logger = Logger.new(STDERR)
end
