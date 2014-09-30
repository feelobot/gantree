class ResourcesTemplate

  def initialize params
    @stack_name = params[:stack_name]
    @rds = params[:rds]
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
                :Default => '#{@env}'

      resource 'InstanceSecurityGroup', :Type => 'AWS::EC2::SecurityGroup', :Properties => {
          :GroupDescription => join('', 'an EC2 instance security group created for #{@env}')
      }

      #{rds}

      output 'InstanceSecurityGroup',
             :Value => ref('InstanceSecurityGroup')

    end.exec!
    "
  end

  def rds
    if rds_enabled?
      "
      value :sampleDB => {
          :Type => 'AWS::RDS::DBInstance',
          :Properties => {
              :DBName => 'sampledb',
              :AllocatedStorage => '10',
              :DBInstanceClass => 'db.m3.large',
              :DBSecurityGroups => [ ref('DBSecurityGroup') ],
              :Engine => 'postgres',
              :EngineVersion => '9.3',
              :MasterUsername => 'masterUser',
              :MasterUserPassword => 'masterpassword',
          },
          :DeletionPolicy => 'Snapshot',
        }

        value :DBSecurityGroup => {
          :Type => 'AWS::RDS::DBSecurityGroup',
          :Properties => {
              :DBSecurityGroupIngress => [
                  { :EC2SecurityGroupName => ref('InstanceSecurityGroup') },
              ],
              :GroupDescription => 'Allow Beanstalk Instances Access',
          },
        }

        output 'RDSHostURL',
          :Value => get_att('sampleDB', 'Endpoint.Address')
      "
    else
      nil
    end
  end

  def rds_enabled?
    if @rds == nil
      false
    elsif @rds == "pg" || @rds == "mysql"
      true
    else
      raise "The --rds option you passed is not supported please use 'pg' or 'mysql'"
    end
  end

end