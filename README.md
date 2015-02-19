# Gantree

[![Build Status](https://travis-ci.org/feelobot/gantree.svg?branch=master)](https://travis-ci.org/feelobot/gantree)
[![Test Coverage](https://codeclimate.com/github/feelobot/gantree/badges/coverage.svg)](https://codeclimate.com/github/feelobot/gantree)
[![Code Climate](https://codeclimate.com/github/feelobot/gantree/badges/gpa.svg)](https://codeclimate.com/github/feelobot/gantree)
[![Gem Version](https://badge.fury.io/rb/gantree.svg)](http://badge.fury.io/rb/gantree)
## Why Gantree?

The name is derived from the word gantry which is a large crane used in ports to pick up shipping containers and load them on a ship. Gantry was already taken so I spelled it "tree" because the primary use is for elastic beanstalk and I guess a beanstalk is a form of tree? 

## Description

This tool is intended to help you setup a Dockerrun.aws.json which allows you to deploy a prebuilt image of your application to Elastic Beanstalk. This also allows you to do versioned deploys to your Elastic Beanstalk application and create an archive of every versioned Dockerrun.aws.json in amazons s3 bucket service.

## Installation

### Prerequisites 
You need to have your AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables set in order to use the tool as well as the proper aws permissions for Elastic Beanstalk, and S3 access. 

*Install docker for MAC OSX*
https://docs.docker.com/installation/mac/

Generate your login credentials token:
```
docker login
```
### Setup
```
gem install gantree
```

### Initialize a new Repo
What this does is create a new Dockerrun.aws.json inside your repository and uploads your docker login credentials to s3 (for private repo access) so you can do deploys. We need the -u to specify a username to rename your .dockercfg and reference it in the Dockerrun.aws.json

```
# the username here is your docker.hub login
gantree init -u frodriguez -p 3000 bleacher/cauldron:master
# this will upload your docker config files to a bucket called "frodrigeuz-docker-cgfs"
```
If you don't have a docker.hub account, you can still use gantree without the `-u` flag, but you will have to explicitly specify the bucket for S3 storage since the default S3 bucket name is generated from the docker.hub login.

##### Specify the bucket for to S3 store docker configuration
```
# Since S3 bucket names are globally namespaced, the default bucket may be taken and unavailable
# Gantree gives you the option to specify an S3 bucket name of your choice
gantree init -u frodgriguez -p 3000 -b hopefully_this_bucket_name_is_available bleacher/cauldron:master
```

### Deploy

This command renames your Dockerrun.aws.json temporarily to NAME_OF_ENV-GITHUB_HASH-Dockerrun.aws.json, uploads it to a NAME_OF_APP-versions bucket, creates a new elastic beanstalk version, and asks the specified elastic beanstalk environment to update to that new version.

```
gantree deploy cauldron-stag-s1
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
gantree create linguist-stag-s1
```

In the elastic beanstalk console you will now see an application called 
**linguist-stag-s1** with an environment called **stag-linguist-app-s1**

You can modify the name of the environment if this does not fit your naming convention:
```
gantre create your_app_name -e your_env_name
```


### Ship 

This command does three things:

1) Builds the image (with an auto generated tag (origin-branch-hash) or custom tag using the -t flag
2) Uploads the image based on the --image-path flag or gantree.cfg (ie. hub.docker, quay.io)
3) Deploys the image to elastic beanstalk based on command line arguments and cfn files.

```
# assuming you already ran 'gantree init' and generated the Dockerrun.aws.json file
gantree ship linguist-stag-s2 -t branch-with-features-and-bug-fixes
```

##### Autodetecting environment roles

Let's say your linguist app consists of both an app and a worker. The Gantree ship command has an autodetect-app-role flag which will automatically detect the environment's role (app, worker, listener, etc.) by matching the environment name's third dash-delimited string and inject that as a `$ROLE` variable inside the Docker containers.

For example, suppose this is the cfn.json file:

```json
"Properties":{
  "ApplicationName": "linguist-stag-s2",
  "EnvironmentName": "stag-linguist-app-s2",
  ...
}

"Properties":{
  "ApplicationName": "linguist-stag-s2",
  "EnvironmentName": "stag-linguist-worker-s2",
  ...
}
```

You can call gantree ship with the autodetect flag

```
gantree ship linguist-stag-s2 --autodetect-app-role=true -t branch-with-features-and-bug-fixes
```

Now every environment's Docker container will have the `$ROLE` variable:

```
# Inside stag-linguist-app-s2 Docker container
root@adfd4543$ echo $ROLE
app

# Inside stag-linguist-worker-s2 Docker container
root@afklji231$ echo $ROLE
worker
```

As of Gantree version 0.4.9, the autodetect flag default is always on but if your env naming convention doesnt follow the stag-linguist-app-s2 convention, you should turn this off to avoid setting the wrong role variable in the Docker container.

## Update and Create
As mentioned earlier, Gantree leverages the power of aws cloud formation.  The gantree commands `update` and `create` are cloud formation specific gantree commands.

### Update
We use gantree's `update` command to change an application name, environment name, or other cloud formation changes.
```
# after making changes in your /cfn/*cfn.json files, you want to update the stack
gantree update linguist-stag-s1
```

```
# You can use the -r flag to easily add a new role to the cnf template
# Note the dry-run flag is used so we actually don't update the stack, but just changing the cfn files locally
gantree update linguist-prod-s1 -r worker --dry-run
```

### Create
The gantree `create` command does three things: 

1) Creates cfn templates
2) Sends them to s3
3) Creates the stack

```
gantree create linguist-prod-s1

# you can use the --local flag to skip the first step
gantree create linguist-prod-s1 --local
```

We use gantree's `create` command to create a new cfn template from an existing cfn template

```
# we already have linguist-prod-s1, and we want to create linguist-prod-s2
gantree create linguist-prod-s2 --dupe linguist-prod-s1
```

### .gantreecfg
Allow defaults for commands to be set in a json file 
```json
{
  "ebextensions" : "git@github.com:br/.ebextensions.git",
  "default_instance_size" : "m3.medium"
}
```

#### .ebextension Support
Elastic Beanstalk cli allows you to create a .ebextension folder that you can package with your deploy to control the host/environment of your application. Deploying only a docker container image referenced in Dockerrun.aws.json has the unfortunate side effect of losing this extreamly powerful feature. To allow this feature to be included in gantree and make it even better you can select either to package a local .ebextension folder with your deploy, package a remote .ebextension folder hosted in github (with branch support) or even create a .gantreecfg file to make either of these type of deploys a default.

```
gantree deploy -x "git:br/ebextensions:master" stag-cauldron-app-s1
```

By default your application will be created on a t1.micro unless you specify otherwise:
```
gantree ceate your_app_name -i m3.medium
```

#### What if you need a database? Here enters the beauty of RDS

PostgreSQL: ```gantree create your_app_name --rds pg```

Mysql: ```gantree create your_app_name --rds msql```

## TODO:

#### What if you want a cdn behind each of your generated applications

Fastly: ```gantree create your_app_name --cdn fastly```

CloudFront: ```gantree create yoour_app_name --cdn cloudfront```

#### Redis & Memcached
Elasticache ```gantree create your_app_name --cache redis``` or ```gantree create your_app_name --cache memcache```

#### Autogenerated Release Notes 

I would like have built in integration with opbeat configurable thorugh the .gantreecfg located in the applications repository.


***Notes:***

Also if the cloud formation template that is generated doesn't match your needs (which it might now) you can edit the .rb files in the repo's cfn folder, build your own gem and use it how you like.
