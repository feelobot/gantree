#!/usr/bin/env ruby

require 'bundler/setup'
require 'cloudformation-ruby-dsl/cfntemplate'
require 'cloudformation-ruby-dsl/spotprice'
require 'cloudformation-ruby-dsl/table'

template do

  value :AWSTemplateFormatVersion => '2010-09-09'

  value :Description => 'Knarr Service\'s Resources (2014-06-30)'

  parameter 'ApplicationName',
            :Type => 'String',
            :Default => ref('ApplicationName')

  resource 'InstanceSecurityGroup', :Type => 'AWS::EC2::SecurityGroup', :Properties => {
      :GroupDescription => join('', 'an EC2 instance security group created for ', ref('ApplicationName')),
      :SecurityGroupIngress => [],
  }

  output 'InstanceSecurityGroup',
         :Value => ref('InstanceSecurityGroup')

end.exec!
