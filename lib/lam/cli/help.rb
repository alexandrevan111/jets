module Lam
  class CLI < Command
    class Help
      class << self
        def build
<<-EOL
Builds and prepares project for AWS Lambda.  Generates a node shim and vendors Traveling Ruby.  Creates a zip file to be uploaded to Lambda for each handler.
EOL
        end

        def process
<<-EOL
TODO: update process help menu
EOL
        end
      end
    end
  end
end
