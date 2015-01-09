#!/usr/bin/env ruby
# encoding: UTF-8

require 'bundler/setup'

require 'redis'
require 'json'
require 'optparse'

params = Struct.new('Params', :fields, :limit).new ['offering_type', 'features'], 5

$option = OptionParser.new{|opt|
  opt.version = '0.0.1'
  opt.on '-f [fields]', '--fields', String, 'fields separated by "," (e.g. "offering_type,features")' do|fields|
    raise 'No fields given' if fields.nil?
    params.fields = fields.split /[,.]/
  end
  opt.on '-l [limit]', '--limit', Integer, 'limit (e.g. 5)' do|limit|
    params.limit = limit
  end
}

def print_help
  STDERR.puts $option.help
  exit 1
end

class String
  def red
    "\033[31m#{self}\033[0m"
  end
end

begin
  $option.parse!
rescue OptionParser::ParseError, RuntimeError => e
  print_help
end

print_help if params.fields.nil? || params.limit.nil?

redis = Redis.new

keys = redis.keys('*')

exit if keys.empty?

targetKeys = keys.sample(params.limit)

print_help if targetKeys.empty?

vals = redis.mget targetKeys

vals.each_with_index do|val, idx|
  puts '=' * 50
  puts "  key: #{targetKeys[idx]}"

  fields = params.fields

  begin
    parsed = JSON.parse val

    fields.size == 1 \
      and fields.first.downcase == 'all' \
      and fields = parsed.keys

    fields.each do|field|
      puts "  #{field}: #{parsed[field]}"
    end
  rescue JSON::ParserError, TypeError => e
    STDERR.puts "  Error: #{e}".red
  end

  puts
end
