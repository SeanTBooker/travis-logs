# frozen_string_literal: true

describe 'aggregation' do
  def db
    Travis::Logs.database_connection.db
  end

  def lorem_ipsum_words
    @lorem_ipsum_words ||= File.read(
      File.expand_path('../../lorem_ipsum', __FILE__)
    ).split
  end

  def word_salad(n = 100)
    s = ''
    n.times { s += "#{lorem_ipsum_words.sample} " }
    s + "\n"
  end

  def create_payload(job_id, n)
    {
      'id' => job_id,
      'number' => n,
      'log' => word_salad(10 * (job_id % (n + 1)))
    }
  end

  def populate_logs(job_count: 10, parts_count: 50)
    lps = Travis::Logs::LogPartsWriter.new

    job_count.times do |n|
      job_id = 17_321 + n

      entries = []
      parts_count.times do |log_part_n|
        entries.push(create_payload(job_id, log_part_n))
      end

      entries.push(
        create_payload(job_id, parts_count + 1).merge('final' => true)
      )

      lps.run(entries)
    end
  end

  before do
    Travis::Logs.database_connection = Travis::Logs::Database.connect
    Travis.config.logs.intervals[:sweeper] = 0
    db.run('TRUNCATE log_parts; TRUNCATE logs')
    populate_logs
  end

  it 'aggregates logs' do
    expect(db[:log_parts].count).to be > 0
    2.times { Travis::Logs::Services::AggregateLogs.run }
    expect(db[:log_parts].count).to eql(0)
  end
end
