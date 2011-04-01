# Perforce2Svn Migration Tool
This tool is designed to help you with relatively sophisticated migrations from a Perforce server into Subversion.  The Subvrsion repository must be on the file system for this command to function correctly.  If a repository does not exist, one will be created.

Currently, this software is incomplete and not yet functional.


Please be sure to install the p4ruby gem (>= 1.0.9).
The gem currently doesn't seem to build without
manual intervention. For instance, I had to run:

  ruby install.rb --version 10.2 --platform linux26x86

Your supported platform may vary.

Additionally, you will need to install the subversion
bindings that come with your platform. On Ubuntu, for
instance, you can run:

  apt-get install libsvn-ruby
