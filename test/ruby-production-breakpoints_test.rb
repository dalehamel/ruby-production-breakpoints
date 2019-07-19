require 'test_helper'

module ProductionBreakpoints
  class RubyProductionBreakpointsTest < MiniTest::Test

    def test_load_from_config
      require ruby_source_testfile_path('config_target.rb')
      ProductionBreakpoints.config_path = config_testfile_path('test_load.json')
      ProductionBreakpoints.reload_config

      bp = JSON.load(File.read(ProductionBreakpoints.config_path))['breakpoints'].first
      assert(ProductionBreakpoints::MyConfigClass.instance_methods.include?(:some_method))

      #refute(ProductionBreakpoints::MyConfigClass.ancestors.first.name.nil?)
      ProductionBreakpoints.install_breakpoint(ProductionBreakpoints::Breakpoints::Inspect,
                                               bp['source_file'], bp['start_line'], bp['end_line'],
                                               trace_id: bp['trace_id'])
      c = ProductionBreakpoints::MyConfigClass.new
      assert(2, c.some_method)

      assert(ProductionBreakpoints::MyConfigClass.ancestors.first.name.nil?)
      assert(c.respond_to?(:production_breakpoint_enabled?))
      assert(c.production_breakpoint_enabled?)

      breakpoint = ProductionBreakpoints.installed_breakpoints[bp['trace_id'].to_sym]
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
