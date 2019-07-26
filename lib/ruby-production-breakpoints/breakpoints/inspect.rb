# frozen_string_literal: true

module ProductionBreakpoints
  module Breakpoints
    # Inspect result of the last evaluated expression
    class Inspect < Base
      TRACEPOINT_TYPES = [String].freeze

      def handle(vm_tracepoint)
        return unless @tracepoint.enabled?
        val = tracepoint.return_value
        @tracepoint.fire(val.inspect)
      end
    end
  end
end
