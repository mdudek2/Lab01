# Questions for Lab01

## Q1 (explore). Tests as security controls

Your tests state security facts that must stay true, such as the
launch script never opening port 22 and the onboarding role attaching only the MFA guard. Explain where in a
delivery pipeline you would run them so that a bad change cannot reach production, and name two kinds of
problem they cannot catch. Compare them with policy as code and analysis tools (for example IAM Access
Analyzer policy validation, cfn-guard or Open Policy Agent) and with a secret scanner like the credential
check in create_repo.sh.

## Answer

Tests would typically be run before pushing from a test environment to a production environment. This is because they are designed to catch problems before they are pushed to production. Unit tests are typically run automatically when code is pushed to a development repository. Integration tests would typically be run in a dedicated testing environment only after unit tests succeed/pass. Unit tests and integration tests are mostly designed to test an applications functionality and cannot catch all problems. For example, unit and integration tests would not be able to detect security misconfigurations and overly permissive security polciies, nor would they be able to detect/stop configuration drift due to an error in the deployment process.

Policy as code and analysis tools are designed to stop different problems than unit/integration tests. For example, tools such as AWS IAM Access Analyzer and Open Policy Agent are able to examine polcies to determine if they are overly permissive or insecure as well as stop insecure deployments from running. Unit and integration tests are also generally not designed to stop secrets from being accidentaly pushed to production. This would typically be done via a .gitignore file and via credential checks in deployment scripts. The create_repo.sh script in this repository does this via the grep command and will refuse to commit anything if it detects something like a private key.
