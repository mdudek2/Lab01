# Questions for Lab01

## Q1 (explore). Tests as security controls

Your tests state security facts that must stay true, such as the
launch script never opening port 22 and the onboarding role attaching only the MFA guard. Explain where in a
delivery pipeline you would run them so that a bad change cannot reach production, and name two kinds of
problem they cannot catch. Compare them with policy as code and analysis tools (for example IAM Access
Analyzer policy validation, cfn-guard or Open Policy Agent) and with a secret scanner like the credential
check in create_repo.sh.

## Q1 Answer

Tests would typically be run before pushing from a test environment to a production environment. This is because they are designed to catch problems before they are pushed to production. Unit tests are typically run automatically when code is pushed to a development repository. Integration tests would typically be run in a dedicated testing environment only after unit tests succeed/pass. Unit tests and integration tests are mostly designed to test an applications functionality and cannot catch all problems. For example, unit and integration tests would not be able to detect security misconfigurations and overly permissive security polciies, nor would they be able to detect/stop configuration drift due to an error in the deployment process.

Policy as code and analysis tools are designed to stop different problems than unit/integration tests. For example, tools such as AWS IAM Access Analyzer and Open Policy Agent are able to examine polcies to determine if they are overly permissive or insecure as well as stop insecure deployments from running. Unit and integration tests are also generally not designed to stop secrets from being accidentaly pushed to production. This would typically be done via a .gitignore file and via credential checks in deployment scripts. The create_repo.sh script in this repository does this via the grep command and will refuse to commit anything if it detects something like a private key.

## Q2. Why does Nimbus-RequireMFA use BoolIfExists rather than Bool?

The Nimbus-RequireMFA policy document uses BoolIfExists rather than Bool because BoolIfExists accounts for situations where there is no MFA present. If Bool was used instead of BoolIfExists then a user with no MFA would be able to bypass the deny. This is not the intended behavior, so the policy needs to use BoolIfExists to account for this possibility and correctly deny the request.

## Q3. In TechTeam-DevScoped, why is a Deny still useful when no Allow grants IAM access?

A Deny is still useful in this policy because it provides an additional layer of security. Explicitely denying a permission always overrides an Allow. This helps ensure that any future policies that are added/created don't accidentaly grant too many permissions. It is good practice to explicitely Deny permissions that are not needed for a particular role.

## Q4 (explore). Group membership as an escalation path

The onboarding role may add users to any group under the /nimbus/ path. If an attacker took over the onboarding service, which of your three groups would be the most valuable to join, and what could the new user then do? Compare a permissions boundary, a Condition on the group name, and a Service Control Policy as ways to close this gap, and say which you would choose.

## Q4 Answer

The most valuable of these three groups to join would be the SecurityTeam group. This is because this group is able to create new policies, create policy versions, and delete policy versions. An attacker that gets access to this group would be able to modify policies that are attached to existing entities which would allow for privelage escalation. A permission could potentially be used to close this gap because it determines the maximum amount of permissions that an IAM user is able to acquire from identity policies. A condition on the group name is not a very good way of closing this gap because it isn't capable of limiting permissions based on group. It is moreso used to restrict IAM operations based on a specific principle/identity. A service control policy/SCP is a way to limit Maximum permissions for IAM users and Roles across a whole organization. This could set global boundaries and protect any group from privelage escalation. If I used an SCP I would be able to limit priveleage escalation even if I decide to modify my groups or create additional groups. Because of this I would choose to use an SCP to close this security gap.

## Q5. Name three places the admin password could have ended up if you had not used Secrets Manager. Why is each one worse?

If I had not used AWS Secrets Manager then the admin password could have potentially ended up in several different places. For example, it could have ended up accidentaly commited to github repository which would have exposed/compromised it. Alternatively, it could have also ended up in a .env file on my local system. This isn't as bad as commiting it to version control, but it is still not as secure as a secrets manager because it can still potentially be viewed/stolen by attackers. Lastly, the admin password could have also ended up as something that was placed in a text file stored in some random directory on my pc. This is a terrible way to manage secrets because they can be easily lost, stolen, or moved to a less secure location either intentionally by an attacker or accidentaly by simply misplacing the file or accidentaly backing it up to cloud storage.

