use inc::Module::Install;


name 'Ridge';
all_from 'lib/Ridge.pm';

requires 'CGI';
requires 'CLASS';
requires 'Cache::Memcached';
requires 'Carp';
requires 'Class::Accessor::Fast';
requires 'Class::Accessor::Lvalue::Fast';
requires 'Class::Component';
requires 'Class::Data::Inheritable';
requires 'Class::Inspector';
requires 'Class::Singleton';
requires 'Class::Trigger';
requires 'DateTime';
requires 'DateTime::TimeZone';
requires 'Encode::JavaScript::UCS';
requires 'Exception::Class';
requires 'Exporter::Lite';
requires 'File::Modified';
requires 'File::Slurp';
requires 'File::Spec';
requires 'FindBin::libs';
requires 'FormValidator::Simple';
requires 'HTTP::BrowserDetect';
requires 'HTTP::MobileAgent';
requires 'HTTP::Request';
requires 'HTTP::Request::AsCGI';
requires 'HTTP::Response';
requires 'IO::Prompt';
requires 'JSON::Syck';
requires 'List::MoreUtils';
requires 'Log::Dispatch';
requires 'Log::Dispatch::Config';
requires 'Log::Dispatch::Configurator::YAML';
requires 'Module::Pluggable';
requires 'Params::Validate';
requires 'Parse::RecDescent';
requires 'Path::Class';
requires 'Plack';
requires 'Plack::Middleware::Debug';
requires 'Plack::Middleware::ReverseProxy';
requires 'Pod::Usage';
requires 'Scalar::Util';
requires 'Template';
requires 'Template::Provider::Encoding';
requires 'Template::Stash::ForceUTF8';
requires 'Time::HiRes';
requires 'UNIVERSAL::require';
requires 'URI';
requires 'YAML::Syck';

recommends 'DateTime::Format::Mail';
recommends 'Geo::IP::PurePerl';
recommends 'IP::Country::Fast';
recommends 'List::Util';
recommends 'MIME::Lite::TT::Japanese';
recommends 'Plack::Middleware::Refresh';
recommends 'Plack::Middleware::ServerStatus::Lite';

recommends 'Coro';
recommends 'Coro::Event';
recommends 'Coro::LWP';
recommends 'LWP::Protocol::https';
recommends 'LWP::UserAgent';

build_requires 'IO::String';
build_requires 'Test::Base';
build_requires 'Test::Class';
build_requires 'Test::More';
build_requires 'Test::Most';
build_requires 'Test::Singleton';

install_script 'bin/ridge.pl';

auto_install;
WriteAll;
