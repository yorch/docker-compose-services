# Docker Registry v2 with UI and Auth

## Create users

To create users, the following command can be used:

```shell
./create-user.sh <username>
```

It will ask for the password and create the user in the file `data/auth/htpasswd`.
It will create the file if needed.
