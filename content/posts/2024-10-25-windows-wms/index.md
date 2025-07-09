---
author: "ca4mi"
title: "Running Windows VMs using dockurr/windows"
date: "2024-10-25"
description: "How to use Docker VMs to run various Windows environments within a Linux-based OS, like Fedora. Sometimes need to access to different Windows versions (7, 10, 11) for testing or other office/work related purposes. Manually installing and managing these versions can be cumbersome. This solution leverages podman with podman-compose and the `dockurr/windows` image to streamline the process."
categories: ["Homelab"]
ShowToc: false
---

#### Sources
* https://youtu.be/xhGYobuG508 /Running Windows in a Docker Container! - Wolfgang's Channel/
* https://bobpony.com/downloads/ /Download ISO images/
* https://github.com/dockur/windows /Github repo/

#### docker-compose.yml example:

```yaml
version: '2.2' 
services:
  win7:
    image: dockurr/windows
    container_name: windows-7
    environment:
      RAM_SIZE: "2G"
      CPU_CORES: 1
      DISK_SIZE: "20G"
    devices:
      - /dev/kvm
    cap_add:
      - NET_ADMIN
    ports:
      - 8007:8006
      - 3387:3389/tcp
      - 3387:3389/udp
    volumes:
      - ./data-7:/storage:Z
      - /path/windows-7.iso:/custom.iso:Z
    stop_grace_period: 2m

  win10:
    image: dockurr/windows
    container_name: windows-10
    environment:
      RAM_SIZE: "4G"
      CPU_CORES: 2
      DISK_SIZE: "30G"
    devices:
      - /dev/kvm
    cap_add:
      - NET_ADMIN
    ports:
      - 8010:8006
      - 3310:3389/tcp
      - 3310:3389/udp
    volumes:
      - ./data-10:/storage:Z
      - /path/windows-10.iso:custom.iso:Z
    stop_grace_period: 2m

  win11:
    image: dockurr/windows
    container_name: windows-11
    environment:
      RAM_SIZE: "8G"
      CPU_CORES: 2
      DISK_SIZE: "50G"
    devices:
      - /dev/kvm
    cap_add:
      - NET_ADMIN
    ports:
      - 8011:8006
      - 3311:3389/tcp
      - 3311:3389/udp
    volumes:
      - ./data-11:/storage:Z
      - /path/windows-11.iso:/custom.iso:Z
    stop_grace_period: 2m  
```

**Explanation:**
This `docker-compose.yml` file defines three Windows VMs, each running a different OS (Windows 7, 10, and 11). The `dockurr/windows` image handles the automatic downloading and installation of the OS during runtime. However, this setup uses ISO images for each VM. Each VM's configuration specifies:

* **Resource Allocation:** RAM (`RAM_SIZE`), CPU cores (`CPU_CORES`), and disk space (`DISK_SIZE`)
* **Devices:** `/dev/kvm` is required for KVM virtualization.
* **Capabilities:**  `NET_ADMIN` allows network administration within the container.
* **Ports:** Different ports are mapped for each VM on the host machine to allow access to RDP (Remote Desktop Protocol). 
* **Volumes:** Volumes are used to persist data specific to each VM.
You can check each details from here: https://github.com/dockur/windows

#### Connecting to the VMs
Use `xfreerdp` to connect to the Windows VMs

```bash
xfreerdp /u:docker /p: /v:127.0.0.1:<tcp port> /clipboard
# for example:
xfreerdp /u:docker /p: /v:127.0.0.1:3387 /clipboard #win 7
xfreerdp /u:docker /p: /v:127.0.0.1:3310 /clipboard #win 10
xfreerdp /u:docker /p: /v:127.0.0.1:3311 /clipboard #win 11
# or
xfreerdp /u:docker /p:admin /v:127.0.0.1:3310 /clipboard /sec:tls /cert:ignore
# gpu passthrough
xfreerdp /v:192.168.99.2:3389 /w:1600 /h:900 /bpp:32 +clipboard +fonts /gdi:hw /rfx /rfx-mode:video /sound:sys:pulse +menu-anims +window-drag
```
