module ProductionBreakpoints
  module Breakpoints
    # Inspect result of the last evaluated expression
    class Inspect < Base
      TRACEPOINT_TYPES = [String]

      def handle(caller_binding, &block)
        return super(caller_binding, &block) unless @tracepoint.enabled?
        val = super(caller_binding, &block)
        @tracepoint.fire(val.inspect)
        return val
      end
    end
  end
end
