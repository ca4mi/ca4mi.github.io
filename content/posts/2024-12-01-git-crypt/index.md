---
author: "ca4mi"
title: "Backing up obsidian notes using github & git-crypt"
date: "2024-12-01"
description: "Obsidian notes -> Push to github -> all notes will encrypted in github repo -> clone it -> import/export GPG keys -> unlock encrypted notes"
categories: ["Linux"]
ShowToc: false
TocOpen: false
---
Install:
```bash
# fedora
sudo dnf install git-crypt
# macos
brew install git-crypt
```

Get GPG Key
```bash
gpg --full-generate-key
# Choose RSA (1)
# Choose 4096 bits
# Choose how long the key should be valid
# Enter your name and email
gpg --list-keys --keyid-format LONG
```
Then export key and save it safe place:
```bash
# export keys
gpg --export-secret-key -a YOUR_EMAIL > private_key.asc
gpg --export -a YOUR_EMAIL > public_key.asc

# import *.asc keys to other devices
gpg --import private_key.asc
gpg --import public_key.asc
```

**In your obsidian notes directory**:
```bash
git init
echo "* filter=git-crypt diff=git-crypt" > .gitattributes
echo ".gitattributes !filter !diff" >> .gitattributes
echo ".gitignore !filter !diff" >> .gitattributes
git-crypt init
# # replace KEY_ID with actual key ID)
git-crypt add-gpg-user KEY_ID
```
Add github repo then push it.

`.gitattributes`:
Git-crypt encrypt everything in directory.
```
* filter=git-crypt diff=git-crypt
.gitattributes !filter !diff
.gitignore !filter !diff
```

**Useful commands**
```bash
# unlock/lock
git-crypt unlock
git-crypt lock
# verify
git-crypt status
# delete gpg key
gpg --delete-secret-key "KEYID"
gpg --delete-key "KEYID"
# check for existing keys
gpg --list-keys --keyid-format LONG
gpg --list-secret-keys --keyid-format LONG
```

**TL;DR**
```sh
git init
# vi .gitattributes and save it
* filter=git-crypt diff=git-crypt
.gitattributes !filter !diff
.gitignore !filter !diff

# git-crypt
git-crypt init
# copy long key from:
gpg --list-keys --keyid-format LONG

# replace long key <KEY_ID>
git-crypt add-gpg-user KEY_ID
git-crypt status
git add .
git commit -m "add git-crypt"
git push -u origin main
# after that add your note files
# then push it again to main repo
```