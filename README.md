# Luther Shell Helpers

Shell scripts to help you manage AWS accounts.

## Set up speculate and AWS credentials with MFA

Install speculate:

```sh
go install github.com/akerl/speculate/v2@latest
```

Follow the instructions to install and use [aws-cred-setup](https://github.com/luthersystems/aws-cred-setup).

```sh
git clone git@github.com:luthersystems/luther-shell-helpers.git
```

source the helpers in `.bashrc` or `.zshrc`:

```sh
source ~/luther-shell-helpers/all.sh
```

## Update your AWS Accounts Map

Add your accounts and their aliases to `~/.aws/accounts`:
(replace with actual IDs).

```sh
# ALIAS        ACCOUNT
billing         <REPLACE>
root            <REPLACE>
platform-prod   <REPLACE>
platform-test   <RPLACE>
```

## Jump around

Login to your admin role, and jump to `admin` in another account:

```sh
aws_login admin
aws_jump platform-test admin
```
