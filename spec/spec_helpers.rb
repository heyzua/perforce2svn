require 'stringio'
require 'time'

ENV['RSPEC_RUNNING'] = 'true'

def attempting(&block)
  lambda &block
end

def attempting_to(&block)
  lambda &block
end

class StringIO
  def readpartial(len)
    read(len)
  end
end

module CommitHelper
  def write(path, text, binary = false)
    @repo.transaction('gabe', Time.now, "Committing to : #{path}") do |txn|
      contents = StringIO.new(text)
      txn.update(path, contents, binary)
    end
  end
  def delete(path)
    @repo.transaction('gabe', Time.now, "Deleting: #{path}") do |txn|
      txn.delete(path)
    end
  end
  def symlink(src, dest)
    @repo.transaction('gabe', Time.now, "Symlinking: #{src} to #{dest}") do |txn|
      txn.symlink(src, dest)
    end
  end
  def read_in(local_path, mode = nil)
    mode ||= 'r'
    f = open(local_path, mode)
    contents = f.read
    f.close
    contents
  end
end
