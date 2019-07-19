# frozen_string_literal: true

require 'simplecov'
SimpleCov.start
require 'minitest/autorun'
require 'pry-byebug' if ENV['PRY']
require_relative '../lib/ruby-production-breakpoints.rb'

def ruby_source_testfile_path(source_name)
  File.join(__dir__, 'ruby_sources', source_name)
end

def config_testfile_path(config)
  File.join(__dir__, 'config', config)
end

def find_provider_fd(provider_name)
  Dir["/proc/#{Process.pid}/fd/*"].each do |fd|
    return fd if File.readlink(fd).include?(provider_name)
  rescue Errno::ENOENT
  end
end
