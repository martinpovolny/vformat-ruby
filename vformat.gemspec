spec = Gem::Specification.new do |s|
  s.name        = 'vformat'
  s.version     = '1.13.1'
  s.summary     = 'VFormat: vcard, vevent, vtodo, ... processing'
  s.description = %{
VFormat is a library for processing of data formated according to RFC2425 and it’s modifications.

At the moments these formats are implemented:

  * rfc2425 (www.ietf.org/rfc/rfc2425.txt)
  * vCard 2.1 (www.imc.org/pdi/pdiproddev.html)
  * vCard 3.0 (www.ietf.org/rfc/rfc2426.txt)
  * vCalendar 1.0 (www.imc.org/pdi/pdiproddev.html)
  * iCalendar 2.0 (www.ietf.org/rfc/rfc2445.txt)
}
  s.files               = Dir['lib/**/*.rb'] #+ Dir['test/**/*.rb']
  s.require_path        = 'lib'
  s.has_rdoc            = true
  s.rdoc_options        << '--title' << 'VFormat -- vcard, vevent, vtodo, ...'
  s.author              = 'Martin Povolny'
  s.email               = 'martin.povolny@gmail.com'
  s.homepage            = 'https://github.com/martinpovolny/vformat-ruby'
end
