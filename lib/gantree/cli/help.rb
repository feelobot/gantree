module Gantree
  class CLI < Thor
    class Help
      class << self
        def init
<<-EOL
Examples:

$ gantree init -u USERNAME -p PORT HANDLE/REPO:TAG

$ gantree init -u frodriguez -p 3000 bleacher/cauldron:master
EOL
        end

        def deploy
<<-EOL
Examples:

$ gantree deploy -t TAG ENVIRONMENT

$ gantree deploy -t latest stag-cauldon-app-s1

# to deploy to all environments to within the same application

$ gantree deploy -t TAG APPLICATION

$ gantree deploy -t TAG stag-cauldron-s1

# add ebextensions

$ gantree deploy -t TAG stag-cauldron-s1 -x "git@github.com:br/.ebextensions.git:master"

EOL
        end

        def create
<<-EOL
Examples:

$ gantree create APPLICATION

$ gantree create linguist-stag-s1

$ gantree create APPLICATION -e ENVIRONMENT

$ gantree create linguist-stag-s1 -e linguist-stag-app-s1

$ gantree create --dupe=rails-stag-s1 rails-stag-s3 
EOL
        end

        def update
<<-EOL
Examples:

$ gantree update linguist-stag-s1
EOL
        end

        def build
<<-EOL
Builds and tags a docker application.

Examples:

$ gantree build -i bleacher/rails:built

$ gantree build -t deploy
EOL
        end

        def push
<<-EOL
Pushs docker image tag to hub

Examples:

$ gantree push bleacher/cms:deploy
EOL
        end

        def ship
<<-EOL
build, push and deploy docker image to elastic beanstalk

Examples:

$ gantree ship -t TAG stag-cauldron-s1 -x "git@github.com:br/.ebextensions.git:master"
EOL
        end

        def restart
<<-EOL
Restart docker environment

Examples:

$ gantree restart stag-rails-app-s1
EOL
        end
      end
    end
  end
end