require 'faker'
class ResourcesTemplate

  def initialize params
    @stack_name = params[:stack_name]
    @env = params[:env]
    @db_instance_size = params[:db_instance_size]
    @rds_enabled = params[:rds_enabled]
    @requirements = params[:requirements]
    @env_type = params[:env_type]
  end

  def create
    "#{@requirements}
    template do

      value :AWSTemplateFormatVersion => '2010-09-09'

      value :Description => '#{@env} Services Resources (2014-06-30)'

      parameter 'ApplicationName',
                :Type => 'String',
                :Default => '#{@env}'

      resource 'InstanceSecurityGroup', :Type => 'AWS::EC2::SecurityGroup', :Properties => {
          :GroupDescription => join('', 'an EC2 instance security group created for #{@env}')
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
      :DBInstanceClass => '#{@db_instance_size}',
      :DBSecurityGroups => [ ref('DBSecurityGroup') ],
      :Engine => '#{db_engine}',
      :EngineVersion => '#{db_version}',
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

  def db_engine
    return "postgres" if @rds == "pg"
    return "MySQL" if @rds == "mysql"
  end

  def db_version
    return "5.1.42" if @rds == "mysql"
    return "9.3" if @rds == "pg"
  end
end