## Q6. What does the TLS only bucket policy stop that Block Public Access does not?

The TLS only bucket policy stops requests that use older/outdated versions of TLS. This is done for security reasons so that the data that is being transmitted is encrypted in a secured fashion. The block public access policy does not stop this. It only restricts public access to the bucket.

## Q7 (explore). Customer managed keys

The lab uses the default encryption keys (SSE-S3 and the default Secrets Manager key) to stay free. Which threats does a customer managed KMS key address that default encryption does not? Describe how a key policy would separate the people who administer the key from the people and roles who use it, and what the extra cost and failure modes are.

## Q7 Answer

A customer managed KMS key addresses several threats that the default encryption does not. For example, a customer managed key provides more overall control over the key through custom policies and more freedom over the management of the key itself. For example, a customer controlled key can be more easily and more readily disabled and revoked than an AWS managed key. A few types of threats that a customer managed key can protect from are insider abuse, unauthorized decryption of data, and decrypting of future data. A key policy can seperate people who administer the key and the people who use it by restricting how certain groups are able to interact with the key. For example, developers should be allowed to use the key to encrypt or decrypt data but they should not be able to control when the key is rotated. Security team members should be allowed to configure when a key is rotated, when it is revoked, and when a new key is needed but they shouldn't necesarily be allowed to use the key to decrpyt data. Customer managed keys do incur some additional cost. As of 2026 the cost is roughly 1 dollar per month per key. Additionl features might cost extra depending on exactly how the key is managed. There are also many failure modes to consider when using a customer managed key. For example, with a default key AWS manages the keys lifecycle and rotation is done automatically. There are also some safeguards in place to prevent the key from being deleted. With a customer managed key the customer is responsible for managing all aspects of the key and its lifecycle. This opens up the possibility of accidentaly deleting or revoking a key without having any other keys enabled. This can result in permanent access loss to a resource. In some cases this is only a minor inconvenience, but this could be devastating if that particular resource contained important data tha was not backed up anywhere.

## Q8. For each of the three simulator results, name the Principal, Action, Resource and Request context, and say which statement decided it

Test 1

- Principal: arn:aws:iam::337820988322:role/nimbus/nimbus-onboarding-svc
- Action: iam:AttachUserPolicy
- Resource: arn:aws:iam::337820988322:user/nimbus/alice
- Request Context: iam:PolicyARN = arn:aws:iam::aws:policy/AdministratorAccess
- Statement that decided it: AttachOnlyTheMFAGuardPolicy from policies/svc-onboarding.json

Test 2

- Principal: arn:aws:iam::337820988322:role/nimbus/nimbus-onboarding-svc
- Action: iam:AttachUserPolicy
- Resource: arn:aws:iam::337820988322:user/nimbus/alice
- Request Context: iam:PolicyARN = arn:aws:iam::337820988322:policy/nimbus/Nimbus-RequireMFA
- Statement that decided it: AttachOnlyTheMFAGuardPolicy from policies/svc-onboarding.json
  
Test 3

- Principal: arn:aws:iam::337820988322:role/nimbus/nimbus-onboarding-svc
- Action: iam:CreateLoginProfile
- Resource: arn:aws:iam::337820988322:user/labuser
- Request Context: iam:PolicyARN = arn:aws:iam::aws:policy/AdministratorAccess
- Statement that decided it: CreateAndTagNimbusUsersOnly from policies/svc-onboarding.json

## Q9 (explore). Four containers, one host

All four containers share one instance, so a compromised container could assume any service role. Explain how the hop limit of 2 and the instance role make that possible. Then compare three redesigns (one instance per service, container task roles on Amazon ECS, and pod level identity on Kubernetes) on isolation, cost and operational effort.

## Q9 Answer

