require 'ruby-static-tracing'

module ProductionBreakpoints
  module Breakpoints
    class Latency < Base # FIXME refactor a bunch of these idioms into Base

      def initialize(*args, &block)
        super(*args, &block)
        @method = 'latency'
        @tracepoint = StaticTracing::Tracepoint.new(File.basename(@source_file).gsub('.', '_'), "#{@method}_#{@trace_id}", Integer)
      end

      def handle(caller_binding)
        return eval(yield, caller_binding) unless @tracepoint.enabled?
        start_time = StaticTracing.nsec
        v = eval(yield, caller_binding)
        duration = StaticTracing.nsec - start_time
        @tracepoint.fire(duration)
        return v
      end
    end
  end
end
