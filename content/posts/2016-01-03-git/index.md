---
author: "ca4mi"
title: "Git"
date: "2016-01-03"
description: "Git"
ShowToc: true
TocOpen: true
---

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