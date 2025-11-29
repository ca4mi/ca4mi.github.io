---
author: "ca4mi"
title: "Hackintosh setup & apps"
date: "2024-10-12"
description: "Hackintosh"
categories: ["macOS"]
---

#### OS
You can check my OpenCore config from [here](https://github.com/ca4mi/open-core-config)

![MacOS - Overview](images/macos_info.png)

#### Hardware

| Parts | Name                                                                                         |
| ----- | -------------------------------------------------------------------------------------------- |
| MOBO  | Gigabyte GA-H61M-DS2V Rev 2.0                                                                |
| CPU   | Intel(R) Core(TM) i5-2300 (4) @ 2.80 GHz                                                     |
| GPU   | NVIDIA GeForce GTX 760 - 2GB                                                                 |
| PSU   | Cooler Master NEX N700                                                                       |
| SSD   | Kingston 240 GB  [TRIM](https://en.wikipedia.org/wiki/Trim_\(computing\)) Enabled via Kernel |
| RAM   | Envinda DDR3 1600 PCI-12800U-CL9 /only works 1333 MHz/                                       |

#### Apps
Install Homebrew:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Brew app list:

```bash
# formula
brew install syncthing

# cask
brew install --cask obsidian
brew install --cask kitty
```

Useful brew commands:
```bash
brew search <package_name> # search available packages 
brew update # update homebrew
brew list # list all packages
brew upgrade # upgrade packages
brew autoremove # remove unused dependencies
brew cleanup --prune=all # will cleanup
```

**Other Apps**
* Adobe Photoshop 2024
* Adobe Lightroom Classic 9.4
* Capture One 16.3
