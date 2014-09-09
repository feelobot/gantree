class MasterTemplate
  def initialize(options ={})
    @app = options.app
    @env = options.env
    @cfn_bucket = "br-templates"
  end

  def generate
    IO.write("master_cfn.rb","
      require 'cloudformation-ruby-dsl/cfntemplate'
      require 'cloudformation-ruby-dsl/spotprice'
      require 'cloudformation-ruby-dsl/table'
      template do 
        value :AWSTemplateFormatVersion => '2010-09-09'
        value :Description => '#{@app} Master Template'

        parameter 'ResourcesTemplate',
                  :Description => 'The key of the template for the resources required to run the app',
                  :Type => 'String',
                  :Default => '#{@app}-resources.cfn.json'

        parameter 'AppTemplate',
                  :Description => 'The key of the template for the EB app/env substack',
                  :Type => 'String',
                  :Default => '#{@app}-elasticbeanstalk.cfn.json'

        parameter 'KeyName',
                  :Default => 'default'

        parameter 'InstanceType',
                  :Type => 'String',
                  :Default => 't1.micro'

        parameter 'ApplicationName',
                  :Type => 'String'

        parameter 'Environment',
                  :Type => 'String',
                  :Default => @env

        parameter 'IamInstanceProfile',
                  :Type => 'String',
                  :Default => 'EbApp'

        resource 'AppResources', :Type => 'AWS::CloudFormation::Stack', :Properties => {
            :TemplateURL => join('/', 'http://s3.amazonaws.com/br-templates', ref('ApplicationName'), ref('ResourcesTemplate')),
            :Parameters => { :ApplicationName => ref('ApplicationName') },
        }

        resource 'App', :Type => 'AWS::CloudFormation::Stack', :Properties => {
            :TemplateURL => join('/', 'http://s3.amazonaws.com/#{@cfn_bucket}', ref('ApplicationName'), ref('AppTemplate')),
            :Parameters => {
                :KeyName => ref('KeyName'),
                :InstanceSecurityGroup => get_att('AppResources', 'Outputs.InstanceSecurityGroup'),
                :InstanceType => ref('InstanceType'),
                :ApplicationName => ref('ApplicationName'),
                :Environment => ref('Environment'),
                :IamInstanceProfile => ref('IamInstanceProfile'),
            },
        }

        output 'URL',
               :Description => 'URL of the AWS Elastic Beanstalk Environment',
               :Value => get_att('App', 'Outputs.URL')

      end.exec!")
      `bundle exec cfn-validate master_cfn.rb`
    end
  end
