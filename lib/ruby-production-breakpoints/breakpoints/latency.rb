require 'ruby-static-tracing'

module ProductionBreakpoints
  module Breakpoints
    class Latency < Base # FIXME refactor a bunch of these idioms into Base

      def handle(caller_binding, &block)
        return super(caller_binding, &block) unless @tracepoint.enabled?
        start_time = StaticTracing.nsec
        val = super(caller_binding, &block)
        duration = StaticTracing.nsec - start_time
        @tracepoint.fire(duration)
        return val
      end
    end
  end
end
