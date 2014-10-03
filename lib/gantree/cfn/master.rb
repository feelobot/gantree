class MasterTemplate

  def initialize params
    @stack_name = params[:stack_name]
    @rds = params[:rds]
    @env = params[:env]
    @bucket = params[:cfn_bucket]
    @requirements = params[:requirements]
  end

  def create
    "#{@requirements}
    template do 
      value :AWSTemplateFormatVersion => '2010-09-09'
      value :Description => '#{@stack_name} Master Template'

      parameter 'ResourcesTemplate',
                :Description => 'The key of the template for the resources required to run the app',
                :Type => 'String',
                :Default => '#{@env}-resources.cfn.json'

      parameter 'AppTemplate',
                :Description => 'The key of the template for the EB app/env substack',
                :Type => 'String',
                :Default => '#{@env}-beanstalk.cfn.json'

      parameter 'KeyName',
                :Type => 'String',
                :Default => 'default'

      parameter 'ApplicationName',
                :Type => 'String',
                :Default => '#{@env}'

      parameter 'Environment',
                :Type => 'String',
                :Default => '#{env_type}'

      parameter 'IamInstanceProfile',
                :Type => 'String',
                :Default => 'EbApp'

      resource 'AppResources', :Type => 'AWS::CloudFormation::Stack', :Properties => {
          :TemplateURL => join('/', 'http://s3.amazonaws.com', '#{@bucket}', '#{@env}', ref('ResourcesTemplate')),
          :Parameters => { :ApplicationName => ref('ApplicationName') },
      }

      resource 'App', :Type => 'AWS::CloudFormation::Stack', :Properties => {
          :TemplateURL => join('/', 'http://s3.amazonaws.com','#{@bucket}', '#{@env}', ref('AppTemplate')),
          :Parameters => {
              :KeyName => ref('KeyName'),
              :InstanceSecurityGroup => get_att('AppResources', 'Outputs.InstanceSecurityGroup'),
              :ApplicationName => ref('ApplicationName'),
              :Environment => ref('Environment'),
              :IamInstanceProfile => ref('IamInstanceProfile'),
              #{":RDSHostURLPass => get_att('AppResources','Outputs.RDSHostURL')," if rds_enabled?}
          },
      }

      output 'URL',
             :Description => 'URL of the AWS Elastic Beanstalk Environment',
             :Value => get_att('App', 'Outputs.URL')

    end.exec!"
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