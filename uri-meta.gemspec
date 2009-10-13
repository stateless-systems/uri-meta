# Generated by jeweler
# DO NOT EDIT THIS FILE
# Instead, edit Jeweler::Tasks in Rakefile, and run `rake gemspec`
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{uri-meta}
  s.version = "0.9.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Stateless Systems"]
  s.date = %q{2009-10-13}
  s.description = %q{Retrieves meta information for a URI from the meturi.com service.}
  s.email = %q{production@statelesssystems.com}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.markdown"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "LICENSE",
     "README.markdown",
     "Rakefile",
     "VERSION",
     "benchmark.rb",
     "lib/uri/meta.rb",
     "test/test_helper.rb",
     "test/uri-meta_test.rb",
     "uri-meta.gemspec"
  ]
  s.homepage = %q{http://github.com/stateless-systems/uri-meta}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Meta information for a URI}
  s.test_files = [
    "test/test_helper.rb",
     "test/uri-meta_test.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<taf2-curb>, [">= 0"])
      s.add_runtime_dependency(%q<wycats-moneta>, [">= 0"])
      s.add_development_dependency(%q<thoughtbot-shoulda>, [">= 0"])
    else
      s.add_dependency(%q<taf2-curb>, [">= 0"])
      s.add_dependency(%q<wycats-moneta>, [">= 0"])
      s.add_dependency(%q<thoughtbot-shoulda>, [">= 0"])
    end
  else
    s.add_dependency(%q<taf2-curb>, [">= 0"])
    s.add_dependency(%q<wycats-moneta>, [">= 0"])
    s.add_dependency(%q<thoughtbot-shoulda>, [">= 0"])
  end
end
