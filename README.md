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

Dalis is a collection of Arch Linux install scripts that serve 3 purposes:

1. Quickly format and reinstall Arch Linux on my own system. The various dalis scripts are found in the root of this repo.
1. Help others understand how to build their own scripts via commenting within each script.
1. Create [a cental 'awesome' collection](https://github.com/simpyll/dalis/tree/main/reference) of various arch linux scripts and install guides found around the web.

## Features 

The key feature that separates these implementations from others is that these scripts are built to be as 'hands off' as possible. There is no need to type in anything yourself, except for when you create a new root and/or user password when prompted. Even things like hostname and user are pre-assigned, so unless you want your hostname to be 'arch' and your user to be 'david' you will need to modify these. Other things to consider modifying are locals, keymap, timezone, language, etc.

There are 5 scripts to choose from:
1. <b>dalis.sh</b> - The standard basic install
1. <b>dalis-barebones.sh</b> - The absolute minimal install needed
1. <b>dalis-lvm.sh</b> - Root on a logical volume
1. <b>dalis-luks.sh</b> - Root encrypted
1. <b>dalis-lvm-luks.sh</b> - Root on a logical volume and encrypted

Note: Script endpoint is dictated by the ability to log in to terminal without iso. A successful install does not include a graphical environment or any other features.

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
