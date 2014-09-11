class BeanstalkTemplate

  def initialize params
    @stack_name = params[:stack_name]
    @env = params[:env]
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
              :stag => { :name => 'sbleacherreport.com' },
              :prod => { :name => 'bleacherreport.com' }

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
                :Default => 'm3.large'

      parameter 'ApplicationName',
                :Description => 'The name of the Elastic Beanstalk Application',
                :Type => 'String',
                :Default => ref('ApplicationName')

      parameter 'Environment',
                :Type => 'String'

      parameter 'IamInstanceProfile',
                :Type => 'String',
                :Default => 'EbApp'

      resource 'Application', :Type => 'AWS::ElasticBeanstalk::Application', :Properties => {
          :Description => ref('ApplicationName'),
          :ApplicationName => join('-', ref('ApplicationName'), ref('Environment')),
      }

      resource 'ApplicationVersion', :Type => 'AWS::ElasticBeanstalk::ApplicationVersion', :Properties => {
          :ApplicationName => ref('Application'),
          :Description => 'Initial Version',
          :SourceBundle => {
              :S3Bucket => join('/','br-repos',ref('Environment')),
              :S3Key => join('',ref('Environment'), '-Dockerrun.aws.json'),
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
                  :Value => find_in_map('LongName', ref('Environment'), 'name'),
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
                  :Value => join(',', join('-', ref('Environment'), 'br'), ref('InstanceSecurityGroup')),
              },
              { :Namespace => 'aws:autoscaling:updatepolicy:rollingupdate', :OptionName => 'RollingUpdateEnabled', :Value => 'true' },
              { :Namespace => 'aws:autoscaling:updatepolicy:rollingupdate', :OptionName => 'MaxBatchSize', :Value => '1' },
              { :Namespace => 'aws:autoscaling:updatepolicy:rollingupdate', :OptionName => 'MinInstancesInService', :Value => '2' },
              { :Namespace => 'aws:elasticbeanstalk:hostmanager', :OptionName => 'LogPublicationControl', :Value => 'true' },
          ],
      }

      resource 'EbEnvironment', :Type => 'AWS::ElasticBeanstalk::Environment', :Properties => {
          :ApplicationName => ref('Application'),
          :EnvironmentName => join('-', ref('Environment'), ref('ApplicationName'), 'app'),
          :Description => 'Default Environment',
          :VersionLabel => ref('ApplicationVersion'),
          :TemplateName => ref('ConfigurationTemplate'),
          :OptionSettings => [],
      }

      resource 'HostRecord', :Type => 'AWS::Route53::RecordSet', :Properties => {
          :Comment => 'DNS name for my stack',
          :HostedZoneName => join('', find_in_map('HostedZoneName', ref('Environment'), 'name'), '.'),
          :Name => join('.', ref('ApplicationName'), find_in_map('HostedZoneName', ref('Environment'), 'name')),
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
end