The hop limit of 2 allow the credentials to reach the container that made the request. This is needed because docker containers are running on a different network, so they need to be abe to acquire credentials on a different network. As for how a compromised container can assume any service role, this is because the role is attached to the ec2 instance itself and not the container. Since all containers are running on the same instance they are effectively considered to be the same identity/entity. There are several redesigns such as having one instance per service, container task roles on ECS, and pod level identity on Kubernetes. Having one instance per service would be good for isolating each of the services, but it would cost considerably more because I would now need to have 4 seperate EC2 intances running. It would also take more effort to manage these systems from an operational standpoint. Using container task roles would allow me to seperate roles better but it would take more effort because I would have to configure ECS. It would be much cheaper than running 4 seperate instances though. It also wouldn't be as secure as having four seperate instances. Using pod level identity on Kubernetes would be cheaper than having seperate instances and would offer a good amount of isolation, but it would take considerably more operational effort to properly configure due to needing to configure and setup Kubernetes.

## Q10. Which two kinds of event does the lab alert on, and why alert on them instead of only storing them?

The two kinds of events that this lab alerts on are risky changes to IAM and a console sign in without multi factor authentication. It is important to alert on these as opposed to only storing them because these are potentially dangerous events. A dangerous IAM change is a sign that someone has breached the system. Alerting on this enables a quick response and helps identify and stop the breach. Alerting on a login without MFA allows for detecting a vulnerable/compromised account so that it can be disabled before it causes any harm.

## Q11 (explore). Blind spots in detection

The two EventBridge rules cover a short list of events. Name two attacker actions against IAM that these rules would miss (for example creating a login profile for an existing user, or using stolen credentials from an unusual location). Write the event pattern for one of them, and discuss alert fatigue and how a managed service such as Amazon GuardDuty approaches the same problem.

## Q11 Answer

Two actions that an attacker could take that these rules would miss are creating new IAM roles or users and creating a login profile for existing IAM users that only have programatic access.

### Event pattern to catch creation of IAM roles and users

```json

{
  "source": ["aws.iam"],
  "detail-type": ["AWS API Call via CloudTrail"],
  "detail": {
    "eventSource": ["iam.amazonaws.com"],
    "eventName": [
      "CreateUser",
      "CreateRole"
    ]
  }
}

```

Alert fatigue is a problem that occurs when there are too many unimportant or false alerts being triggered in a system. When this happens IT personnel tend to start ignoring alerts. This is a major issue because it causes situations where a critical alert is ignored due to the mistaken belief that it is simply another false alarm. Managed services such as Amazon GuardDuty help mitigate alert fatigue because they aggregate and categorize alerts from various sources. These alerts are automatically sorted and prioritized with the help of AI to help ensure that administrators are able to see the most important alerts.

## Q12. Why is there no SSH and no key pair, and how do you debug the server without them?

There is no SSH enabled, nor is there a key pair in this lab because these are all potential vulnerabilities in a system. This app is just a few simple microservices. There isn't really any reason why a user would need to login to this particular system because it is simple and can be readily redeployed in just a few minutes. Enabling SSH would only provide an additional attack vector, so it remains disabled. The server can be debugged by running aws ec2 get-console-output "instance-id". This grabs the console output from the server and allows an administrator to debug issues. I used this method in the lab to debug being unable to access the dashboard. Based on console output I determined that I accidentally used the wrong url when cloning the repository with 05-launch-ec2.sh. Because of this the app never deployed, so there was no dashboard to access. I was then able to destroy all resources and redeploy without needing to SSH into the server.

## Q13. If the web container were compromised, what does egress filtering stop and what does it not stop?

If the web container was compromised than egress filtering would stop all traffic except for http and https. This means that an attacker would not be able to use other protocols like SSH to move laterally to other systems. It would not stop traffic that used http or https, so the attacker could still try to access other websites/portals, or they could possibly try to download some malicious code onto the server via curl or some other command.

## Q14 (explore). Certificates and trust on first use

The console uses a self signed certificate and you compared its fingerprint by hand. Explain the attack this comparison defends against and why most users skip it. Compare this with a certificate from AWS Certificate Manager behind a load balancer, and with a public certificate authority. What do HSTS and certificate transparency add?

## Q14 Answer

Comparing the certificate by hand helps defend against man in the middle attacks. Since the certificate is self signed an attacker can simply generate their own and try to trick a user into entering sensitive data on a website that they control instead of the real site. Comparing the certificate protects against this because it allows me to make sure that I am connecting to the correct system. Most users skip verifying the certificate because it is tedious and they simply do not want to do it. Certificates from AWS Certificate Manager and certificates from public certificate authorities are typically trusted by the browser, so a user does not have to verify it manually. HSTS adds an additional layer of security by preventing browsers from ever loading a resource over http. This prevents ssl stripping attacks. Certificate transparancy helps protect against scenarios where a valid/legit certificate was assigned to a malicious site by mistake. It essentially just adds another check/safety measure to certificates.

