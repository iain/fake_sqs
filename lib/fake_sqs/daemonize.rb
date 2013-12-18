module FakeSQS
  class Daemonize

    attr_reader :pid

    def initialize(options)
      @pid = options.fetch(:pid) {
        warn "No PID file specified while daemonizing!"
        exit 1
      }
    end

    def call
      Process.daemon(true, true)

      if File.exist?(pid)
        existing_pid = File.open(pid, 'r').read.chomp.to_i
        running = Process.getpgid(existing_pid) rescue false
        if running
          warn "Error, Process #{existing_pid} already running"
          exit 1
        else
          warn "Cleaning up stale pid at #{pid}"
        end
      end
      File.open(pid, 'w') { |f| f.write(Process.pid) }
    end

  end
end
