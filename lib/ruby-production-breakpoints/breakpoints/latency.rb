# frozen_string_literal: true

module ProductionBreakpoints
  module Breakpoints
    # Exposes nanosecond the latency of executing the selected lines
    class Latency < Base # FIXME: refactor a bunch of these idioms into Base
      TRACEPOINT_TYPES = [Integer].freeze

      def handle(caller_binding, &block)
        return super(caller_binding, &block) unless @tracepoint.enabled?

        start_time = StaticTracing.nsec
        val = super(caller_binding, &block)
        duration = StaticTracing.nsec - start_time
        @tracepoint.fire(duration)
        val
      end
    end
  end
end
