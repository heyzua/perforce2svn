require 'perforce2svn/errors'
require 'perforce2svn/mapping/operation'

module Perforce2Svn::Mapping
  class BranchMapping < Operation
    attr_reader :p4_path, :svn_path

    def initialize(tok, p4_path, svn_path)
      super(tok)
      @p4_path = p4_path
      @svn_path = svn_path
      @path_match = /^#{@p4_path}/
    end

    def p4_dotted
      @p4_path + '...'
    end

    def matches_perforce_path?(other_p4_path)
      (other_p4_path =~ @path_match) != nil
    end

    def to_svn_path(other_p4_path)
      opath = other_p4_path.gsub(p4_path, svn_path)
      opath.gsub!("%40", "@")
      opath.gsub!("%23", "#")
      opath.gsub!("%2a", "*")
      opath.gsub!("%25", "%")
      opath
    end
  end
end
