# Gantree

[![Build Status](https://travis-ci.org/feelobot/gantree.svg)](https://travis-ci.org/feelobot/gantree)
[![Test Coverage](https://codeclimate.com/github/feelobot/gantree/badges/coverage.svg)](https://codeclimate.com/github/feelobot/gantree)
[![Code Climate](https://codeclimate.com/github/feelobot/gantree/badges/gpa.svg)](https://codeclimate.com/github/feelobot/gantree)

## Description

This tool is intended to help you setup a Dockerrun.aws.json which allows you to deploy a prebuilt image of your application to Elastic Beanstalk. This also allows you to do versioned deploys to your Elastic Beanstalk application and create an archive of every versioned Dockerrun.aws.json in amazons s3 bucket service.

## Installation

You need to have your AWS_ACCES_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables set in order to use the tool as well as the proper aws permissions for Elastic Beanstalk, and S3 access. 

For the time being you also need to configure your github repo to auto build an image inside of Dockerhub (private or open). In order to do this you need to have a dockerhub account already, login, and select your profile/orginization to add a *Automated Build* to. Select the branch you want to build, location of the docker file and the tag to reference the image that will be built (this will hopefully be automated in the future via dockerhub api).

Once you have your docker image created you will also need to install docker (if you haven't already)

*MAC OSX*
```
brew install docker
```

Generate your login credentials token:
```
docker login
```

Install the gem
```
gem install 'gantree'
```

### Initialize (not yet created)

What this does is create a new Dockerrun.aws.json inside your repository and uploads your docker login credentials to s3 (for private repo access) so you can do deploys. We need the -u to specify a username to rename your .dockercfg and reference it in the Dockerrun.aws.json

```
gantree init -u frodriguez bleacher/cauldron
```


### Deploy

This command renames your Dockerrun.aws.json temporarily to NAME_OF_ENV-GITHUB_HASH-Dockerrun.aws.json, uploads it to a NAME_OF_APP-versions bucket, creates a new elastic beanstalk version, and asks the specified elastic beanstalk environment to update to that new version.

```
gantree deploy stag-cauldron-app-s1
```

You can also specify a new image tag to use for the deploy

```
gantree deploy -t latest stag-cauldon-app-s1
```
