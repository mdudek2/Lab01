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

The onboarding role may add users to any group under the /nimbus/ path. If an attacker took over the onboarding service, which of your three groups would be the most valuable to join, and what could the new user then do? Compare a permissions boundary, a
Condition on the group name, and a Service Control Policy as ways to close this gap, and say which you would choose.

## Q4 Answer