## Q15 Which of the six checks proved encryption in transit, which proved a smaller attack surface, and which proved protection against password guessing?

The first two checks proved that the application uses encryption in transit because http was rejected and the application uses secure headers. The third checked proved a smaller attack surface because ssh and port 8080 were closed and only 8443 was accepting traffic. The fourth test proved that there was protection against password guessing because there was a lockout after multiple incorrect passwords were tried.

## Q16. Why does the same user and action get denied without MFA and allowed with it? Quote the condition key

The same user and action get denied without MFA and allowed with it because we attached a policy called Nimbus-RequireMFA to each nimbus user when they were created. This effectively forces MFA, so when we simulated an action without MFA we recieved an "explicit deny" and when the same action was simulated with MFA we get "allowed". The condition key for our policy is "aws:MultiFactorAuthPresent" and it's value is set to false. Basically, the polcy will Deny actions if there is no MFA present.

The condition key for the policy is shown below

```json
{
            "Sid": "DenyEverythingExceptMFASetupWhenNoMFA",
            "Effect": "Deny",
            "NotAction": [ ... ],
            "Resource": "*",
            "Condition": {
                "BoolIfExists": {
                    "aws:MultiFactorAuthPresent": "false"
                }
            }
        }
```

## Q17. Who created mallory and how did you find out? Why does the audit trail in S3 not show it?

My IAM user "labuser" that I am using for this project created mallory. I found out by running the 08-investigate.sh" script and looking at the cloudtrail results. The audit trail in S3 doesn't show it because the user was not created through the dashboard/application and was created directly through aws cli.

## Q18 (explore). Replacing IAM users with single sign on

Suppose the company adopts AWS IAM Identity Center with an external identity provider. Which parts of this lab become unnecessary, which still matter (for example the MFA guard, the kill switch and drift detection), and what new risks appear, such as a compromised identity provider?

## Q18 Answer

If the company were to adopt AWS IAM Identity Center with an external identity provider then the nimbus dashboard will no longer be necessary since we would be managing identities with another provider. The dashboard for this project basically just handles onboarding and offboarding for aws users. If we had an external identity provider it would be unnecessary. The security policies that we use to enforce MFA and default deny access without it would need to remain in order to ensure best practices. The alerts would also need to stay for the same reason. Drift detection and the killswitch would also need to remain in order to make sure that users that are offboarded do not maintain access. There are a couple of risks with using an external provider, but the main one would be the fact that we would be relying on a third party that could be compromised. We can secure our own code and our own identity management applications but we'd have no control over how secure the third party providers infrastructure is.

## Q19 Why is a token rotation safe with no restart, and what would break if the services accepted only the current token?

A token rotation is safe with no restart because we are managing our secrets/tokens via AWS. Nothing is stored locally in the application because it is designed to dynamically retrieve the secret from secrets manager. The actual value of the secret doesn't matter it simply needs to be valid according to AWS. AWS cryptographically validates it's tokens and supports seamlessly transitioning/rotating them so that nothing fails due to a new token. Services need to accept the previous token temporarily so that they do not fail every time a token or secret is rotated. This is one of the benefits of using AWS secrets manager. If the services only accepted the current token then any application that relied on a token or a secret like a database, or something that needed s3 access would effectively stop functioning unless it was restarted with the new secret value.

## Q20. Which control would have prevented the incident, and which only limited it? Name one more free control you would add

For this scenario enforcing least privelages for IAM accounts would have completely mitigated the scenario. My lab user has a lot of permissions that it doesn't really need to have. This is what allowed it to create an access key for James. In a perfect world the lab user would have been configured to only have the permissions needed to deploy the infrastructure for the lab. Another potential control I could implement to reduce the impact of an incident like this is to make use of temporary credentials. This could limit the usefulness of any compromised keys because they would automatically become invalid after some time. I would add a control on the following action for the labuser: iam:CreateAccessKey. This would limit it's ability to create keys for other accounts.

