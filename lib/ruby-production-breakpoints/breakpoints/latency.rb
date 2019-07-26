# frozen_string_literal: true

module ProductionBreakpoints
  module Breakpoints
    # Exposes nanosecond the latency of executing the selected lines
    class Latency < Base # FIXME: refactor a bunch of these idioms into Base
      TRACEPOINT_TYPES = [Integer].freeze

      # FIXME: needs to take a hash by instance or thread ID
      # Storing @start_time as an instance variable isn't thread safe
      # as a breakpoint can apply to many classes
      def handle(vm_tracepoint)
        return unless @tracepoint.enabled?

        @start_time = StaticTracing.nsec if vm_tracepoint.lineno == @start_line

        if vm_tracepoint.lineno == @end_line
          duration = StaticTracing.nsec - start_time
          @tracepoint.fire(duration)
        end
      end
    end
  end
end
