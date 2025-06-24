---
author: "ca4mi"
title: "Git"
date: "2016-01-03"
description: "Git"
ShowToc: true
TocOpen: true
---
### Option 1
Терминал дээр шалгах
```bash
ssh -T git@github.com
```
`Permission denied (public key).` буцааж байвал:

```bash
ssh-keygen -t rsa -b 4096 -C "email_or_github_mail@email.com"
```

Mac дээр:
```bash
cat ~/.ssh/id_rsa.pub | pbcopy
```

Linux дээр:
```bash
cat ~/.ssh/id_rsa.pub | xclip -sel clip
```
copy хийсэн.

Github тохиргоо орон SSH [нэмэх](https://github.com/settings/keys)
SSH Key нэмсэн бол терминал дээр:
```bash
ssh -T git@github.com
```

```bash
git config --global user.email "you@example.com"
git config --global user.name "Your Name"
```

### Option 2
SSH key within a subdirectory

```sh
mkdir -p ~/.ssh/git
ssh-keygen -t ed25519 -C "email_or_github_mail@email.com" -f ~/.ssh/git/github
cat ~/.ssh/git/github.pub | xclip -sel clip
```
Add key to Github[key](https://github.com/settings/keys)

```sh
# create config 
vi ~/.ssh/config
# add
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/git/github
```
Test connection

```sh
ssh -T git@github.com
```

### Option 3
Add existing key
```sh
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/<key_name>
# Identity added: ...
# add <key_name>.pub key to github and check to connection
ssh -T git@github.com
```
