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

Comparing the certificate by hand helps defend against man in the middle attacks. Since the certificate is self signed an attacker can simply generate their own and try to trick a user into entering sensitive data on a website that they control instead of the real site. Comparing the certificate protects against this because it allows me to make sure that I am connecting to the correct system. Most users skip verifying the certificate because it is tedious and they simply do not want to do it. Certificates from AWS Certificate Manager and with public certificate authorities are typically trusted by the browser, so a user does not have to verify it manually. HSTS adds an additional layer of security by preventing browsers from ever loading a resource over http. This prevents ssl stripping attacks. Certificate transparancy helps protect against scenarios where a valid/legit certificate was assigned to a malicious site by mistake. It essentially just adds another check/safety measure to certificates.

## Q15