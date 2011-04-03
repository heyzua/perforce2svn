# Perforce2Svn Migration Tool

This tool is designed to help you with relatively sophisticated migrations from a Perforce server into Subversion.  The Subversion repository must be on the file system for this command to function correctly.  If a repository does not exist, one will be created.

## Prerequisites && Installation

This gem has only been tested on Ubuntu, though it should work on any Linux/Unix derivative with the correct binary libraries. It has only been tested on 1.8.7, though it should work on 1.8.6; it most certainly does not work at all under 1.9, particularly since the binary libraries are build against 1.8.

Sidenote: if you do run Ubuntu (or Debian), please do yourself a favor and install the latest from rubygems.org. Gem packaging and maintenance on Debian is complete crap and should not be trusted.

For this gem to function correctly, you will need to install certain tools on your own.  You will need at least:

- <code>svnadmin</code>: Required for cleaning up stale transactions if you Ctrl-C during a migration.
- <code>p4</code>: The Perforce command line utility should be installed. You will need to log in with it (or p4v) before you can do any migration.

In addition to these console tools, you will need to install some gems on your own. First, the <code>p4ruby (>= 1.0.9)</code> gem is required. I would list it as a dependency in the gemspec, but I have yet to have it succesfully install itself on its own. You should try the following:

    gem install p4ruby
    # ... Watch it fail, record the FTP url so that you can go to the 10.2 sources
    cd ${GEM_HOME}/gems/p4ruby-1.0.9/
    ruby install.rb --version 10.2 --platform ${YOUR_PLATFORM_HERE}

Additionally, you will need to install the Subversion bindings for Ruby. These should install their code under RUBY_HOME. On Ubuntu, you can run:

   apt-get install libsvn-ruby

I'm sure there are other binary packages out there for other platforms.

At this point, you can now install the main gem:

    gem install perforce2svn

This installs the <code>perforce2svn</code> command line client onto your path.

## Usage

The <code>perforce2svn</code> tool requires a mapping file that describes the migration activities that should occur. The general outline of a mapping file should look something like this:

    # This is a comment. 
    migrate //depot/from/perforce/path   /to/svn/trunk
    migrate //depot/another/path         /to/svn/trunk/subdir

    # Post-migration actions can also occur:
    copy    /svn/path/in/tree   /to/another/path
    move    /same/as/copy       /but/gets/rid/of/old/path
    delete  /deletes/svn/file

    # You can even add files at the end of a migration
    update  /live/file/in/tree.txt

The mapping file is fairly utilitarian, so you should feel free take what you need and leave the rest. There is a much more detailed discussion of the format of the mapping file and how to use it if you run <code>perforce2svn --mapping-file</code>.

The only quirky bit is the use of the <code>--live-path</code> flag, which points at the base directory of some directory structure that you want to use in your mapping file. In particularly large and complicated migrations and refactorings, this can be useful to update post-migration files so that any fixes that need to be immediately applied can be. This can be a bit of a time-saver if you have to manually test and re-test the migration operation several times to be absolutely sure that the code is in a usable state after the migration.

Running <code>perforce2svn --help</code> should give you most of the details that may be missing here.

## Hacking

This tool is not the most refined. It doesn't handle branches and merges, really at all. It's probably better than the Perl tool (since you can see what's actually happenning), but it can still be a bit difficult to maintain full backward history.

If you want to add that functionality and take this project from me, go for it! I created an older version of this tool some time ago, and it should really be extended by somebody with more insight into Perforce's internals than myself. There are at least a few tests to see what you can do, and several of the tricky parts of the SVN API have been carefully masked for most operations.

In fact, you could take some of the work here and create other Perforce migration clients, since you can pull out file contents fairly easily.

May the Source be With You.

