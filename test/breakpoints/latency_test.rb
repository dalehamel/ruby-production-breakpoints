require 'test_helper'

module ProductionBreakpoints
  class LatencyTest < MiniTest::Test

    # FIXME uses linux-specific code, should separate for portability
    def test_install_breakpoint
      start_line = 7
      end_line = 9
      trace_id = :test_breakpoint_install
      source_file = ruby_source_testfile_path('breakpoint_target.rb')
      require source_file
      assert(ProductionBreakpoints::MyClass.instance_methods.include?(:some_method))

      refute(ProductionBreakpoints::MyClass.ancestors.first.name.nil?)
      ProductionBreakpoints.install_breakpoint(ProductionBreakpoints::Breakpoints::Latency,
                                               source_file, start_line, end_line,
                                               trace_id: trace_id)
      c = ProductionBreakpoints::MyClass.new
      assert(2, c.some_method)

      assert(ProductionBreakpoints::MyClass.ancestors.first.name.nil?)
      assert(c.respond_to?(:production_breakpoint_enabled?))
      assert(c.production_breakpoint_enabled?)

      breakpoint = ProductionBreakpoints.installed_breakpoints[trace_id]

      # FIXME this is linux specific from here on
      provider_fd = find_provider_fd(breakpoint.provider_name)
      assert(provider_fd)

      elf_notes = `readelf --notes #{provider_fd}`

      assert_equal(breakpoint.provider_name,
                   elf_notes.lines.find { |l| l =~ /\s+Provider:/ }.split(/\s+/).last)


      assert_equal(breakpoint.name,
                   elf_notes.lines.find { |l| l =~ /\s+Name:/ }.split(/\s+/).last)
    end
  end
end
