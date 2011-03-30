use inc::Module::Install;


name 'Ridge';
all_from 'lib/Ridge.pm';

requires 'CGI';
requires 'CLASS';
requires 'Carp';
requires 'Class::Accessor::Fast';
requires 'Class::Accessor::Lvalue::Fast';
requires 'Class::Component::Plugin';
requires 'Class::Data::Inheritable';
requires 'Class::Inspector';
requires 'Class::Singleton';
requires 'Encode::JavaScript::UCS';
requires 'Exception::Class';
requires 'Exporter::Lite';
requires 'File::Modified';
requires 'File::Slurp';
requires 'FormValidator::Simple';
requires 'HTTP::Request';
requires 'HTTP::Request::AsCGI';
requires 'HTTP::Response';
requires 'HTTP::BrowserDetect';
requires 'JSON::Syck';
requires 'List::MoreUtils';
requires 'Module::Pluggable';
requires 'Module::Refresh';
requires 'Parse::RecDescent';
requires 'Path::Class';
requires 'Pod::Usage';
requires 'Template';
requires 'UNIVERSAL::require';
requires 'URI';
requires 'Log::Dispatch::Config';
requires 'Log::Dispatch::Configurator::YAML';
requires 'Template::Stash::ForceUTF8';
requires 'Plack';
requires 'Plack::Middleware::ReverseProxy';

recommends 'Locale::Maketext::Simple';
recommends 'Locale::Maketext::Lexicon';
recommends 'Geo::IP::PurePerl';
recommends 'IP::Country::Fast';
recommends 'MIME::Lite::TT::Japanese';
recommends 'DateTime';
recommends 'DateTime::Format::Mail';
recommends 'DateTime::TimeZone';
recommends 'List::Util';

build_requires 'File::Spec';
build_requires 'FindBin::libs';
build_requires 'Net::Ping';
build_requires 'Scalar::Util';
build_requires 'Test::Base';
build_requires 'Test::Class';
build_requires 'Test::HTTP';
build_requires 'Test::More';
build_requires 'Test::Singleton';
build_requires 'Time::HiRes';

install_script 'bin/ridge.pl';

auto_install;
WriteAll;
