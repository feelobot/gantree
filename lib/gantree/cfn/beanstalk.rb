class BeanstalkTemplate

  def initialize params
    @stack_name = params[:stack_name]
    @size = params[:instance_size]
    @rds = params[:rds]
    @env = params[:env]
    @prod_domain = params[:prod_domain]
    @stag_domain = params[:stag_domain]
    @requirements = params[:requirements]
  end

  def create
    "#{@requirements}
    template do

      value :AWSTemplateFormatVersion => '2010-09-09'

      value :Description => '#{@env} Service Parent Template (2014-08-15)'

      mapping 'LongName',
              :stag => { :name => 'staging' },
              :prod => { :name => 'production' }

      mapping 'HostedZoneName',
              :stag => { :name => '#{@stag_domain}' },
              :prod => { :name => '#{@prod_domain}' }

      parameter 'KeyName',
                :Description => 'The Key Pair to launch instances with',
                :Type => 'String',
                :Default => 'default'

      parameter 'InstanceSecurityGroup',
                :Type => 'String'

      parameter 'InstanceType',
                :Description => 'EC2 Instance Type',
                :Type => 'String',
                :AllowedValues => %w(t1.micro m1.small m3.medium m3.large m3.xlarge m3.2xlarge c3.large c3.xlarge c3.2xlarge c3.4xlarge c3.8xlarge),
                :Default => '#{@size}'

      parameter 'ApplicationName',
                :Description => 'The name of the Elastic Beanstalk Application',
                :Type => 'String',
                :Default =>  '#{@env}'

      parameter 'Environment',
                :Type => 'String',
                :Default => 'stag'

      parameter 'IamInstanceProfile',
                :Type => 'String',
                :Default => 'EbApp'

      parameter 'RDSHostURL',
                :Type => 'String'

      resource 'Application', :Type => 'AWS::ElasticBeanstalk::Application', :Properties => {
          :Description => '#{@env}',
          :ApplicationName => '#{@env}',
      }

      resource 'ApplicationVersion', :Type => 'AWS::ElasticBeanstalk::ApplicationVersion', :Properties => {
          :ApplicationName => ref('Application'),
          :Description => 'Initial Version',
          :SourceBundle => {
              :S3Bucket => 'elasticbeanstalk-samples-us-east-1',
              :S3Key => 'docker-sample.zip',
          },
      }

      resource 'ConfigurationTemplate', :Type => 'AWS::ElasticBeanstalk::ConfigurationTemplate', :Properties => {
          :ApplicationName => ref('Application'),
          :SolutionStackName => '64bit Amazon Linux 2014.03 v1.0.1 running Docker 1.0.0',
          :Description => 'Default Configuration Version 1.0 - with SSH access',
          :OptionSettings => [
              {
                  :Namespace => 'aws:elasticbeanstalk:application:environment',
                  :OptionName => 'AWS_REGION',
                  :Value => aws_region,
              },
              {
                  :Namespace => 'aws:elasticbeanstalk:application:environment',
                  :OptionName => 'RACK_ENV',
                  :Value => find_in_map('LongName', '#{env_type}', 'name'),
              },
              {
                  :Namespace => 'aws:autoscaling:launchconfiguration',
                  :OptionName => 'EC2KeyName',
                  :Value => ref('KeyName'),
              },
              {
                  :Namespace => 'aws:autoscaling:launchconfiguration',
                  :OptionName => 'IamInstanceProfile',
                  :Value => ref('IamInstanceProfile'),
              },
              {
                  :Namespace => 'aws:autoscaling:launchconfiguration',
                  :OptionName => 'InstanceType',
                  :Value => ref('InstanceType'),
              },
              {
                  :Namespace => 'aws:autoscaling:launchconfiguration',
                  :OptionName => 'SecurityGroups',
                  :Value => join(',', join('-', '#{env_type}', 'br'), ref('InstanceSecurityGroup')),
              },
              { :Namespace => 'aws:autoscaling:updatepolicy:rollingupdate', :OptionName => 'RollingUpdateEnabled', :Value => 'true' },
              { :Namespace => 'aws:autoscaling:updatepolicy:rollingupdate', :OptionName => 'MaxBatchSize', :Value => '1' },
              { :Namespace => 'aws:autoscaling:updatepolicy:rollingupdate', :OptionName => 'MinInstancesInService', :Value => '2' },
              { :Namespace => 'aws:elasticbeanstalk:hostmanager', :OptionName => 'LogPublicationControl', :Value => 'true' },
              #{set_rds_parameters}
          ],
      }

      resource 'EbEnvironment', :Type => 'AWS::ElasticBeanstalk::Environment', :Properties => {
          :ApplicationName => '#{@env}',
          :EnvironmentName => '#{@stack_name}',
          :Description => 'Default Environment',
          :VersionLabel => ref('ApplicationVersion'),
          :TemplateName => ref('ConfigurationTemplate'),
          :OptionSettings => [],
      }

      resource 'HostRecord', :Type => 'AWS::Route53::RecordSet', :Properties => {
          :Comment => 'DNS name for my stack',
          :HostedZoneName => join('', find_in_map('HostedZoneName', '#{env_type}', 'name'), '.'),
          :Name => join('.', ref('ApplicationName'), find_in_map('HostedZoneName', '#{env_type}', 'name')),
          :ResourceRecords => [ get_att('EbEnvironment', 'EndpointURL') ],
          :TTL => '60',
          :Type => 'CNAME',
      }

      output 'URL',
             :Description => 'URL of the AWS Elastic Beanstalk Environment',
             :Value => join('', 'http://', get_att('EbEnvironment', 'EndpointURL'))

    end.exec!
    "
  end
  def set_rds_parameters
    if rds_enabled?
      "{
        :Namespace => 'aws:elasticbeanstalk:application:environment',
        :OptionName => 'DB_HostURL',
        :Value => ref('RDSHostURLPass'),
      },"
    else
      nil
    end
  end

  def rds_enabled?
    if @rds == nil
      puts "RDS is not enabled, no DB created"
      false
    elsif @rds == "pg" || @rds == "mysql"
      puts "RDS is enabled, creating DB"
      true
    else
      raise "The --rds option you passed is not supported please use 'pg' or 'mysql'"
    end
  end

  def env_type
    if @env.include?("prod")
      "prod"
    elsif @env.include?("stag")
      "stag"
    else
      ""
    end
  end

end