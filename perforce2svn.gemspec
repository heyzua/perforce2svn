Gem::Specification.new do |gem|
  gem.name        = "perforce2svn"
  gem.version     = begin
                      require 'choosy/version'
                      Choosy::Version.load_from_lib.to_s
                    rescue Exception
                      '0'
                    end
  gem.executables  = %W{perforce2svn}
  gem.platform    = Gem::Platform::RUBY
  gem.authors     = ["Gabe McArthur"]
  gem.email       = ["madeonamac@gmail.com"]
  gem.homepage    = "http://github.com/gabemc/perforce2svn"
  gem.summary     = "Converts a Perforce repository into a Subversion repository"
  gem.description = "It loads each revision in a Perforce repository sequentially and commits each change into an exist or new or existing Subversion repository.  It also handles more complicated operations that may occur after a migration, like adding, deleting, copy, or updating files to make the entire migration functional."
   
  gem.required_rubygems_version = ">= 1.3.6"

  gem.add_dependency 'log4r',     '>= 1.1.7'
  gem.add_dependency 'choosy',    '>= 0.4.8'
#  gem.add_dependency 'p4ruby',    '>= 1.0.9'
  gem.post_install_message =<<EOF
Please be sure to install the p4ruby gem (>= 1.0.9).
The gem currently doesn't seem to build without
manual intervention. For instance, I had to run:

  ruby install.rb --version 10.2 --platform linux26x86

Your supported platform may vary.

Additionally, you will need to install the subversion
bindings that come with your platform. On Ubuntu, for
instance, you can run:

  apt-get install libsvn-ruby

The runtime will check that both of these are installed
before proceeding.
EOF

  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'mocha'
  gem.add_development_dependency 'autotest'
  gem.add_development_dependency 'autotest-notification'
  gem.add_development_dependency 'ZenTest'

  gem.files        = Dir.glob("**/*")
  gem.require_path = 'lib'
end
