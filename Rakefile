#!/usr/bin/env rake
require "bundler/gem_tasks"
require 'rake/testtask'

Rake::TestTask.new('test') do |test|
  test.libs << 'lib'
  test.verbose = true
  test.test_files = Dir.glob('test/test_*.rb')
end
