<h2 align="center">
DALIS
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

Dalis is a collection of Arch Linux install scripts that serve 2 purposes:

1. Quickly format and reinstall Arch Linux on my own system.
1. Help others understand how to build their own scripts via through commenting within each script.

## Features 

The key feature that separates these implementations from others is that these are complete scipts. There is no need to type in anything yourself, except for when you create new root and/or user passwords when prompted. 

There are 5 scripts to choose from:
1. <b>dalis.sh</b> - The standard basic install
1. <b>dalis-barebones.sh</b> - The absolute minimal install needed
1. <b>dalis-lvm.sh</b> - Root on a logical volume
1. <b>dalis-luks.sh</b> - Root encrypted
1. <b>dalis-lvm-luks.sh</b> - Root on a logical volume and encrypted

- Script endpoint means able to log in to terminal without iso. 'Install' does not mean graphical environment.

## Status 

1. <b>dalis.sh</b> - Broken
1. <b>dalis-barebones.sh</b> - Broken
1. <b>dalis-lvm.sh</b> - Broken
1. <b>dalis-luks.sh</b> - Broken
1. <b>dalis-lvm-luks.sh</b> - Broken


## Download

```
curl -LO raw.githubusercontent.com/simpyll/dalis/main/dalis.bash
```

## Installation

```
sh dalis.bash
```

## Structure 

- Main Scrpts in project root 
- /resources is a collection of scripts and guides found around the web (mostly GitHub)
- /docs is a collection of various notes on specific install topics (i.e. Connecting to the internet or creating locales)

## Roadmap 

1. Get scripts functioning seamlessly 
1. Comment each line of code to describe it's function.

## License

MIT
