require 'unmixer'
using Unmixer

module ProductionBreakpoints
  module Breakpoints
    class Base

      def initialize(source_file, start_line, end_line, trace_id: 1)
        @source_file = source_file
        @start_line = start_line
        @end_line = end_line
        @trace_id = trace_id
      end

      def install
        @parser = ProductionBreakpoints::Parser.new(@source_file)
        node = @parser.find_definition_node(@start_line, @end_line)
        @redefined = build_redefined_definition_module(node)
        ns = Object.const_get(@parser.find_definition_namespace(node))
        ns.prepend(@redefined)
      end

      # FIXME saftey if already uninstalled
      def uninstall
        ns.class.instance_eval( unprepend(@redefined) )
      end

      def load
        @tracepoint.provider.enable
      end

      # Allows for specific handling of the selected lines
      def handle(caller_binding)
        return eval(yield, caller_binding)
      end

      # Execute remaining lines of method in the same binding
      def finish(caller_binding)
        eval(yield, caller_binding)
      end

    private

      def build_redefined_definition_module(node)
        injected = @parser.inject_ruby_block("local_bind=binding; ProductionBreakpoints.installed_breakpoints[#{@trace_id}].handle(local_bind)",
                                             "ProductionBreakpoints.installed_breakpoints[#{@trace_id}].finish(local_bind)",
                                             node.first_lineno, node.last_lineno, @start_line, @end_line)
        Module.new { module_eval{ eval(injected); eval('def production_breakpoint_enabled?; true; end;') } }
      end
    end
  end
end
