require 'unmixer'
using Unmixer

module ProductionBreakpoints
  module Breakpoints
    class Base
      TRACEPOINT_TYPES = []

      attr_reader :provider_name, :name

      def initialize(source_file, start_line, end_line, trace_id: 1)
        @injector_module = nil
        @source_file = source_file
        @start_line = start_line
        @end_line = end_line
        @trace_id = trace_id
        @method = self.class.name.split('::').last.downcase
        @parser = ProductionBreakpoints::Parser.new(@source_file)
        @node = @parser.find_definition_node(@start_line, @end_line)
        @ns = Object.const_get(@parser.find_definition_namespace(@node)) # FIXME error handling, if not found
        @provider_name = File.basename(@source_file).gsub('.', '_')
        @name = "#{@method}_#{@trace_id}"
        @tracepoint = StaticTracing::Tracepoint.new(@provider_name, @name, *(self.class.const_get('TRACEPOINT_TYPES')))
      end

      def install
        @injector_module = build_redefined_definition_module(@node)
        @ns.prepend(@injector_module)
      end

      # FIXME saftey if already uninstalled
      def uninstall
        @ns.instance_eval{ unprepend(@injector_module) }
        @injector_module = nil
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

        # This is the metaprogramming to inject our breakpoint handler around the original source code
        handler = "local_bind=binding; ProductionBreakpoints.installed_breakpoints[:#{@trace_id}].handle(local_bind)"

        # This is needed to keep the execution of the remaining lines of the method within the same binding
        finisher = "ProductionBreakpoints.installed_breakpoints[:#{@trace_id}].finish(local_bind)"

        # This injects our handler and finisher blocks into the original source code, treating the code
        # in between as string literals to be evaluated
        injected = @parser.inject_metaprogramming_handlers(handler, finisher,
                                             node.first_lineno, node.last_lineno, @start_line, @end_line)
        #ProductionBreakpoints.logger.debug(injected)
        Module.new { module_eval{ eval(injected); eval('def production_breakpoint_enabled?; true; end;') } }
      end
    end
  end
end
