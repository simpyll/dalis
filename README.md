<h2 align="center">
DALIS Testing
</h2>
<p align="center">
David's Arch Linux Install Scripts
</p>

<p align="center">
<b><a href="#overview">Overview</a></b>
|
<b><a href="#features">Features</a></b>
|
<b><a href="#status">Status</a></b>
|
<b><a href="#download">Download</a></b>
|
<b><a href="#installation">Installation</a></b>
|
<b><a href="#structure">Structure</a></b>
|
<b><a href="#structure">Structure</a></b>
|
<b><a href="#roadmap">Roadmap</a></b>
|
<b><a href="#license">License</a></b>
</p>


## Overview 

Dalis is a collection of Arch Linux install scripts that focus on hardening and security.

Guides used to build these scripts include: [Official Arch Security Guide](https://wiki.archlinux.org/title/security) and [The linux hardening guide](https://theprivacyguide1.github.io/linux_hardening_guide)

## Features 

- lvm on luks
- nftables
- Wayland

## Status 

1. <b>dalis.sh</b> - Working
1. <b>basic-config.sh</b> - Working
1. <b>dalis-lvm.sh</b> - Broken
1. <b>dalis-luks.sh</b> - Broken
1. <b>dalis-lvm-luks.sh</b> - Broken


## Download

curl the raw script of your choice to the root terminal of your iso.

Example:

```
curl -LO raw.githubusercontent.com/simpyll/dalis/main/dalis.bash
```

## Installation

Example:

```
sh dalis.bash
```

## Structure 

- Main Scrpts are in project root 
- /resources is a collection of scripts and guides found around the web (mostly GitHub)
- /docs is a collection of various notes on specific install topics (i.e. Connecting to the internet or creating locales)

## Roadmap 

1. Get scripts functioning seamlessly.
1. Comment each line of code to describe it's function.
1. Add to and standardize the resource folder.

## License

[MIT](https://github.com/simpyll/dalis/blob/main/LICENSE)
