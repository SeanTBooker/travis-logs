require 'travis/logs'
require 'travis/support'
require 'travis/support/database'
require 'travis/support/amqp'
require 'travis/support/exceptions/reporter'
require 'travis/support/log_subscriber/active_record_metrics'
require 'travis/support/memory'
require 'travis/logs/receive/queue'
require 'travis/logs/services/process_log_part'
require 'metriks'
require 'metriks/reporter/logger'
require 'active_support/core_ext/logger'

$stdout.sync = true

module Travis
  module Logs
    class Receive
      def setup
        Travis.logger.info('** Starting Log Parts Processor **')
        Travis::Amqp.config = Travis::Logs.config.amqp
        Travis::Database.connect
        Travis::Exceptions::Reporter.start
        Travis::LogSubscriber::ActiveRecordMetrics.attach
        Metriks::Reporter::Logger.new.start
        Travis::Memory.new(:logs).report_periodically if Travis.env == 'production'
      end

      def run
        1.upto(Logs.config.logs.threads) do
          Queue.subscribe('logs', &method(:receive))
        end
      end

      def receive(payload)
        Travis::Logs::Services::ProcessLogPart.run(payload)
      end
    end
  end
end
