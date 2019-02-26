---
title: Minimal Deploy IAM Policy
---

The IAM user you use to run the `jets deploy` command needs a minimal set of IAM policies in order to deploy a Jets application. Here is a table of the baseline services needed:

Service | Description
--- | ---
API Gateway | To create the API Gateway resources.
CloudFormation | To create the CloudFormation stacks that then creates the most of the AWS resources that Jets creates.
DynamoDB | To look up DynamoDB table stream arn if using [DynamoDB Events]({% link _docs/events-dynamodb.md %}).
Events | To create the CloudWatch Event Rules for jobs.
IAM | To create IAM roles to be associated with the Lambda functions.
Lambda | To prewarm the application upon deployment completion.
Logs | To clean up CloudWatch logs when deleting the application.
Route53 | To create vanity DNS endpoint when using [custom domains]({% link _docs/routing-custom-domain.md %}).
S3 | To upload code to s3.

## Instructions

It is recommended that you create an IAM group and associate it with the IAM users that need access to use `jets deploy`.  Here are starter instructions and a policy that you can tailor for your needs:

### Commands Summary

Here's a summary of the commands:

    aws iam create-group --group-name Jets
    cat << 'EOF' > /tmp/jets-iam-policy.json
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "apigateway:*",
                    "cloudformation:*",
                    "dynamodb:*",
                    "events:*",
                    "iam:*",
                    "lambda:*",
                    "logs:*",
                    "route53:*",
                    "s3:*"
                 ],
                "Resource": [
                    "*"
                ]
            }
        ]
    }
    EOF
    aws iam put-group-policy --group-name Jets --policy-name JetsPolicy --policy-document file:///tmp/jets-iam-policy.json

Then create a user and add the user to IAM group. Here's an example:

    aws iam create-user --user-name tung
    aws iam add-user-to-group --user-name tung --group-name Jets

## Additional IAM Permissions

The baseline IAM policy above might not include all the permissions required depending on what your Jets application does. For example, if you are using [AWS Config Rules]({% link _docs/config-rules.md %}) or [Custom Resources]({% link _docs/custom-resources.md %}), then you would need to add permissions specific to those resources. This is why an IAM group is recommended.  You simply have to update the group policies.

Here's how you add a managed IAM policy that provides the AWS Config Rule permissions:

    aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/service-role/AWSConfigRole --group-name Jets

The IAM Policies for the group looks something like this:

![](/img/docs/minimal-iam-policy.png)

## Lambda Function vs User Deploy IAM Policies

This page refers to your **user** IAM policy used when running `jets deploy`. These are different from the IAM Policies associated with created Lambda functions.  For those iam policies refer to:

* [IAM Policies]({% link _docs/iam-policies.md %})
* [Managed IAM Policies]({% link _docs/managed-iam-policies.md %})

<a id="prev" class="btn btn-basic" href="{% link _docs/rescue-from.md %}">Back</a>
<a id="next" class="btn btn-primary" href="{% link _docs/custom-inflections.md %}">Next Step</a>
<p class="keyboard-tip">Pro tip: Use the <- and -> arrow keys to move back and forward.</p>
