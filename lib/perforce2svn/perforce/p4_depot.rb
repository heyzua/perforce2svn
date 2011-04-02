require 'perforce2svn/logging'
require 'perforce2svn/errors'
require 'P4'
require 'singleton'

module Perforce2Svn::Perforce
  class P4Depot
    include Singleton
    include Perforce2Svn::Logging

    def initialize
      @p4 = P4.new
    end

    def connect!
      handle_errors do
        @p4.connect unless @p4.connected?
      end
    end

    def disconnect!
      begin
        @p4.disconnect if @p4.connected?
      rescue Exception => e
        log.fatal(e)
        exit 1
      end
    end

    def query(&block)
      raise Perforce2Svn::P4Error, "Requires a block" unless block_given?
      connect!
      handle_errors do
        yield @p4
      end
    end

    # Retrieves the latest revision on the Perforce server
    def latest_revision
      if @latest_revision.nil?
        query do |p4|
          log.debug "Retrieving latest perforce revision"
          output = p4.run("changes", "-m1")[0]
          @latest_revision = output['change'].to_i
        end
      end
      @latest_revision
    end

    private
    def handle_errors(&block)
      begin
        yield
      rescue P4Exception => e
        @p4.warnings.each do |warning|
          log.debug "PERFORCE: Skipping warning: #{warning}"
        end
        if @p4.errors.length > 0
          log.error e
          @p4.errors.each do |error|
            log.error "PERFORCE: #{error}"
          end
          log.fatal "PERFORCE: Are you currently logged into the Perforce server? "
          raise Perforce2Svn::P4Error, "Error while interacting with the Perforce server"
        end
      end
    end
  end # P4Depot
end
