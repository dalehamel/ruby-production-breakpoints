# frozen_string_literal: true

require 'unmixer'
using Unmixer

module ProductionBreakpoints
  module Breakpoints
    class Base
      TRACEPOINT_TYPES = [].freeze

      attr_reader :provider_name, :name, :node :start_line, :end_line

      def initialize(source_file, start_line, end_line, trace_id: 1)
        @injector_module = nil
        @source_file = source_file
        @start_line = start_line
        @end_line = end_line
        @trace_id = trace_id

        @method = self.class.name.split('::').last.downcase
        @parser = ProductionBreakpoints::Parser.new(@source_file)
        @node = @parser.find_definition_node(@start_line, @end_line)
        @ns = Object.const_get(@parser.find_definition_namespace(@node)) # FIXME: error handling, if not found
        @provider_name = File.basename(@source_file).gsub('.', '_')
        @name = "#{@method}_#{@trace_id}"
        @tracepoint = StaticTracing::Tracepoint.new(@provider_name, @name, *self.class.const_get('TRACEPOINT_TYPES'))
        compile
      end


      def install
        @injector_module = build_redefined_definition_module(@node)
        @ns.prepend(@injector_module)
      end

      # FIXME: saftey if already uninstalled
      def uninstall
        @ns.instance_eval { unprepend(@injector_module) }
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
        @handler_iseq.eval(caller_binding)
        @resume_iseq.eval(caller_binding)
      rescue ArgumentError
        # If we got here, then https://github.com/ruby/ruby/pull/2298 is probably unmerged
        # This fallback behavior is less efficient as it continuously calls eval.
        # You can run a patched ruby with support for this by following
        # https://gist.github.com/dalehamel/4aafc5436105937c0e0ad4316e583f70
        # FIXME should this print a warning the first time it is hit?
        eval(@handler_src, caller_binding)
        eval(@resume_src, caller_binding)
      end

      private

      # A custom module we'll prepend in order to override
      # It will inject handlers before and after the target lines, allowing
      # us to keep the expected binding for the wrapped code, and remainder of the method
      def build_redefined_definition_module
        # This is the metaprogramming to inject our breakpoint handler around the original source code
        handler = "ProductionBreakpoints.installed_breakpoints[:#{@trace_id}].handle(Kernel.binding)"

        # ProductionBreakpoints.logger.debug(injected)
        Module.new { module_eval { eval(injected); eval('def __production_breakpoint_enabled?; true; end;') } }
      end


     # This method is a litle weird and pretty deep into metaprogramming, so i'll try to explain it
     #
     # Given the source method some_method, and a range of lines to apply the breakpoint to, we will inject
     # calls two breakpoint methods. We will pass these calls the string representation of the original source code.
     # If the string of original source is part of the "handle" block, it will run withing the binding
     # of the method up to that point, and allow for us to run our custom handler method to apply our debugging automation.
     #
     # Any remaining code in the method also needs to be eval'd, as we want it to be recognized in the original binding,
     # and the same binding as we've used for evaluating our handler. This allows us to keep local variables persisted
     # "between blocks", as we want our breakpoint code to have no impact to the original bindings and source code.
     #
     # A generated breakpoint is shown below, the resulting string. is what will be evaluated on the method
     # that we will prepend to the original parent in order to initiate our override.
     #
     # def some_method
     # local_bind=binding; ProductionBreakpoints.installed_breakpoints[:test_breakpoint_install].handle(local_bind) do
     # <<-EOS
     #       a = 1
     #       sleep 0.5
     #       b = a + 1
     # EOS
     # end
     #  ProductionBreakpoints.installed_breakpoints[:test_breakpoint_install].finish(local_bind) do
     # <<-EOS
     # EOS
     # end
     #     end
     #
     # In this example, the entire body of the method has been wrapped in our handler.
     # FIXME is there an elegant way to save the line number and file information here, and make
     # FIXME inject by column, not just line, to ensure edge cases work
     # it available to eval later? Would help to debug what is being eval'd
    end
  end
end
