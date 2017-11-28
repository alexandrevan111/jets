require "spec_helper"

describe Jets::Commands::Base do
  let(:null) { double(:null).as_null_object }
  let(:command) do
    command = Jets::Commands::Base.new(given_args)
    allow(command).to receive(:shell).and_return(null)
    command
  end

  context Jets::Commands::Base do
    it "namespaced_commands" do
      commands = Jets::Commands::Base.namespaced_commands
      expect(commands).to include "build"
      expect(commands).to include "call"
      expect(commands).to include "routes"
      expect(commands).to include "dynamodb:generate"
      expect(commands).to include "dynamodb:migrate:down"
      expect(commands).to include "process:controller"
    end

    it "klass_from_namespace" do
      klass = Jets::Commands::Base.klass_from_namespace("dynamodb")
      expect(klass).to be Jets::Commands::Dynamodb

      klass = Jets::Commands::Base.klass_from_namespace(nil)
      expect(klass).to be Jets::Commands::Main
    end

    it "autocomplete" do
      full_command = Jets::Commands::Base.autocomplete("ser")
      puts "full_command #{full_command.inspect}"
      expect(full_command).to eq "server"
    end
  end
end
