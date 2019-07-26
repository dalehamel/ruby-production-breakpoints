# frozen_string_literal: true

module ProductionBreakpoints
  module Breakpoints
    class Base
      TRACEPOINT_TYPES = [].freeze

      attr_reader :provider_name, :name

      def initialize(source_file, start_line, end_line, trace_id: 1)
        @injector_module = nil
        @source_file = source_file
        @start_line = start_line
        @end_line = end_line
        @trace_id = trace_id
        @handler_str = self.class.name.split('::').last.downcase

        @parser = ProductionBreakpoints::Parser.new(@source_file)
        @node = @parser.find_definition_node(@start_line, @end_line)
        @ns = Object.const_get(@parser.find_definition_namespace(@node)) # FIXME: error handling, if not found
        @method_symbol = @parser.find_definition_symbol(@node)

        @provider_name = File.basename(@source_file).gsub('.', '_')
        @name = "#{@handler_str}_#{@trace_id}"
        @tracepoint = StaticTracing::Tracepoint.new(@provider_name,
                                                    @name,
                                                    *self.class.const_get('TRACEPOINT_TYPES'))
      end

      def install
        @vm_tracepoint = TracePoint.new(:line) do |tp|
          self.handle(tp)
        end
        @vm_tracepoint.enable(target: @ns.instance_method(@method_symbol))
      end

      def uninstall
        @vm_tracepoint.disable
      end

      def load
        @tracepoint.provider.enable
      end

      def unload
        @tracepoint.provider.disable
      end

      # Allows for specific handling of the selected lines
      def handle(caller_binding)
      end

    end
  end
end
