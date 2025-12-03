#!/bin/bash
set -euo pipefail
AWS_REGION=${AWS_REGION:-us-east-1}
SECRET_PREFIX=${SECRET_PREFIX:-smart-feedback}
ENV_ARG=${1:-}
if [ -z "$ENV_ARG" ]; then echo "usage: $0 [dev|uat|prod|all]"; exit 1; fi
push_env(){
  ENV_NAME=$1
  FILE="environment/$ENV_NAME.env"
  if [ ! -f "$FILE" ]; then
    ALT="environment/example.$ENV_NAME.env"
    [ -f "$ALT" ] || { echo "missing $FILE and $ALT"; exit 1; }
    FILE="$ALT"
  fi
  SECRET_NAME="$SECRET_PREFIX/$ENV_NAME"
  JSON=$(python - <<PY
import json
env_file="$FILE"
d={}
for line in open(env_file):
    line=line.strip()
    if not line or line.startswith('#'): continue
    if '=' not in line: continue
    k,v=line.split('=',1)
    d[k]=v
print(json.dumps(d))
PY
)
  aws secretsmanager describe-secret --region "$AWS_REGION" --secret-id "$SECRET_NAME" >/dev/null 2>&1 || aws secretsmanager create-secret --region "$AWS_REGION" --name "$SECRET_NAME" --secret-string "$JSON" >/dev/null
  aws secretsmanager put-secret-value --region "$AWS_REGION" --secret-id "$SECRET_NAME" --secret-string "$JSON" >/dev/null
  echo "$SECRET_NAME"
}
if [ "$ENV_ARG" = "all" ]; then
  push_env dev
  push_env uat
  push_env prod
else
  push_env "$ENV_ARG"
fi
