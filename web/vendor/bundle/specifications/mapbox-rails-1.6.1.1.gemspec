# -*- encoding: utf-8 -*-
# stub: mapbox-rails 1.6.1.1 ruby lib vendor

Gem::Specification.new do |s|
  s.name = "mapbox-rails"
  s.version = "1.6.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib", "vendor"]
  s.authors = ["Mark Madsen"]
  s.date = "2014-02-28"
  s.description = "Integrate MapBox.js with the Rails asset pipeline"
  s.email = ["growl@agileanimal.com"]
  s.homepage = "https://github.com/aai/mapbox-rails"
  s.licenses = ["BSD and MIT"]
  s.rubygems_version = "2.2.2"
  s.summary = "Integrate MapBox.js with the Rails asset pipeline"

  s.installed_by_version = "2.2.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>, ["~> 1.3"])
      s.add_development_dependency(%q<rake>, [">= 0"])
    else
      s.add_dependency(%q<bundler>, ["~> 1.3"])
      s.add_dependency(%q<rake>, [">= 0"])
    end
  else
    s.add_dependency(%q<bundler>, ["~> 1.3"])
    s.add_dependency(%q<rake>, [">= 0"])
  end
end
