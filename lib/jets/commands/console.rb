class Jets::Commands::Console
  def self.run
    $stderr.puts Jets.boot_message

    # Thanks: https://mutelight.org/bin-console
    require "irb"
    require "irb/completion"

    ARGV.clear # https://stackoverflow.com/questions/33070092/irb-start-not-starting/33136762
    IRB.start
  end
end
