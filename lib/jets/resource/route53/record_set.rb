# CloudFormation Docs AWS::Route53::RecordSet: https://amzn.to/2BtP9s5
#
# Example:
#
#   DnsRecord:
#     Type: AWS::Route53::RecordSet
#     Properties:
#       HostedZoneName: !Ref 'HostedZoneResource'
#       Comment: DNS name for my instance.
#       Name: !Join ['', [!Ref 'Ec2Instance', ., !Ref 'AWS::Region', ., !Ref 'HostedZone', .]]
#       Type: A
#       TTL: '900'
#       ResourceRecords:
#       - !GetAtt Ec2Instance.PublicIp
module Jets::Resource::Route53
  class RecordSet < Jets::Resource::Base
    def definition
      {
        dns_record: {
          type: "AWS::Route53::RecordSet",
          properties: {
            hosted_zone_name: hosted_zone_name,
            comment: "DNS record managed by Jets",
            name: name,
            type: "CNAME",
            ttl: "60",
            resource_records: [
              cname,
            ],
          }
        }
      }
    end

    def cname
      if endpoint_types.include?("REGIONAL")
        "!GetAtt DomainName.RegionalDomainName"
      else
        "!GetAtt DomainName.DistributionDomainName"
      end
    end

    def domain_name
      Jets::Resource::ApiGateway::DomainName.new
    end
    memoize :domain_name

    def endpoint_types
      domain_name.endpoint_types
    end

    # IE: demo-dev.mydomain.com
    def name
      # Weird looking but correct: domain_name is object and domain_name is also method
      domain_name.domain_name
    end

    # IE: mydomain.com
    def hosted_zone_name
      name = Jets.config.domain.hosted_zone_name
      name.ends_with?('.') ? name : "#{name}." # add trailing period if missing
    end

    def outputs
      {
        "DnsRecord" => "!Ref DnsRecord",
      }
    end
  end
end