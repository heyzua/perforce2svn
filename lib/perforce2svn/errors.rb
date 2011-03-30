
module Perforce2Svn
  Error = Class.new(RuntimeError)

  # Configuration
  ConfigurationError = Class.new(Perforce2Svn::Error)

  # Subversion errors
  SvnPathNotFoundError = Class.new(Perforce2Svn::Error)
  SvnNoSuchRevisionError = Class.new(Perforce2Svn::Error)
  SvnTransactionError = Class.new(Perforce2Svn::Error)

  # Perforce
  P4Error = Class.new(Perforce2Svn::Error)

  # Mappings
  MappingParserError = Class.new(Perforce2Svn::Error)
end