## Q21 (explore). Mapping the drill to a framework

Map the steps of the G6 incident drill to techniques in the MITRE ATT&CK Cloud Matrix (for example persistence through additional cloud credentials). Then map three controls from this lab to a published control set such as the CIS AWS Foundations Benchmark or NIST SP800-53, and identify one requirement in that set which this lab does not meet.

## Q21 Answer

### Incident Drill Steps and Mapping

- Attacker gained access to labuser account: Mapped to Valid Accounts: Cloud Accounts. Initial Access.
- Attacker used the labuser account to create an access key for the legitimate james user: Mapped to Account Manipulation: Additional Cloud Credentials. Persistence.
- Alert for Risky IAM was received: Mapped to nothing (MITRE ATT&CK Cloud Matrix focuses on attacker techniqes not defensive actions)
- Investigation script was run and the malicious key was discovered: Mapped to nothing (MITRE ATT&CK Cloud Matrix focuses on attacker techniqes not defensive actions)
- The compromised James account was offboarded: Mapped to nothing (MITRE ATT&CK Cloud Matrix focuses on attacker techniqes not defensive actions)
- The malicious backdoor key was deleted: Mapped to nothing (MITRE ATT&CK Cloud Matrix focuses on attacker techniqes not defensive actions)
- A new replacement account was created for James: Mapped to nothing (MITRE ATT&CK Cloud Matrix focuses on attacker techniqes not defensive actions)
- Network access logs were reviewed: Mapped to nothing (MITRE ATT&CK Cloud Matrix focuses on attacker techniqes not defensive actions)

### Control Mappings

Selected Framework: AWS Foundational Security Best Practices (FSBP)

Selected Controls

- Nimbus Deny All
- Nimbus Require MFA
- BusinessTeamReadOnly

| FSBP Control | Requirement | Relevant Control/Policy |
| --- | --- | --- |
| **IAM.1** | IAM policies should not allow full administrative privileges (*) | Nimbus Deny All; BusinessTeamReadOnly |
| **IAM.2** | IAM users should not have IAM policies attached | All three compliant |
| **IAM.3** | IAM access keys should be rotated within 90 days | Not Shown |
| **IAM.5** | MFA enabled for IAM users with console passwords | Nimbus Require MFA |
| **IAM.7** | IAM password policies should have strong configurations | Nimbus Require MFA |
| **IAM.8** | Unused IAM user credentials should be removed | Not Shown |
| **IAM.9** | MFA enabled for the root user | Not Shown |
| **IAM.19** | MFA enabled for all IAM users | Nimbus Require MFA |
| **IAM.21** | Customer-managed policies should not allow wildcard service actions | BusinessTeamReadOnly |

### Unmet Requirement: IAM.7: IAM password policies should have strong configurations

The password policy in this lab does not really enforce strong passwords. It does enforce multifactor authentication but users are still free to set basically whatever password that they want after they login initially. A stronger password policy should be fefined for this lab that requires a specific length, complexity, and these passwords should also be rotated periodically.

## Q22. Complete the table in your own words: which limit do you hit first in each row, and what do you change?

Here is the completion for **Q22**, breaking down the first limit hit and the required changes for each concern as you scale beyond 100 users:

| Concern | First Limit Hit | What to Change |
| --- | --- | --- |
| **Permissions** | IAM user group limits or account user ceilings. | Switch from manually controlled IAM identities to a federated identity provider |
| **Registry (S3)** | S3 API performance and latency bottlenecks when listing thousands of objects on a refresh/reload. | Implement a database to store this information instead of relying exclusively on S3 |
| **Dashboard** | AWS IAM API rate limits and throttling. | Use IAM Credential Report and/or batched synchronization to mitigate API limits. |
| **Service Identity** | Container compromise (all containers are on the same host, so if one gets compromised then all of them are compromised.) | Use seperate EC2 instances for each service or implement ECS tasks. |
| **Sign In** | A large organization has multiple administrators, so there should be multiple admin accounts instead of a shared one | Use SSO to avoid making IAM users manually, and stop sharing one admin account. |
| **Logging** | CloudTrail stortage and retention limits might be an issue with a large organization | Send logs to a seperate logging account and implement a SIEM system to help manage analyze events. |

