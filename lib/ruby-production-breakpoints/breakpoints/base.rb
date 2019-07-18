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
        @method = self.class.name.split('::').last.downcase
        @parser = ProductionBreakpoints::Parser.new(@source_file)
        @node = @parser.find_definition_node(@start_line, @end_line)
        @ns = Object.const_get(@parser.find_definition_namespace(@node))
        @tracepoint = StaticTracing::Tracepoint.new(File.basename(@source_file).gsub('.', '_'), "#{@method}_#{@trace_id}", Integer)
      end

      def install
        @redefined = build_redefined_definition_module(@node)
        @ns.prepend(@redefined)
      end

      # FIXME saftey if already uninstalled
      def uninstall
        ns.class.instance_eval( unprepend(@redefined) )
      end

      def load
        @tracepoint.provider.enable
      end

      def unload
        @tracepoint.provider.disable
      end

      # Allows for specific handling of the selected lines
      def handle(caller_binding)
        eval(yield, caller_binding)
      end

      # Execute remaining lines of method in the same binding
      def finish(caller_binding)
        eval(yield, caller_binding)
      end

    private

      # A custom module we'll prepend in order to override
      # It will inject handlers before and after the target lines, allowing
      # us to keep the expected binding for the wrapped code, and remainder of the method
      def build_redefined_definition_module(node)
        injected = @parser.inject_ruby_block("local_bind=binding; ProductionBreakpoints.installed_breakpoints[#{@trace_id}].handle(local_bind)",
                                             "ProductionBreakpoints.installed_breakpoints[#{@trace_id}].finish(local_bind)",
                                             node.first_lineno, node.last_lineno, @start_line, @end_line)
        Module.new { module_eval{ eval(injected); eval('def production_breakpoint_enabled?; true; end;') } }
      end
    end
  end
end
