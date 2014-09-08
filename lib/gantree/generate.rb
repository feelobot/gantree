require 'cloudformation-ruby-dsl'
module Gantree
  class Generate

    def initialize app,options
      @options = options
      AWS.config(
        :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
        :secret_access_key => ENV['AWS_SECRET_ACCES_KEY'])
    end

    

    def create_master_template
      template do
        parameter 'Label',
                  :Description => 'The label to apply to the servers.',
                  :Type => 'String',
                  :MinLength => '2',
                  :MaxLength => '25',
                  :AllowedPattern => '[_a-zA-Z0-9]*',
                  :ConstraintDescription => 'Maximum length of the Label parameter may not exceed 25 characters and may only contain letters, numbers and underscores.',
                  # The :Immutable attribute is a Ruby CFN extension.  It affects the behavior of the '<template> cfn-update-stack ...'
                  # operation in that a stack update may not change the values of parameters marked w/:Immutable => true.
                  :Immutable => true

        parameter 'InstanceType',
                  :Description => 'EC2 instance type',
                  :Type => 'String',
                  :Default => 'm2.xlarge',
                  :AllowedValues => %w(t1.micro m1.small m1.medium m1.large m1.xlarge m2.xlarge m2.2xlarge m2.4xlarge c1.medium c1.xlarge),
                  :ConstraintDescription => 'Must be a valid EC2 instance type.'

        parameter 'ImageId',
                  :Description => 'EC2 Image ID',
                  :Type => 'String',
                  :Default => 'ami-255bbc4c',
                  :AllowedPattern => 'ami-[a-f0-9]{8}',
                  :ConstraintDescription => 'Must be ami-XXXXXXXX (where X is a hexadecimal digit)'
      end
    end
  end
end
