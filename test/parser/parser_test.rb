require 'test_helper'

module ProductionBreakpoints
  class ParserTest < MiniTest::Test


    def test_find_known_method_symbol
      start_line = 28
      end_line = 29
      source_file = ruby_source_testfile_path('ruby-static-tracing.rb')
      parser = ProductionBreakpoints::Parser.new(source_file)

      def_name = parser.find_definition_symbol(start_line, end_line)
      assert(def_name == :issue_disabled_tracepoints_warning)
    end

    def test__find_definition_node
      start_line = 28
      end_line = 29
      source_file = ruby_source_testfile_path('ruby-static-tracing.rb')
      parser = ProductionBreakpoints::Parser.new(source_file)

      def_node = parser._find_definition_node(parser.root_node, start_line, end_line)
      assert(def_node.type == :DEFN)
      assert(start_line >= def_node.first_lineno)
      assert(end_line <= def_node.last_lineno)
    end

    def test_read_ruby_source
      start_line = 27
      end_line = 32
      source_file = ruby_source_testfile_path('ruby-static-tracing.rb')
      parser = ProductionBreakpoints::Parser.new(source_file)

      definition = parser.ruby_source(start_line, end_line)
      expected = <<-EOF
  def issue_disabled_tracepoints_warning
    return if defined?(@warning_issued)

    @warning_issued = true
    logger.info("USDT tracepoints are not presently supported supported on \#{RUBY_PLATFORM} - all operations will no-op")
  end
EOF

      assert_equal(definition, expected)
    end

    def test_find_definition_namespace
      start_line = 7
      end_line = 8
      source_file = ruby_source_testfile_path('breakpoint_target.rb')
      require source_file
      assert(ProductionBreakpoints::MyClass.instance_methods.include?(:some_method))

      parser = ProductionBreakpoints::Parser.new(source_file)

      def_node = parser._find_definition_node(parser.root_node, start_line, end_line)

      ns = Object.const_get(parser.find_definition_namespace(def_node))

      assert_equal(ProductionBreakpoints::MyClass, ns)
    end

  end
end
