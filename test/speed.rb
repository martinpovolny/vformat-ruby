#!/usr/bin/ruby -w
#
#  Copyright (c) 2007 Jan Becvar <jan.becvar@solnet.cz>
#  Copyright (c) 2007 soLNet, s.r.o. 
#
#  License: GPL
#

$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'vformat/icalendar'
require 'benchmark'

NUM = 500

ical = VFormat['VCALENDAR'].new do |c|
    c.VEVENT do |e|
        e.DTSTART  '20060706T120000Z'
        e.DTEND    '20060706T220000Z'
        e.SUMMARY  'Meeting+èΔΦüΔèåäæàÇΓñööøòßΠΠΣvzå@mjogmdwgmtjdmgdnemjPDpmpmtdpwmgN.m'
        e.LOCATION 'ΔéèΔΦèéèΔåäΓ22gjptjgtjbjat+vj0tmj+t+tΘp0twuptxt+gu'
        e.add('X-AALARM', '20060706T120000Z')
        e.add 'LAST-MODIFIED', '20060705T160008Z'
        e.add 'X-IRMC-LUID',   '000000000017'
    end
end
str = ical.encode

vcal = VFormat['VCALENDAR', '1.0'].new do |c|
    c.VEVENT do |e|
        e.DTSTART  '20060706T120000Z'
        e.DTEND    '20060706T220000Z'
        e.SUMMARY  'Meeting+èΔΦüΔèåäæàÇΓñööøòßΠΠΣvzå@mjogmdwgmtjdmgdnemjPDpmpmtdpwmgN.m'
        e.LOCATION 'ΔéèΔΦèéèΔåäΓ22gjptjgtjbjat+vj0tmj+t+tΘp0twuptxt+gu'
        e.AALARM   '20060706T120000Z'
        e.add 'LAST-MODIFIED', '20060705T160008Z'
        e.add 'X-IRMC-LUID',   '000000000017'
    end
end
str_vcal = vcal.encode

Benchmark.bmbm do |x|
    x.report("#{NUM}x encode_only ical") { NUM.times { ical.encode } }
    x.report("#{NUM}x encode_only vcal") { NUM.times { vcal.encode } }
    x.report("#{NUM}x encode ical") do
        NUM.times do 
            VFormat['VCALENDAR'].new do |c|
                c.VEVENT do |e|
                    e.DTSTART  '20060706T120000Z'
                    e.DTEND    '20060706T220000Z'
                    e.SUMMARY  'Meeting+èΔΦüΔèåäæàÇΓñööøòßΠΠΣvzå@mjogmdwgmtjdmgdnemjPDpmpmtdpwmgN.m'
                    e.LOCATION 'ΔéèΔΦèéèΔåäΓ22gjptjgtjbjat+vj0tmj+t+tΘp0twuptxt+gu'
                    e.add('X-AALARM', '20060706T120000Z')
                    e.add 'LAST-MODIFIED', '20060705T160008Z'
                    e.add 'X-IRMC-LUID',   '000000000017'
                end
            end.encode
        end 
    end
    x.report("#{NUM}x encode vcal") do
        NUM.times do 
            VFormat['VCALENDAR', '1.0'].new do |c|
                c.VEVENT do |e|
                    e.DTSTART  '20060706T120000Z'
                    e.DTEND    '20060706T220000Z'
                    e.SUMMARY  'Meeting+èΔΦüΔèåäæàÇΓñööøòßΠΠΣvzå@mjogmdwgmtjdmgdnemjPDpmpmtdpwmgN.m'
                    e.LOCATION 'ΔéèΔΦèéèΔåäΓ22gjptjgtjbjat+vj0tmj+t+tΘp0twuptxt+gu'
                    e.AALARM   '20060706T120000Z'
                    e.add 'LAST-MODIFIED', '20060705T160008Z'
                    e.add 'X-IRMC-LUID',   '000000000017'
                end
            end.encode
        end
    end
    x.report("#{NUM}x decode_raw ical") { NUM.times { VFormat.decode_raw(str) } }
    x.report("#{NUM}x decode_raw vcal") { NUM.times { VFormat.decode_raw(str_vcal) } }
    x.report("#{NUM}x decode ical") { NUM.times { VFormat.decode(str) } }
    x.report("#{NUM}x decode vcal") { NUM.times { VFormat.decode(str_vcal) } }
    x.report("#{NUM}x convert ical->vcal") { NUM.times { ical.to_version('1.0') } }
    x.report("#{NUM}x convert vcal->ical") { NUM.times { vcal.to_version('2.0') } }
end

