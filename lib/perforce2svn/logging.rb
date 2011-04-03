require 'log4r'

module Perforce2Svn
  # A convenient module for mixins that allow to
  # share the logging configuration everywhere
  # easily
  module Logging
    @@log = nil

    def self.configure(debug)
      if @@log.nil?
        @@log = Log4r::Logger.new 'perforce2svn'
        @@log.outputters = Log4r::Outputter.stdout
        @@log.level = if ENV['RSPEC_RUNNING']
                        Log4r::FATAL
                      elsif debug
                        Log4r::DEBUG
                      else
                        Log4r::INFO
                      end
        Log4r::Outputter.stdout.formatter = Log4r::PatternFormatter.new(:pattern => "[%l]\t%M")
      end
      @@log
    end
    
    def self.log
      @@log ||= configure(true)
    end
    
    # Meant for mixing into other classes for simplified logging
    def log
      @@log ||= Logging.log
    end
  end
end
