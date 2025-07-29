# SetUp SSH for multiple keys

This section provides an example of an SSH configuration file and a `git clone` command using different SSH identities.

## SSH Configuration

The following SSH configuration can be added to the `.ssh/config` file:

```
Host github-work
HostName github.com
IdentityFile ~/.ssh/id_rsa

Host github-personal
HostName github.com
IdentityFile ~/.ssh/id_rsa_personal
```

Make sure to replace `~/.ssh/id_rsa` and `~/.ssh/id_rsa_personal` with the actual paths to your SSH private key files.

## Git Clone

To clone a repository using the specified SSH identities, use the following `git clone` command:

```
git clone git@github-personal:lvalencia1286/tutorials.git
```


Replace `lvalencia1286` with your GitHub username and `tutorials.git` with the name of the repository you want to clone.

Make sure you have the necessary permissions to access the repository with the specified SSH key.
