# frozen_string_literal: true

require 'logger'

require 'ruby-static-tracing'

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

  # For now add new types here
  def install_breakpoint(type, source_file, start_line, end_line, trace_id: 1)

    # Hack to check if there is a supported breakpoint of this type for now
    case type.name
    when 'ProductionBreakpoints::Breakpoints::Latency'
      #logger.debug("Creating latency tracer")
      # now rewrite source to call this created breakpoint through parser
    else
      logger.error("Unsupported breakpoint type #{type}")
    end

    breakpoint = type.new(source_file, start_line, end_line, trace_id: trace_id)
    self.installed_breakpoints[trace_id] = breakpoint
    breakpoint.install
    breakpoint.load
  end

  def disable_breakpoint(trace_id)
    breakpoint = self.installed_breakpoints.delete(trace_id)
    breakpoint.unload
    breakpoint.uninstall
  end

  # load config file and refresh breakpoints
  # do this at init, but also trigger this via a signal handler
  # def reload_config
end
