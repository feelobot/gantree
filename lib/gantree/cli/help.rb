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

$ gantree deploy -t TAG cauldron-stag-s1

# add remote .ebextensions

$ gantree deploy -t TAG stag-cauldron-s1 -x "git@github.com:br/.ebextensions.git"

# add remote .ebextensions branch

$ gantree deploy -t TAG stag-cauldron-s1 -x "git@github.com:br/.ebextensions:feature_branch"

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

# Update a cloudformation stack

$ gantree update linguist-stag-s1

# Add an app role to an existing stack

$ gantree update linguist-stag-s1 -r worker

# Update docker solution starck version

$ gantree update linguist-stag-s1 -s latest

$ gantree update linguist-stag-s1 -s "64bit Amazon Linux 2014.09 v1.0.11 running Docker 1.3.3"
EOL
        end

        def build
<<-EOL
Builds and tags a docker application.

Examples:

# Automatically tag a build

$ gantree build

# Add custom tag to a build 

$ gantree build -t deploy 

# Override image path to point to another hub

$ gantree build -i quay.io/bleacherreport/cms

EOL
        end

        def push
<<-EOL
Push docker image tag to hub

Examples:

# Push automatically tagged build

$ gantree push

# Push custom tagged build

$ gantree push -t deploy 

# Push to another hub/acocunt/repo

$ gantree push -i quay.io/bleacherreport/cms
EOL
        end

        def ship
<<-EOL
build, push and deploy docker image to elastic beanstalk

Examples:

# Automatically tag a build, push that build and deploy to elastic beanstalk

$ gantree ship cms-stag-s1

# Override defaults

$ gantree ship -i bleacher/cms -x "git@github.com:br/.ebextensions.git:master" cms-stag-s1

$ gantree ship -i bleacher/cms -t built -x "git@github.com:br/.ebextensions.git:master" cms-stag-s1
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