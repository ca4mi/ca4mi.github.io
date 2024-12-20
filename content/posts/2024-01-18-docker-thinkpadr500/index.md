---
author: "ca4mi"
title: "Thinkpad R500-д Almalinux 8 OS + Docker + Nginx proxy manager + SSL certificate + DuckDNS"
date: "2024-01-18"
description: "Nginx Proxy Manager + DuckDNS + Containers"
categories: ["Homelab"]
ShowToc: true
TocOpen: true
---

#### OS
Almalinux 8.9 minimal [ISO](https://mirrors.almalinux.org/isos/x86_64/8.9.html) суулгасан. Суулгах явцад root-с тусад нь user үүсгэн wheel группд нэмсэн. 
```bash
# hostnamectl
         Icon name: computer-laptop
           Chassis: laptop
  Operating System: AlmaLinux 8.9 (Midnight Oncilla)
       CPE OS Name: cpe:/o:almalinux:almalinux:8::baseos
            Kernel: Linux 4.18.0-513.9.1.el8_9.x86_64
      Architecture: x86-64
# lshw
    vendor: LENOVO
    version: ThinkPad R500
    cpu: Celeron(R) Dual-Core CPU T3100 @ 1.90GHz
    ram: 8G DDR2 800MHz
```

#### Docker & docker compose
Суулгах
```bash
sudo dnf upgrade
sudo dnf install yum-utils

sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

sudo dnf install docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Complete бол сервис асаана
sudo systemctl start docker
sudo systemctl enable docker

# check version
docker --version
# Docker version 24.0.7, build afdd53b
docker-compose --version
# Docker Compose version v2.12.2
```
Compose ажиллахгүй бол энэ аргаар суулгана:
```bash
curl -L "https://github.com/docker/compose/releases/download/v2.12.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/bin/docker-compose

chmod +x /usr/bin/docker-compose
```
Non root user бол docker group үүсгээд sudo үүсгэх боломжтой болгоорой.
```bash
# Add alma user to wheel group
sudo usermod -aG wheel alma
# Add alma user to docker group
sudo usermod -aG docker alma

# groups
alma wheel docker
# id
uid=1000(alma) gid=1000(alma) groups=1000(alma),10(wheel),992(docker)
```
#### Docker compose
[nginxproxymanager](https://nginxproxymanager.com/), [nextcloud](https://nextcloud.com/), [homeassistant](https://www.home-assistant.io/), [jellyfin](https://jellyfin.org/), [odoo+postgres](https://github.com/bitnami/containers/blob/main/bitnami/odoo/docker-compose.yml), [navidrome](https://www.navidrome.org/) docker compose бүрдэнэ. Nginx proxy manager дээр HTTPS (Let's encrypt) авахад бас [DuckDNS](https://www.duckdns.org/) domain авахад ашиглана. Docker network-оо дундаа ашиглана. 3 port docker -с host руу 80, 81, 443 expose хийсэн.

```yml
version: '2.2' 
services:
  nginxproxymanager:
    image: 'jc21/nginx-proxy-manager:latest' 
    container_name: nginxproxymanager
    restart: unless-stopped 
    ports:
      - '80:80'
      - '81:81'
      - '443:443' 
    volumes:
      - ./nginx/data:/data
      - ./nginx/letsencrypt:/etc/letsencrypt
      # default cred: admin@example.com, changeme

  nextcloud:
    image: lscr.io/linuxserver/nextcloud:latest
    container_name: nextcloud
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Ulaanbaatar
    volumes:
      - ./nextcloud/appdata:/config 
      - ./nextcloud/data:/data
    restart: unless-stopped 

  homeassistant:
    image: lscr.io/linuxserver/homeassistant:latest
    container_name: homeassistant 
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Ulaanbaatar
    volumes:
      - ./hass/config:/config 
    restart: unless-stopped

  jellyfin:
    image: lscr.io/linuxserver/jellyfin:latest
    container_name: jellyfin 
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Ulaanbaatar
    volumes:
      - ./jellyfin/config:/config
      - ./jellyfin/tvshows:/data/tvshows
      - ./jellyfin/movies:/data/movies 
    restart: unless-stopped
    
  postgresql:
    image: docker.io/bitnami/postgresql:16
    container_name: postgresql
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Ulaanbaatar
      - ALLOW_EMPTY_PASSWORD=yes
      - POSTGRESQL_USERNAME=bn_odoo
      - POSTGRESQL_DATABASE=bitnami_odoo
    volumes:
      - ./postgresql/postgresql-persistence:/bitnami/postgresql
    restart: unless-stopped

  odoo:
    image: docker.io/bitnami/odoo:17
    container_name: odoo
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Ulaanbaatar
      - ALLOW_EMPTY_PASSWORD=yes
      - ODOO_DATABASE_HOST=postgresql
      - ODOO_DATABASE_PORT_NUMBER=5432
      - ODOO_DATABASE_USER=bn_odoo
      - ODOO_DATABASE_NAME=bitnami_odoo
    volumes:
      - ./odoo/odoo-persistence:/bitnami/odoo
    depends_on:
      - postgresql
    restart: unless-stopped
    # default cred: user@example.com, bitnami
```

Compose run:
```
docker-compose up -d
```

`docker ps`:
```bash
CONTAINER ID   IMAGE                                      COMMAND                  CREATED         STATUS                   PORTS                                                                                  NAMES
0f35e9aafd25   bitnami/odoo:17                            "/opt/bitnami/script…"   6 minutes ago   Up 6 minutes             3000/tcp, 8069/tcp, 8072/tcp                                                           odoo
91faa3c03087   lscr.io/linuxserver/homeassistant:latest   "/init"                  6 minutes ago   Up 6 minutes             8123/tcp                                                                               homeassistant
a2aa28911120   lscr.io/linuxserver/nextcloud:latest       "/init"                  6 minutes ago   Up 6 minutes             80/tcp, 443/tcp                                                                        nextcloud
89039950eded   bitnami/postgresql:16                      "/opt/bitnami/script…"   6 minutes ago   Up 6 minutes             5432/tcp                                                                               postgresql
a2c89d8405bf   jc21/nginx-proxy-manager:latest            "/init"                  6 minutes ago   Up 6 minutes             0.0.0.0:80-81->80-81/tcp, :::80-81->80-81/tcp, 0.0.0.0:443->443/tcp, :::443->443/tcp   nginxproxymanager
029423ea3e20   lscr.io/linuxserver/jellyfin:latest        "/init"                  6 minutes ago   Up 6 minutes             8096/tcp, 8920/tcp                                                                     jellyfin
```
#### Port нээх
docker expose хийсэн портуудыг хост талдаа нээнэ.
```bash
# Host port нээх
sudo firewall-cmd --zone=public --add-service=http --permanent
sudo firewall-cmd --zone=public --add-port 8080/tcp --permanent
# reload хийх
sudo firewall-cmd --reload
# port шалгах
sudo firewall-cmd --zone=public --list-ports
```

### Host-д persist хийгдсэн volume
```bash
#pwd
/home/alma/docker/compose
#ls -la -d * */*
-rw-rw-r--. 1 alma             alma 2022 Jan 18 00:59 docker-compose.yml
drwxr-xr-x. 3 root             root   20 Jan  6 01:49 hass
drwxr-xr-x. 8 alma             alma 4096 Jan 18 01:21 hass/config
drwxr-xr-x. 5 root             root   49 Jan  6 01:49 jellyfin
drwxr-xr-x. 6 alma             alma  179 Jan 16 09:28 jellyfin/config
drwxr-xr-x. 2 alma             alma 4096 Jan 14 07:43 jellyfin/movies
drwxr-xr-x. 4 alma             alma   54 Jan 14 07:43 jellyfin/tvshows
drwxr-xr-x. 4 root             root   33 Jan  6 01:49 nextcloud
drwxr-xr-x. 7 alma             alma   95 Jan  6 02:30 nextcloud/appdata
drwxrwx---. 5 alma             alma  158 Jan 18 06:30 nextcloud/data
drwxr-xr-x. 4 root             root   37 Jan  6 01:49 nginx
drwxr-xr-x. 7 root             root  137 Jan 18 06:02 nginx/data
drwxr-xr-x. 8 root             root  104 Jan 18 06:02 nginx/letsencrypt
drwxr-xr-x. 3 root             root   30 Jan 17 23:28 odoo
drwxrwxr-x. 5 systemd-coredump root   44 Jan 18 01:01 odoo/odoo-persistence
drwxr-xr-x. 3 root             root   36 Jan 18 00:54 postgresql
drwxr-xr-x. 3             1001 1001   18 Jan 18 00:58 postgresql/postgresql-persistence
drwxr-xr-x. 4 root             root   31 Mar  2 15:02 navidrome
drwxr-xr-x. 3 root             root   87 Mar  2 15:02 navidrome/data
drwxr-xr-x. 2 root             root    6 Mar  2 15:02 navidrome/music
```

non-root container-н хувьд permission алдаа заавал, жишээ нь postgresql:
```bash
sudo chown -R 1001:1001 postgresql/postgresql-persistence
```

Permission denied хийж байвал:
```bash
# jellyfin
sudo chown -R alma:alma movies
sudo chmod -R 755 movies #tvshows
```

### Nginx proxy manager
`http://server-ip:81` хандан default creds-р (`admin@example.com` pass: `changeme`) нэвтэрнэ. Дараа нь [DuckDNS](https://duckdns.org/) бүртгүүлээд sub domain (жишээ нь `hosono`.duckdns.org г.м) авна. `Current IP` хэсэгт host-н IP (192.168.1.200 г.м) save хийнэ дээд хэсэгт `token` -copy хийнэ.

Nginx proxy manager -> SSL Certificate -> Add Let's Encrypt Certificate ->  Let's Encrypt орон Domain Names хэсэгт DuckDNS авсан domain-аа (`*.hosono.duckdns.org` болон `hosono.duckdns.org`) оруулна. Email хэсэгт мэдэгдэл авах мэйл хаягаа оруулна. Use a DNS Challenge -г enable хийгээд `DuckDNS` сонгоод `dns_duckdns_token=өмнө copy хийсэн token-oo энд paste хийнэ`. Propagation Seconds хэсэгт `120` гэж бичээд save. Алдаа заавал дахин save хийнэ.

#### Proxy entry
`hosono.duckdns.org` -г `http://nginxproxymanager:81`
`jellyfin.hosono.duckdns.org` -г `http://jellyfin:8096` гэх мэтээр Certificate тохируулахад Proxy host-ууд бүртгэнэ. 

Domain Names хэсэгт бүртгэж буй sub domain-аа бичин, Scheme хэсэгт `http` `https` -с сонгоно. container талаас 443 default хийгдээгүй л бол ихэхндээ `http` -г сонгоно.  Forward Hostname / IP хэсэгт container name эсхүл 127.0.0.1 байж болно. 

SSL хэсэгт SSL Certificate -д бүртгэсэн DuckDNS -с сонгоод Force SSL, HTTP/2 Support гэдгийг сонгоод хадаглах юм. Энэ мэтээр subdomain -уудаа бүртгэнэ.

|SOURCE|DESTINATION|SSL|ACCESS|STATUS|
|---|---|---|---|---|
| home.hosono.duckdns.org | http://homeassistant:8123 | Let's Encrypt | Public | Online | 
| hosono.duckdns.org | http://nginxproxymanager:81 | Let's Encrypt | Public | Online | 
| jellyfin.hosono.duckdns.org | http://jellyfin:8096 | Let's Encrypt | Public | Online | 
| nextcloud.hosono.duckdns.org | https://nextcloud:443 | Let's Encrypt | Public | Online | 
| odoo.hosono.duckdns.org | http://odoo:8069 | Let's Encrypt | Public | Online | 

##### HA
http://homeassistant:8123 хувьд Proxy бүртгэх дээ Websockets Supports гэдгийг чагтлан өгнө. Дараа нь npm ажиллаж байгаа IP хаягийн мэдээллийг аван HASS дотор configuration.yml -г trusted_proxy хэсэгт npm нэмэн оруулна  

```bash
docker inspect nginxproxymanager
...
"IPAddress": "172.23.0.2"
...

# /home/user/docker/compose/hass/config
vi configuration.yaml
...
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 172.23.0.0/24
  # - 172.23.0.5
...
```

configuration.yaml save хийгээд homeassistant restart хийнэ:
```bash
docker restart homeassistant
```

### Watchtower
Гараар container-ууд update хийнэ. 
/Docker-compose дотор байнга ажилладаг байхаар тохируулж бас болно/
```bash
docker run -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower --run-once
```

### Bookmarks
- https://youtu.be/qlcVx-k-02E
- https://notthebe.ee/blog/easy-ssl-in-homelab-dns01/
- https://github.com/bitnami/containers/tree/main/bitnami/odoo#configuration
- https://linux.how2shout.com/how-to-open-or-close-ports-in-almalinux-8-or-rocky-firewall/
- https://techoverflow.net/2020/01/28/how-to-fix-bitnami-mariadb-mkdir-cannot-create-directory-bitnami-mariadb-permission-denied/
- https://github.com/containrrr/watchtower/discussions/901
- https://containrrr.dev/watchtower/
- https://github.com/navidrome/navidrome
