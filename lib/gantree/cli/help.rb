module Gantree
  class CLI < Thor
    class Help
      class << self
        def hello(action)
<<-EOL
Adds a remote named <name> for the repository at <url>. The command git fetch <name> can then be used to create and update
EOL
        end
      end
    end
  end
end