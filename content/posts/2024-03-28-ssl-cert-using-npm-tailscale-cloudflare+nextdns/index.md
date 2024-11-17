---
author: "ca4mi"
title: "Tailscale VPN(mesh) + Cloudflare + NextDNS + Nignx Proxy Manager (Let's Encrypt) SSL certificate тохируулах"
date: "2024-03-28"
descript1ion: "Tailscale VPN(mesh) + Cloudflare + NextDNS + Nignx Proxy Manager (Let's Encrypt) SSL certificate тохируулах"
categories: ["Homelab"]
ShowToc: true
TocOpen: false
---

Note: Дээрх аргаас гадна өөр олон арга ашиглан vpn үүсгэх, тохируулах боломжтой.
### Domain худалдан авах
Энэ удаа hover.com-с domain аван тохируулга хийнэ. Нэвтрэн ороод авах гэж domain нэрээр хайлт хийнэ. Гарч ирсэн утгуудаас сонголт хийн худалдан авна. Domain, нэг жилдээ хямдхан, дараа жилээс үнэ нь 10 хэд дахин өсдөг тул сунгалт хийхэд үнийн өсөлт бага байхаар худалдан авалт хийгээрэй.
![Hover.com domain pick](images/20240325000838.png)
`hosono.space` нэртэй domain худалдан авлаа.
#### Domain DNS
hosono.space domain-н тохироо дах DNS хэсэгт доорх байдлаар тохируулга хийнэ:
![Hover.com domain DNS](images/20240325001442.png)

| TYPE  | HOST | VALUE                                | TTL        | ADDED BY |
| ----- | ---- | ------------------------------------ | ---------- | -------- |
| A     | *    | 216.40.34.41                         | 15 Minutes | Hover    |
| A     | @    | 216.40.34.41                         | 15 Minutes | Hover    |
| MX    | @    | 10 mx.hover.com.cust.hostedemail.com | 15 Minutes | Hover    |
| CNAME | mail | mail.hover.com.cust.hostedemail.com  | 15 Minutes | Hover    |

`MX`, `CNAME` тохируулга хийхгүй байж болно.

#### Domain Nameserver
Overview хэсэг дах Nameserver хэсэгт edit хийнэ
![Edit Nameserver](images/20240325004547.png)
`ridge.ns.cloudflare.com`, `tess.ns.cloudflare.com` оруулан save хийнэ.
### Cloudflare-д бүртгүүлэх & тохируулах
#### DNS Records
Cloudflare.com хаягаар орон бүртгэлгүй бол шинээр бүртгүүлнэ. Нэвтрэн ороод Websites хэсгээр орон `Add a site` дээр даран өмнө авсан domain нэрээ оруулаарай. `DNS` цэсээр орон Records бүртгэл хийнэ.
![Cloudflare add DNS records for domain](images/20240325003911.png)

| Type | Name         | Content      | Proxy Status | TLL  |
| ---- | ------------ | ------------ | ------------ | ---- |
| A    | *            | 216.40.34.41 | Proxied      | Auto |
| A    | hosono.space | 216.40.34.41 | Proxied      | Auto |
| A    | www          | 216.40.34.41 | Proxied      | Auto |

#### API Token авах
Overview цэсээс доошлуулаад харвал API гэсэн хэсэг байгаа Get your IP token дээр дарна.
![Cloudflare get API Token](images/20240325171509.png)

`Edit zone DNS` дэх use template -г сонгоно.
![Edit zone DNS](images/20240325174231.png)
Нэр, Permission, Zone Resources -г доорх зургийн дагуу тохируулаад `Contiune and summary` дарна.
![Edit zone DNS](images/20240325173045.png)
Permissions:
`Zone`, `DNS`, `Edit`
Zone Resources
`Include`, `All Zones`

Create Token дарна:
![Create Token](images/20240325174717.png)

`gjeuX3Jw8zXCCohha11N9zauX4y02XVx8ZrmY5Nt` token-гоо хуулж аваарай. Бусдад дамжуулах ил газар хуулаад хэрэггүй юм.
![Copy token](images/20240325174908.png)
Note: Жишээ энэ token-г устгасан болно. 

