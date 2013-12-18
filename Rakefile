require "bundler/gem_tasks"

require "tempfile"
require 'rspec/core/rake_task'

namespace :spec do

  desc "Run only unit specs"
  RSpec::Core::RakeTask.new(:unit) do |t|
    t.pattern = "spec/unit"
  end

  desc "Run specs with in-memory database"
  RSpec::Core::RakeTask.new(:memory) do |t|
    ENV["SQS_DATABASE"] = ":memory:"
    t.pattern = "spec/acceptance"
  end

  desc "Run specs with file database"
  RSpec::Core::RakeTask.new(:file) do |t|
    file = Tempfile.new(["rspec-sqs", ".yml"], encoding: "utf-8")
    ENV["SQS_DATABASE"] = file.path
    t.pattern = "spec/acceptance"
  end

end

desc "Run spec suite with both in-memory and file"
task :spec => ["spec:unit", "spec:memory", "spec:file"]

task :default => :spec
