module ProductionBreakpoints
  module Breakpoints
    # Show local variables and their values
    class Locals < Base # FIXME refactor a bunch of these idioms into Base
      TRACEPOINT_TYPES = [String]

      def handle(caller_binding, &block)
        return super(caller_binding, &block) unless @tracepoint.enabled?
        val = super(caller_binding, &block)
        locals = caller_binding.local_variables
        locals.delete(:local_bind) # we define this, so we'll get rid of it
        vals = locals.map { |v| [v, caller_binding.local_variable_get(v) ]}.to_h
        @tracepoint.fire(vals.inspect)
        return val
      end
    end
  end
end
