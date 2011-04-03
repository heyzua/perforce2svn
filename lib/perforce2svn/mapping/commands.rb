require 'perforce2svn/mapping/operation'

module Perforce2Svn::Mapping
  class Command < Operation
    # Must be implemented by subclasses
    def execute!(svn_txn)
      raise Exception, "Not implemented"
    end
  end

  class Copy < Command
    attr_reader :svn_from, :svn_to
    def initialize(tok,svn_from, svn_to)
      super(tok)
      @svn_from = svn_from
      @svn_to = svn_to
    end

    def execute!(svn_txn)
      svn_txn.copy(@svn_from, @svn_to)
    end
  end

  class Mkdir < Command
    attr_reader :svn_path
    def initialize(tok, svn_path)
      super(tok)
      @svn_path = svn_path
    end

    def execute!(svn_txn)
      svn_txn.mkdir(@svn_path)
    end
  end

  class Move < Command
    attr_reader :svn_from, :svn_to
    def initialize(tok, svn_from, svn_to)
      super(tok)
      @svn_from = svn_from
      @svn_to = svn_to
    end

    def execute!(svn_txn)
      svn_txn.move(@svn_from, @svn_to)
    end
  end

  class Update < Command
    attr_reader :svn_path, :live_path
    def initialize(tok, svn_path, live_path)
      super(tok)
      @svn_path = svn_path
      @live_path = live_path
    end

    def execute!(svn_txn)
      File.open(@live_path, 'r') do |fstream|
        svn_txn.update(@svn_path, fstream)
      end
    end
  end

  class Delete < Command
    attr_reader :svn_path
    def initialize(tok, svn_path)
      super(tok)
      @svn_path = svn_path
    end

    def execute!(svn_txn)
      svn_txn.delete(@svn_path)
    end
  end
end
