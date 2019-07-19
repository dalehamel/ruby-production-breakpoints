[![Build Status](https://travis-ci.org/dalehamel/ruby-production-breakpoints.svg?branch=master)](https://travis-ci.org/dalehamel/ruby-production-breakpoints)

# Ruby Production Breakpoints

This is the start of a gem to enable "production breakpoints" in Ruby.

This Gem is a hack days project idea meant to power a prototype, and not actually suitable for production use (yet).

# What this does

This gem lets you dynamically add "production breakpoints" to a live, running application to see what it is doing.

Once you're done debugging, the breakpoints can be unloaded and removed.

# How this works

Ruby "production breakpoints" rewrite the source code of a method with the targeted lines to include a wrapper around those lines.

The method is redefined by prepending a module with the new definition to the parent of the original method, overriding it. To undo this,
the module can be 'unprepended' restoring the original behavior.

When a breakpoint line is executed, we can use the Linux Kernel to interrupt our application and retrieve some data we've prepared for it.

Unless a breakpoint is both enabled and attached to by a debugger, it shouldn't change execution
