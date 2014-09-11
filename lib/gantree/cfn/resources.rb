class ResourcesTemplate

  def initialize params
    @stack_name = params[:stack_name]
    @env = params[:env]
    @requirements = params[:requirements]
  end

  def create
    "#{@requirements}
    template do

      value :AWSTemplateFormatVersion => '2010-09-09'

      value :Description => '#{@env} Services Resources (2014-06-30)'

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
    "
  end
end