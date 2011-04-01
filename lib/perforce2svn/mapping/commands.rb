
module Perforce2Svn::Mapping
  class Command
    attr_reader :line_number
    def initialize(tok)
      @line_number = tok.line
    end
  end

  class Add < Command
    attr_reader :svn_path, :live_path
    def initialize(tok, svn_path, live_path)
      super(tok)
      @svn_path = svn_path
      @live_path = live_path
    end
  end

  class Copy < Command
    attr_reader :svn_from, :svn_to
    def initialize(tok,svn_from, svn_to)
      super(tok)
      @svn_from = svn_from
      @svn_to = svn_to
    end
  end

  class Mkdir < Command
    attr_reader :svn_path
    def initialize(tok, svn_path)
      super(tok)
      @svn_path = svn_path
    end
  end

  class Move < Command
    attr_reader :svn_from, :svn_to
    def initialize(tok, svn_from, svn_to)
      super(tok)
      @svn_from = svn_from
      @svn_to = svn_to
    end
  end

  class Update < Command
    attr_reader :svn_path, :live_path
    def initialize(tok, svn_path, live_path)
      super(tok)
      @svn_path = svn_path
      @live_path = live_path
    end
  end

  class Remove < Command
    attr_reader :svn_path
    def initialize(tok, svn_path)
      super(tok)
      @svn_path = svn_path
    end
  end

  class BranchMapping < Command
    attr_reader :p4_path, :svn_path

    def initialize(tok, p4_path, svn_path)
      super(tok)
      @p4_path = p4_path
      @svn_path = svn_path
    end

    def p4_dotted
      @p4_path + '...'
    end

    def matches_perforce_path?(other_p4_path)
      (other_p4_path =~ /^#{p4_path}/) != nil
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
