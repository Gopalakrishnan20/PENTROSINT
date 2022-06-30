# PENTROSINT ![Version](https://img.shields.io/badge/PENTROSINT-v1.0-blue) ![Support](https://img.shields.io/badge/Supported%20OS-Linux-red) ![License](https://img.shields.io/badge/Licence-GPL-green)
 PENTROSINT brings the user-friendly interface which can be accessible to a person with a basic amount of programming knowledge.
 
 There are three modules in PENTROSINT which are reconnaissance, web application scanning and Wi-Fi based attacks.

 In reconnaissance module information gathering techniques like social media hunting using image, Tracing single IP, IP Heat map, URL redirection checker, PDF metadata  analysis, URL lookup in WebPages, Information gathering using name, Phone number verifier and Open Source INTelligence for Instagram. 
 
 For Web Application scanning techniques like SQL Injection, Clickjacking, Host header injection, Sub domain Enumeration, Reverse IP, And finally

Wi-Fi attack modules embed De-authentication attack and Evil Twin Attack



<img src="https://user-images.githubusercontent.com/48313492/176611177-2661b269-edf8-466e-81aa-b8fa1c03916a.png" width="500">
<img src="https://user-images.githubusercontent.com/48313492/176610074-45d96e84-f1f2-4246-9957-7138895a6651.png" width="500">
<img src="https://user-images.githubusercontent.com/48313492/176611240-51e8cee5-33f2-4ea7-8e00-ce3881fec4ec.png" width="500">
<img src="https://user-images.githubusercontent.com/48313492/176611283-9a8bc38d-4671-4a86-aa43-551d5c10e3af.png" width="1000">

## Dependecies
- aircrack-ng
- mdk4
- xterm
- Python3
- Bash

## :book: How Wifipot works
* Scan for a target wireless network.
* Launch the `Handshake Snooper` attack.
* Capture a handshake (necessary for password verification).
* Launch `Captive Portal` attack.
* Spawns a rogue (fake) AP, imitating the original access point.
* Spawns a DNS server, redirecting all requests to the attacker's host running the captive portal.
* Spawns a web server, serving the captive portal which prompts users for their WPA/WPA2 key.
* Spawns a jammer, deauthenticating all clients from original AP and luring them to the rogue AP.
* All authentication attempts at the captive portal are checked against the handshake file captured earlier.
* The attack will automatically terminate once a correct key has been submitted.
* The key will be logged and clients will be allowed to reconnect to the target access point.
* For a guide to the `Captive Portal` attack, read the [Captive Portal attack guide](https://github.com/FluxionNetwork/fluxion/wiki/Captive-Portal-Attack)

## Osintgram usages
Osintgram offers an interactive shell to perform analysis on Instagram account of any users by its nickname. You can get:

```text
- addrs           Get all registered addressed by target photos
- captions        Get user's photos captions
- comments        Get total comments of target's posts
- followers       Get target followers
- followings      Get users followed by target
- fwersemail      Get email of target followers
- fwingsemail     Get email of users followed by target
- fwersnumber     Get phone number of target followers
- fwingsnumber    Get phone number of users followed by target
- hashtags        Get hashtags used by target
- info            Get target info
- likes           Get total likes of target's posts
- mediatype       Get user's posts type (photo or video)
- photodes        Get description of target's photos
- photos          Download user's photos in output folder
- propic          Download user's profile picture
- stories         Download user's stories  
- tagged          Get list of users tagged by target
- wcommented      Get a list of user who commented target's photos
- wtagged         Get a list of user who tagged target
```

## :heavy_exclamation_mark: Requirements
Wireless card support monitor mode and run as root.


## How to use
```
git clone https://github.com/Gopalakrishnan20/PENTROSINT
cd PENTROSINT
python3 PENTROSINT.py
```

## Tested on
OS
- Kali Linux 2020.4

Tester
- Me

## Disclaimer

* The usage of PENTROSINT for attacking infrastructures without prior mutual consent could be considered an illegal activity and is highly discouraged by its authors/developers. It is the end user's responsibility to obey all applicable local, state and federal laws. Authors assume no liability and are not responsible for any misuse or damage caused by this program.
