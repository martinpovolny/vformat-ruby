#!/usr/bin/ruby -w
#
#  Copyright (c) 2007 Jan Becvar <jan.becvar@solnet.cz>
#  Copyright (c) 2007 soLNet, s.r.o. 
#
#  License: GPL
#

require 'test/unit'

Dir.foreach(File.dirname(__FILE__)) do |f|
    next unless f =~ /^test_.*\.rb$/

    require(File.join(File.dirname(__FILE__), f))
end

