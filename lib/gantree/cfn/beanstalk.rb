class BeanstalkTemplate

  def initialize params
    @stack_name = params[:stack_name]
    @docker_version = params[:solution] 
    @size = params[:instance_size]
    @rds = params[:rds]
    @env = params[:env]
    @domain = params[:domain]
    @requirements = params[:requirements]
    @rds_enabled = params[:rds?]
    @env_type = params[:env_type]
  end

  def create
    "#{@requirements}
    template do

      value :AWSTemplateFormatVersion => '2010-09-09'

      value :Description => '#{@stack_name} Service Parent Template (2014-08-15)'

      #{beanstalk_parmaters}

      resource 'Application', :Type => 'AWS::ElasticBeanstalk::Application', :Properties => {
          :Description => '#{@stack_name}',
          :ApplicationName => '#{@stack_name}',
      }

      #{configuration_template}

      #{resources}

      output 'URL',
             :Description => 'URL of the AWS Elastic Beanstalk Environment',
             :Value => join('', 'http://', get_att('EbEnvironment', 'EndpointURL'))

    end.exec!
    "
  end

  def beanstalk_parmaters
    "parameter 'KeyName',
                :Description => 'The Key Pair to launch instances with',
                :Type => 'String',
                :Default => 'default'

      parameter 'InstanceSecurityGroup',
                :Type => 'String'

      parameter 'InstanceType',
                :Description => 'EC2 Instance Type',
                :Type => 'String',
                :Default => '#{@size}'

      parameter 'ApplicationName',
                :Description => 'The name of the Elastic Beanstalk Application',
                :Type => 'String',
                :Default =>  '#{@stack_name}'

      parameter 'Environment',
                :Type => 'String',
                :Default => '#{@env_type}'

      parameter 'IamInstanceProfile',
                :Type => 'String',
                :Default => 'EbApp'

      #{"parameter 'RDSHostURLPass', :Type => 'String'" if @rds_enabled }"

  end

  def configuration_template
    "resource 'ConfigurationTemplate', :Type => 'AWS::ElasticBeanstalk::ConfigurationTemplate', :Properties => {
        :ApplicationName => ref('Application'),
        :SolutionStackName => '#{@docker_version}',
        :Description => 'Default Configuration Version #{@docker_version} - with SSH access',
        :OptionSettings => [
            {
                :Namespace => 'aws:elasticbeanstalk:application:environment',
                :OptionName => 'AWS_REGION',
                :Value => aws_region,
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
                :Value => join(',', join('-', '#{@env_type}', 'br'), ref('InstanceSecurityGroup')),
            },
            { :Namespace => 'aws:autoscaling:updatepolicy:rollingupdate', :OptionName => 'RollingUpdateEnabled', :Value => 'true' },
            { :Namespace => 'aws:autoscaling:updatepolicy:rollingupdate', :OptionName => 'MaxBatchSize', :Value => '1' },
            { :Namespace => 'aws:autoscaling:updatepolicy:rollingupdate', :OptionName => 'MinInstancesInService', :Value => '2' },
            { :Namespace => 'aws:elasticbeanstalk:hostmanager', :OptionName => 'LogPublicationControl', :Value => 'true' },
            #{set_rds_parameters if @rds_enabled }
        ],
    }"
  end

  def resources
    "resource 'EbEnvironment', :Type => 'AWS::ElasticBeanstalk::Environment', :Properties => {
        :ApplicationName => '#{@stack_name}',
        :EnvironmentName => '#{@env}',
        :Description => 'Default Environment',
        :TemplateName => ref('ConfigurationTemplate'),
        :OptionSettings => [],
    }

    resource 'HostRecord', :Type => 'AWS::Route53::RecordSet', :Properties => {
        :Comment => 'DNS name for my stack',
        :HostedZoneName => '#{@domain}',
        :Name => join('.', '#{@stack_name}', '#{@domain}'),
        :ResourceRecords => [ get_att('EbEnvironment', 'EndpointURL') ],
        :TTL => '60',
        :Type => 'CNAME',
    }"
  end
  def set_rds_parameters
    "{
      :Namespace => 'aws:elasticbeanstalk:application:environment',
      :OptionName => 'DB_HostURL',
      :Value => ref('RDSHostURLPass'),
    },"
  end
end