### Nignx Proxy Manager
#### NPM
NPM суулгах заавартай [энд](https://ca4mi.github.io/posts/2024-01-18-docker-thinkpadr500/) даран дэлгэрүүлэн үзнэ үү. Товчоор бол `docker-compose.yml` дотор жишээ нь:
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
```
суулгаад `localhost:81` -р хандан default creds хандалт хийнэ.

#### Let's Encrypt - Cloudflare
`SSL Certificates` ->  `Add SSL Certificate` -> `Let's Encrypt` сонгоно.
![Add SSL - Let's Encrypt](images/20240325180527.png)

| Талбар                          | Тайлбар                                                                    |
| ------------------------------- | -------------------------------------------------------------------------- |
| Domain Names                    | Эхэнд авсан domain-г бичин оруулна. `*.hosono.space` г.м                   |
| Email Address for Let's Encrypt | Certificates хугацаа дуусах үед мэдэгдэл авах мэйл хаяг бичин тохируулна   |
| Use a DNS Challenge             | Үүнийг чагтлах                                                             |
| DNS Provider                    | Cloudflare -г сонгоно                                                      |
| Credentials File Content        | Cloudflares-с авсан API token-г 1234 гэсэн тоон утгийн оронд солин оруулна |
| Propagation Seconds             | Хоосон орхиж болно                                                         |
| I Agree                         | Үүнийг чагтлах                                                             |

Credentials File Content:
```
dns_cloudflare_api_token = <Cloudflare API token байна>
```

#### Proxy Hosts
Add proxy hosts дээр даран жишээ нь jellyfin-г тохируулж буйг зургаас харна уу. Domain name хэсэгт хандах subdomain бичнэ. Scheme, IP, forward port-ууд тухайн container-н тохиргооноос хамааран өөр байна. Jellyfin-н default port: 8096, docker-compose дотор container name нь jellyfin ба compose нэг network-д тул container name-г хандалт хийж болох юм г.м.
![Proxy Hosts](images/20240328155401.png)

SSL цэсээр орон SSL Certificate талбарт өмнө үүсгэсэн `*.hosono.space` -г сонгоод `force SSL`, `HTTPS Support` сонгон save хийнэ.
![Proxy Hosts](images/20240328155453.png)

Энэ мэтээр proxy hosts тохируулах юм.

### Tailscale & NextDNS
[Tailscale](https://tailscale.com) бүртгэлгүй бол бүртгүүлээд сервер дээрээ [script](https://tailscale.com/kb/1347/installation) ашиглан суулгаад machine бүртгэл хийгээд approve хийсэн бол доорх зураг шиг харагдана.
![Tailscale dashbaord](images/20240328161357.png)

[NextDNS](https://nextdns.io) бүртгэлгүй бол бүртгүүлээд Endpoints хэсэг дэх ID хуулна. Tailscale-н dashbaord руу буцан ороод DNS цэсээр орон `Add nameserver` дээр даран `NextDNS`-г сонгоно. 
![Add nameserver](images/20240328163003.png)

Гарч ирсэн цонхонд NextDNS-н Endpoints хэсэг дэх ID-г оруулан save. Дараа нь `Override local DNS` -г on болгоно.
![NextDNS endpoints](images/20240328163200.png)

Үүний дараа NextDNS [тохиргоон](https://my.nextdns.io/) дах Settings хэсэг дах Rewrites-д `New rewrite` оруулна.
![NextDNS rewrites](images/20240328164037.png)
Domain талбарт `hosono.space`, Answer хэсэгт tailscale-н machine IP address оруулан save. Save хийсэн бол дараах байдалтай харагдана. 
![NextDNS rewrites sample](images/20240328164305.png)
Tailscale -г on болгоод `https://jellyfin.hosono.space` руу хандан, SSL Cert шалгавал:
![Shown SSL Cert on jellyfin](images/20240328160211.png)