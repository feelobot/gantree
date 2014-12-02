class ResourcesTemplate

  def initialize params
    @stack_name = params[:stack_name]
    @rds = params[:rds]
    @env = params[:env]
    @rds_enabled = params[:rds?]
    @requirements = params[:requirements]
    @env_type = params[:env_type]
  end

  def create
    "#{@requirements}
    template do

      value :AWSTemplateFormatVersion => '2010-09-09'

      value :Description => '#{@stack_name} Services Resources (2014-06-30)'

      parameter 'ApplicationName',
                :Type => 'String',
                :Default => '#{@stack_name}'

      resource 'InstanceSecurityGroup', :Type => 'AWS::EC2::SecurityGroup', :Properties => {
          :GroupDescription => join('', 'an EC2 instance security group created for #{@stack_name}')
      }

      output 'InstanceSecurityGroup',
             :Value => ref('InstanceSecurityGroup')

      #{rds if @rds_enabled}

    end.exec!
    "
  end

  def rds
    "resource 'sampleDB', :Type => 'AWS::RDS::DBInstance', :DeletionPolicy => 'Snapshot', :Properties => {
      :DBName => 'sampledb',
      :AllocatedStorage => '10',
      :DBInstanceClass => 'db.m3.large',
      :DBSecurityGroups => [ ref('DBSecurityGroup') ],
      :Engine => 'postgres',
      :EngineVersion => '9.3',
      :MasterUsername => 'masterUser',
      :MasterUserPassword => 'masterpassword',
    }

    resource 'DBSecurityGroup', :Type => 'AWS::RDS::DBSecurityGroup', :Properties => {
      :DBSecurityGroupIngress => [
          { :EC2SecurityGroupName => ref('InstanceSecurityGroup') },
      ],
      :GroupDescription => 'Allow Beanstalk Instances Access',
    }
    
    output 'RDSHostURL',
      :Value => get_att('sampleDB', 'Endpoint.Address')
    "
  end
end