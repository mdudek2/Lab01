# 1. Can onboarding attach AdministratorAccess to a user? Expect: implicitDeny
aws iam simulate-principal-policy \
--policy-source-arn arn:aws:iam::337820988322:role/nimbus/nimbus-onboarding-svc \
--action-names iam:AttachUserPolicy \
--resource-arns arn:aws:iam::337820988322:user/nimbus/alice \
--context-entries "ContextKeyName=iam:PolicyARN,ContextKeyValues=arn:aws:iam::aws:policy/
AdministratorAccess,ContextKeyType=string" \
--query 'EvaluationResults[].[EvalActionName,EvalDecision]' --output table

# 2. Same action with the MFA guard policy. Expect: allowed
# Change ContextKeyValues to arn:aws:iam::ACCT:policy/nimbus/Nimbus-RequireMFA
aws iam simulate-principal-policy \
--policy-source-arn arn:aws:iam::337820988322:role/nimbus/nimbus-onboarding-svc \
--action-names iam:AttachUserPolicy \
--resource-arns arn:aws:iam::337820988322:user/nimbus/alice \
--context-entries "ContextKeyName=iam:PolicyARN,ContextKeyValues=arn:aws:iam::337820988322:policy/nimbus/Nimbus-RequireMFA,
ContextKeyType=string" \
--query 'EvaluationResults[].[EvalActionName,EvalDecision]' --output table

# 3. Can onboarding touch YOUR lab user? Expect: implicitDeny
# Change resource-arns to arn:aws:iam::ACCT:user/lab-user and action-names to iam:CreateLoginProfile
aws iam simulate-principal-policy \
--policy-source-arn arn:aws:iam::337820988322:role/nimbus/nimbus-onboarding-svc \
--action-names iam:CreateLoginProfile \
--resource-arns arn:aws:iam::337820988322:user/labuser \
--context-entries "ContextKeyName=iam:PolicyARN,ContextKeyValues=arn:aws:iam::aws:policy/
AdministratorAccess,ContextKeyType=string" \
--query 'EvaluationResults[].[EvalActionName,EvalDecision]' --output table