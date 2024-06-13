#!/usr/bin/env bash

function acre_env_file {
    ENVIRONMENT=$1
    if [[ -z "$ENVIRONMENT" ]]; then
        echo "please supply an environment name" >&2
        return 1
    fi
    env_file="$(find tests -iname "Acre-AWS${ENVIRONMENT}*.postman_environment.json")"
    if [[ -z "$env_file" ]]; then
        echo "unable to locate environment" >&2
        return 1
    fi
    echo "$env_file"
}

function acre_aws_api_key {
    ENVIRONMENT=$1
    if ! env_file="$(acre_env_file "$ENVIRONMENT")"; then
        return 1
    fi
    # shellcheck disable=2016
    secret_id="$(jq -r '.values[] | select(.key == "API_KEY").value' "$env_file" | sed 's/.*`\(.*\)`.*/\1/')"
    aws secretsmanager get-secret-value --region eu-west-2 --secret-id "$secret_id" | jq -r '.SecretString'
}

function acre_local_cookie {
    _acre_cookie 'http://localhost:8080' "$API_KEY"
}

function acre_aws_cookie {
    ENVIRONMENT=$1
    if ! api_key="$(acre_aws_api_key "$ENVIRONMENT")"; then
        return 1
    fi
    if ! env_file="$(acre_env_file "$ENVIRONMENT")"; then
        return 1
    fi
    if ! server="$(jq -r '.values[] | select(.key == "SERVER").value' "$env_file")"; then
        return 1
    fi
    url="https://${server}"
    _acre_cookie "$url" "$api_key"
}

function _acre_cookie {
    URL=$1
    if [[ -z "$URL" ]]; then
        echo "please supply an environment URL prefix" >&2
        return
    fi
    API_KEY=$2
    if [[ -z "$API_KEY" ]]; then
        echo "please supply an API key" >&2
        return
    fi
    claim='{"iss":"Luther Systems Test IDP","sub":"martin","aud":"luther"}'
    if ! id_token="$(curl --fail -X POST -H "X-API-Key: ${API_KEY}" --data "${claim}" -s "${URL}/test/fakeidp/token"  | jq -r '.token')"; then
        echo "error retrieving token" >&2
        return
    fi
    echo "authorization=${id_token}"
}
