# How this works

Ruby "production breakpoints" rewrite the source code of a method with the targeted lines to include a wrapper around those lines.

The method is redefined by prepending a module with the new definition to the parent of the original method, overriding it. To undo this,
the module can be 'unprepended' restoring the original behavior.

When a breakpoint line is executed, we can use the Linux Kernel to interrupt our application and retrieve some data we've prepared for it.

Unless a breakpoint is both enabled and attached to by a debugger, it shouldn't change execution

# Injecting breakpoints

To do this, we will need to actually rewrite Ruby functions to inject our tracing code around the selected line or lines. Ruby 2.6 + has built-in AST parsing, so we can use this to determine what needs to be redefined, in order to add our tracer.
 
This technique should be applicable to other dynamic languages, but Ruby is particularly well-suited to it, as it is easy to override and redefine methods dynamically at runtime.
 
This gem leverages the ruby-static-tracing gem which provides the 'secret sauce' that allows for plucking this data out of a ruby process, using the kernel’s handling of the intel x86 “Breakpoint” int3 instruction.

The AST parsing will show us the scope of the lines that the user would like to trace, and will load the method scope of the lines, in order to inject the tracing support. This modified ruby code string can then be evaluated in the scope of an anonymous module, which is prepended to the parent of the method that has been redefined.

This will put it at the tip of the chain, and override the original copy of this method. Upon unprepending the module, the original definition should be what is evaluated by Ruby's runtime Polymorphic method message mapping.

# Specifying breakpoints

A global config value:

```ruby
ProductionBreakpoints.config_file
```

Can be set to specify the path to a JSON config, indicating the breakpoints that are to be installed:

```json
{
  "breakpoints": [
    {
      "type": "inspect",
      "source_file": "test/ruby_sources/config_target.rb",
      "start_line": 7,
      "end_line": 9,
      "trace_id": "config_file_test"
    }
  ]
}
```

These values indicate:

* `type`: the built-in breakpoint handler to run when the specified breakpoint is hit in production.
* `source_file`: the source repository-root relative path to the source file to install a breakpoint within. (note, the path of this source folder relative to the host / mount namespace is to be handled elsewhere by the caller that initiates tracing via this gem)
* `start_line`: The first line which should be evaluated from the context of the breakpoint.
* `end_line`: The last line which should be evaluated in the context of the breakpoint
* `trace_id`: A key to group the output of executing the breakpoint, and filter results associated with a particular breakpoint invocation

Many breakpoints can be specified. Breakpoints that apply to the same file are added and removed simultaneously. Breakpoints that are applied but not specified in the config file will be removed if the config file is reloaded.


# Loading breakpoints

For each source file, a 'shadow' ELF stub is associated with it, and can be easily found by inspecting the processes open file handles.

After all breakpoints have been specified for a file, the ELF stub can be generated and loaded. To update or remove breakpoints, this ELF stub needs to be re-loaded, which requires the breakpoints to be disabled first. To avoid this, the scope could be changed to be something other than file, but file is believed to be nice and easily discoverable for now.

The tracing code will noop, until a tracer is actually attached to it, and should have minimal performance implications. Something like unmixer (which hooks into the ruby internal api) could be used to prevent performance degradation caused by growing lists of overridden functions.
