# frozen_string_literal: true
module Travis
  module Logs
    module Services
      class FetchLogParts
        def initialize(database: nil)
          @database = database || Travis::Logs.database_connection
        end

        attr_reader :database
        private :database

        def run(log_id: nil, job_id: nil, after: nil, part_numbers: [])
          log_id = database.log_id_for_job_id(job_id) if log_id.nil?
          return nil if log_id.nil?
          database.log_parts(log_id, after: after, part_numbers: part_numbers)
        end
      end
    end
  end
end