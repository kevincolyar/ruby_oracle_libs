require 'runit/testsuite'
require 'runit/cui/testrunner'

srcdir = File.dirname(__FILE__)

# Low-level API
require "#{srcdir}/test_oradate"
require "#{srcdir}/test_oranumber"
require "#{srcdir}/test_describe"
require "#{srcdir}/test_bind_time"
require "#{srcdir}/test_bind_raw"
if $test_clob
  require "#{srcdir}/test_clob"
end

# High-level API
require "#{srcdir}/test_break"
require "#{srcdir}/test_oci8"
require "#{srcdir}/test_connstr"
require "#{srcdir}/test_metadata"
require "#{srcdir}/test_rowid"

# Ruby/DBI
begin
  require 'dbi'
rescue LoadError
  begin
    require 'rubygems'
    require 'dbi'
  rescue LoadError
    dbi_not_found = false
  end
end
unless dbi_not_found
  require "#{srcdir}/test_dbi"
  if $test_clob
    require "#{srcdir}/test_dbi_clob"
  end
end

suite = RUNIT::TestSuite.new
ObjectSpace.each_object(Class) { |klass|
  if klass.ancestors.include?(RUNIT::TestCase)
    suite.add_test(klass.suite)
  end
}
#RUNIT::CUI::TestRunner.quiet_mode = true
RUNIT::CUI::TestRunner.run(suite)
