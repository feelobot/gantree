# Gantree

[![Build Status](https://travis-ci.org/feelobot/gantree.svg)](https://travis-ci.org/feelobot/gantree)
[![Test Coverage](https://codeclimate.com/github/feelobot/gantree/badges/coverage.svg)](https://codeclimate.com/github/feelobot/gantree)
[![Code Climate](https://codeclimate.com/github/feelobot/gantree/badges/gpa.svg)](https://codeclimate.com/github/feelobot/gantree)
## Why Gantree?

The name is derived from the word gantry which is a large crane used in ports to pick up shipping containers and load them on a ship. Gantry was already taken so I spelled it "tree" because the primary use is for elastic beanstalk and I guess a beanstalk is a form of tree? 

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
gem install gantree
```

### Initialize

What this does is create a new Dockerrun.aws.json inside your repository and uploads your docker login credentials to s3 (for private repo access) so you can do deploys. We need the -u to specify a username to rename your .dockercfg and reference it in the Dockerrun.aws.json

For a public repo
```
gantree init -p 3000 bleacher/cauldron:master
```
For a private repo
```
gantree init -u frodriguez -p 3000 bleacher/cauldron:master
```

### Deploy

This command renames your Dockerrun.aws.json temporarily to NAME_OF_ENV-GITHUB_HASH-Dockerrun.aws.json, uploads it to a NAME_OF_APP-versions bucket, creates a new elastic beanstalk version, and asks the specified elastic beanstalk environment to update to that new version.

```
gantree deploy stag-cauldron-app-s1
```
By default this will check for the environment cauldron-stag-s1 and deploy to the app stag-cauldron-app. You can also specify an environment name directly using -e.

```
gantree deploy -e cauldron-stag-s1 stag-cauldron-app-s1
```

You can also specify a new image tag to use for the deploy

```
gantree deploy -t latest stag-cauldon-app-s1
```

### Create Stacks

Gantree allows you to leverage the power of aws cloud formation to create your entire elastic beanstalk stack, rds, caching layer etc all while maintaining a set naming convention. This does the following: 
* uses the ruby-cloudformation-dsl to generate nested cloud formation templates inside a cfn folder in your repo
* uploads them to an s3 bucket
* uses aws-sdk to communicate with cfn and initiate the stack creation

To generate a basic staging cluster for linguist we would do:
```
gantree create stag-linguist-app-s1
```

In the elastic beanstalk console you will now see an application called 
**linguist-stag-s1** with an environment called **stag-linguist-app-s1**

You can modify the name of the environment if this does not fit your naming convention:
```
gantre create your_app_name -e your_env_name
```

Also if the cloud formation template that is generated doesn't match your needs (which it might now) you can edit the .rb files in the repo's cfn folder, build your own gem and use it how you like.
