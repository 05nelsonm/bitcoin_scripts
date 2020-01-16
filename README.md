Sovereignty Scripts  
=  
Scripts that make setting up & maintaining a Bitcoin full node on Ubuntu easier.  

This script will: 

- Install needed dependencies to run the package(s) & this script.
- Check for the latest version of specified package(s). If an update  
  is available, it will:  
 
  - Download the package(s).  
  - Verify PGP/sha256sum signatures of the package(s), when applicable.  
  - Install the package(s), when applicable.

## Highly Important Information  
It is **key** to verify the information contained in `scripts/project_info.sh`  
for correctness. I know they are correct, but it is in your best interest  
to practice the mantra of **don't trust, verify**. This is the file  
that contains all of the PGP information & download links.  

Urls to verify for yourself are provided as comments within the file.  

Here is the GitHub link to it, too:  

https://github.com/05nelsonm/sovereignty_scripts/blob/master/scripts/project_info.sh

## This Project's Roadmap
* [x] Coldcard Firmware
* [x] Coldcard Protocol
* [x] Wasabi Wallet
* [ ] Tor install & configuration
* [ ] Bitcoin Core
* [ ] Electrum Wallet
* [ ] Electrs
* [ ] Samourai Dojo
* [ ] c-lightning
* [ ] Ride The Lightning
* [ ] Lnd
* [ ] Zap-Desktop
* [ ] BTC Pay Server

## Testing  
These scripts have been tested on:  

- Ubuntu 18.04 Desktop  

## Getting Started
- Clone this repo  
- `cd sovereignty_scripts`  
- `./get_latest.sh` to display the help message for more info.  

Example command for retrieving & verifying the latest Coldcard Firmware:  

- `./get_latest.sh ckcc-firmware`


## Tor Settings  
Checkout the `.env` file to ensure the proper IP address & Port for Tor  
are set. Otherwise the script will automatically fall back to  
downloading over clearnet.  

Default setting is: `127.0.0.1:9050`  

## Help Message  
Running `./get_latest.sh` will show the following help message.  

```

This script downloads, verifies signatures of, & installs packages for you.

$ ./get_latest.sh [PACKAGE-NAME] [OPTION1] [OPTION2] ...

[PACKAGE-NAME]

    get-all .  .  .  .  . +  Cycles through all of the below listed
                          +  packages & updates/installs them.

    ckcc-firmware .  .  . +  Downloads the latest Coldcard firmware.
                          +
                          +  Running this will *ALWAYS* re-verify the
                          +  package for you if it already exists.

    ckcc-protocol .  .  . +  Installs the latest Coldcard protocol
                          +  (primarily needed for Electrum Wallet).

    wasabi-wallet .  .  . +  Installs the latest .deb package
                          +  of Wasabi Wallet.

[OPTIONS]

    --dry-run  .  .  .  . +  Will not install or delete downloaded
                          +  packages.
                          +
                          +  Can also be used just to download and
                          +  verify the latest package(s).

    --no-tor   .  .  .  . +  By default, if Tor is installed a
                          +  connectivity check will be performed.
                          +
                          +  If it passes, the script will download
                          +  things over Tor; if it fails, it falls
                          +  back to downloading things over clearnet.
                          +
                          +  Setting this option will skip the check
                          +  entirely & download things over clearnet.

    --only-tor    .  .  . +  Will *ONLY* use Tor to download packages.
                          +  If the connectivity check fails, the
                          +  script exits.
```