## Q23 (explore). Controls that even an administrator cannot remove

At company scale you add guardrails above the account. Choose three controls from this lab (for example the trail, the Deny All policy, Block PublicAccess) and write the Service Control Policy that would protect each one in an AWS Organization. What does
an SCP not protect against, and why is the management account treated differently?

## Q23 Answer

### Offboard SCP

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "OffboardedAccountKillSwitch",
      "Effect": "Deny",
      "NotAction": [
        "sts:AssumeRole"
      ],
      "Resource": "*"
    }
  ]
}
```

### Data Bucket Policy SCP

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EnforceTLSRequestsOnly",
      "Effect": "Deny",
      "Action": "s3:*",
      "Resource": "*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    },
    {
      "Sid": "EnforceMinimumTLSVersion",
      "Effect": "Deny",
      "Action": "s3:*",
      "Resource": "*",
      "Condition": {
        "NumericLessThan": {
          "s3:TlsVersion": "1.2"
        }
      }
    }
  ]
}
```

### Security Team Guardrails SCP

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ProtectCoreSecurityResources",
      "Effect": "Deny",
      "Action": [
        "iam:DeleteRole",
        "iam:DeleteRolePolicy",
        "iam:PutRolePolicy",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "cloudtrail:DeleteTrail",
        "cloudtrail:StopLogging",
        "guardduty:DeleteDetector"
      ],
      "Resource": "*",
      "Condition": {
        "ArnNotEquals": {
          "aws:PrincipalArn": [
            "arn:aws:iam::*:role/YourSecurityAdminRoleName"
          ]
        }
      }
    }
  ]
}
```
### What an SCP doesn't protect against

An SCP can limit the permissions that IAM users and roles have, but it cannot protect against the management account being compromised because SCP's do not affect the managment account. This is intentional because if a badly written SCP was attached to the management account then it could potentially lock out that account with no easy way of recovery. The management account must be treated differently because there has to be some kind of a failsafe if an administrator makes a mistake. AWS also reccomends alternative methods to securing management accounts such as strong multifactor authentication as well as hardware authentication.

## Q24 (explore). Can you trust the logs?

The cleanup script deletes the trail and the log bucket, but in a real company those logs are evidence. The trail has log file validation on. Explain what the digest files prove and how you would verify them with aws cloudtrail validate-logs. Then describe what an attacker with administrator rights could still do to your evidence in this lab, and how a separate log archive account, S3
Object Lock and MFA delete would change the answer.

## Q24 Answer

Digest files help prove the validity and integrity of the logs that were generated because they are hashed and chained together. The digest files prove that the logs are legitimate. The aws cloudtrail validate-logs command computes the hashes and verifies all of the signatures. I would use this command to check whether my logs are legitimate. An attacker with admin rights could potentially modify or even delete these logs because they are stored in an s3 bucket, so if the administrative account can modify s3 then the attacker could completely wipe the logs. Seperate logging accounts, s3 object lock, and MFA can help protect against this because they act as addional guardrails to a compromised administrator account. If the logs are in a seperate account then the attacker can't delete them because the compromised admin account doesn't have the permissions to access the logging accounts resources. An object lock can prevent objects in a bucket from being deleted because it overules an accounts permissions when it comes to deleting objects. Multifactor authentication helps defend the logs because it requires an additional form of authentication when logging in. This means that if an attacker has an administrators credentials they still will not be able to login and perfrom any actions. S3 buckets can also be configured to require multifactor authentication when trying to delete data.

Sources

https://docs.aws.amazon.com/IAM/latest/UserGuide/what-is-access-analyzer.html

https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html

https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html

https://docs.aws.amazon.com/AmazonECS/latest/developerguide/Welcome.html

https://docs.aws.amazon.com/guardduty/latest/ug/what-is-guardduty.html

https://docs.aws.amazon.com/acm/latest/userguide/acm-overview.html

https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers.html

https://attack.mitre.org/matrices/enterprise/cloud/

https://docs.aws.amazon.com/securityhub/latest/userguide/iam-controls.html

https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html

https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-log-file-validation-intro.html