# frozen_string_literal: true

require 'logger'

require 'ruby-production-breakpoints/version'
require 'ruby-production-breakpoints/parser'
require 'ruby-production-breakpoints/breakpoints'

module ProductionBreakpoints
  extend self

  BaseError = Class.new(StandardError)
  InternalError = Class.new(BaseError)

  attr_accessor :logger, :installed_breakpoints

  self.logger = Logger.new(STDERR)
  self.installed_breakpoints = {}

  def install_breakpoint(type, source_file, start_line, end_line, trace_id: 1)

    case type
    when 'latency'
      breakpoint = Breakpoints::Latency.new(source_file, start_line, end_line, trace_id: trace_id)
      self.installed_breakpoints[trace_id] = breakpoint
      breakpoint.install
      breakpoint.load
      # now rewrite source to call this created breakpoint through parser
    else
      logger.debug("Unsupported breakpoint type #{type}")
    end
  end

  # load config file and refresh breakpoints
  # do this at init, but also trigger this via a signal handler
  # def reload_config
end
