# frozen_string_literal: true

module ProductionBreakpoints
  module Breakpoints
    # Inspect result of the last evaluated expression
    class Inspect < Base
      TRACEPOINT_TYPES = [String].freeze

      def handle(caller_binding, &block)
        return super(caller_binding, &block) unless @tracepoint.enabled?

        val = super(caller_binding, &block)
        @tracepoint.fire(val.inspect)
        val
      end
    end
  end
end
