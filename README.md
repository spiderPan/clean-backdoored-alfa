# clean-backdoored-alfa

## Description

This is a script to clean up the known infected WordPress site from the Alfa backdoor. See [details](https://lukeleal.com/research/posts/backdoored-alfa-webshell/) 

## Installation

```bash
wget https://github.com/spiderPan/clean-backdoored-alfa/blob/main/scan_and_delete.sh
chmod +x scan_and_delete.sh

./scan_and_delete.sh scan # scan only and show the infected files in /var/log/affected_files.log
./scan_and_delete.sh delete # scan and delete
```
