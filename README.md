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

If the shell can't prompt for your MFA code (for example Claude Code's `!`
prompt), pass it as the last argument:

```sh
aws_login admin 123456
```

### MFA code from 1Password

`aws_login_op [role]` (and `aws_admin_op`) read the one-time password from
1Password with `op`, so nothing is typed. Set once in your shell rc:

```sh
export LUTHER_OP_MFA_ITEM="Luther AWS - <you>"   # the item with your AWS OTP
export LUTHER_OP_MFA_VAULT="Employee"             # optional
# LUTHER_OP_ACCOUNT defaults to luthersystems.1password.com and is always
# passed to op, so it never prompts your other 1Password accounts.
```

AWS rejects a code that was already used, so back-to-back logins wait for the
next code (up to `LUTHER_OP_MFA_WAIT`, default 60 s).

