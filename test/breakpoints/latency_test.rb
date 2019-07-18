require 'test_helper'

module ProductionBreakpoints
  class BreakpointTest < MiniTest::Test

    def test_install_breakpoint
      start_line = 7
      end_line = 8
      source_file = ruby_source_testfile_path('breakpoint_target.rb')
      require source_file
      assert(ProductionBreakpoints::MyClass.instance_methods.include?(:some_method))
      ProductionBreakpoints.install_breakpoint('latency', source_file, start_line, end_line)
      c = ProductionBreakpoints::MyClass.new
      assert(2, c.some_method)
    end

  end
end