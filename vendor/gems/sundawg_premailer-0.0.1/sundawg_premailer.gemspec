# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{sundawg_premailer}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Christopher Sun"]
  s.date = %q{2010-09-11}
  s.description = %q{Fork of premailer project to accomodate in memory HTML (http://premailer.dialect.ca/).}
  s.email = %q{christopher.sun@gmail.com}
  s.executables = ["premailer", "trollop.rb"]
  s.extra_rdoc_files = ["CHANGELOG.rdoc", "LICENSE.rdoc", "README.rdoc", "bin/premailer", "bin/trollop.rb", "lib/premailer.rb", "lib/premailer/html_to_plain_text.rb", "lib/premailer/premailer.rb"]
  s.files = ["CHANGELOG.rdoc", "LICENSE.rdoc", "README.rdoc", "Rakefile", "bin/premailer", "bin/trollop.rb", "init.rb", "lib/premailer.rb", "lib/premailer/html_to_plain_text.rb", "lib/premailer/premailer.rb", "misc/client_support.yaml", "premailer.gemspec", "tests/files/base.html", "tests/files/contact_bg.png", "tests/files/dialect.png", "tests/files/dots_end.png", "tests/files/dots_h.gif", "tests/files/import.css", "tests/files/inc/2009-placeholder.png", "tests/files/noimport.css", "tests/files/styles.css", "tests/test_helper.rb", "tests/test_html_to_plain_text.rb", "tests/test_link_resolver.rb", "tests/test_premailer.rb", "Manifest", "sundawg_premailer.gemspec"]
  s.homepage = %q{http://github.com/SunDawg/premailer}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Sundawg_premailer", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{sundawg_premailer}
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Fork of premailer project to accomodate in memory HTML (http://premailer.dialect.ca/).}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<hpricot>, [">= 0.6"])
      s.add_runtime_dependency(%q<css_parser>, [">= 1.0.0"])
      s.add_runtime_dependency(%q<text-reform>, [">= 0.2.0"])
      s.add_runtime_dependency(%q<htmlentities>, [">= 4.0.0"])
    else
      s.add_dependency(%q<hpricot>, [">= 0.6"])
      s.add_dependency(%q<css_parser>, [">= 1.0.0"])
      s.add_dependency(%q<text-reform>, [">= 0.2.0"])
      s.add_dependency(%q<htmlentities>, [">= 4.0.0"])
    end
  else
    s.add_dependency(%q<hpricot>, [">= 0.6"])
    s.add_dependency(%q<css_parser>, [">= 1.0.0"])
    s.add_dependency(%q<text-reform>, [">= 0.2.0"])
    s.add_dependency(%q<htmlentities>, [">= 4.0.0"])
  end
end
