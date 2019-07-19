# frozen_string_literal: true

require 'logger'
require 'json'

require 'ruby-static-tracing'

require 'ruby-production-breakpoints/version'
require 'ruby-production-breakpoints/parser'
require 'ruby-production-breakpoints/breakpoints'

module ProductionBreakpoints
  extend self

  BaseError = Class.new(StandardError)
  InternalError = Class.new(BaseError)

  attr_accessor :logger, :installed_breakpoints, :config_path

  self.logger = Logger.new(STDERR)
  self.installed_breakpoints = {}
  self.config_path = "/tmp/prod_bp_config" # How to handle multiple?

  # For now add new types here
  def install_breakpoint(type, source_file, start_line, end_line, trace_id: 1)

    # Hack to check if there is a supported breakpoint of this type for now
    case type.name
    when 'ProductionBreakpoints::Breakpoints::Latency'
    when 'ProductionBreakpoints::Breakpoints::Inspect'
    when 'ProductionBreakpoints::Breakpoints::Locals'
      #logger.debug("Creating latency tracer")
      # now rewrite source to call this created breakpoint through parser
    else
      logger.error("Unsupported breakpoint type #{type}")
    end

    breakpoint = type.new(source_file, start_line, end_line, trace_id: trace_id)
    self.installed_breakpoints[trace_id.to_sym] = breakpoint
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
  def reload_config
    return unless File.exists?(self.config_path)
    config = JSON.load(File.read(self.config_path))

    config['breakpoints'].each do |bp|
      type = Object.const_get("ProductionBreakpoints::Breakpoints::#{bp['type'].capitalize}")
      install_breakpoint(type, bp['source_file'], bp['start_line'], bp['end_line'], trace_id: bp['trace_id'])
    end
  end
end
