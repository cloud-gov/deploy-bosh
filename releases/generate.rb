#!/usr/bin/env ruby

require 'erb'
require 'yaml'

inputs = ARGV

template = ERB.new(File.read(File.join(__dir__, 'pipeline.yml.erb')))

b = binding
inputs.each do |input|
  YAML.load(File.read(input)).map do |key, value|
    b.local_variable_set(key, value)
  end
end

puts template.result(b)
