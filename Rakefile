# frozen_string_literal: true

require 'rake/testtask'
require 'bundler/gem_tasks'

GEMSPEC    = eval(File.read('ruby-production-breakpoints.gemspec'))
# ==========================================================
# Packaging
# ==========================================================

require 'rubygems/package_task'
Gem::PackageTask.new(GEMSPEC) do |_pkg|
end
