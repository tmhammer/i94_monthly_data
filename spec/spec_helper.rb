require 'simplecov'
SimpleCov.start 'rails'

$LOAD_PATH.unshift File.expand_path('../..', __FILE__)
require 'excel_parser'
require 'ports_parser'
require 'canada_mexico_parser'
require 'visa_type_parser'
require 'data_builder'