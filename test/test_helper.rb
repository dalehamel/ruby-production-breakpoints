# frozen_string_literal: true

require 'simplecov'
SimpleCov.start
require 'minitest/autorun'
require 'pry-byebug' if ENV['PRY']
require_relative '../lib/ruby-production-breakpoints.rb'

def ruby_source_testfile_path(source_name)
  File.join(__dir__, 'ruby_sources', source_name)
end
