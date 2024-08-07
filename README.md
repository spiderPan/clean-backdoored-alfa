# clean-backdoored-alfa

## Description

This is a script to clean up the known infected WordPress site from the Alfa backdoor. See [details](https://lukeleal.com/research/posts/backdoored-alfa-webshell/)

## Installation

```bash
git clone https://github.com/spiderPan/clean-backdoored-alfa.git
chmod +x clean-backdoored-alfa/*.sh
cd clean-backdoored-alfa
./find_suspicious.sh scan # scan only and show the infected files in /var/log/affected_files.log
./find_suspicious.sh delete # scan and delete
./verify_wp.sh # verify the WordPress installation
./reset_wp.sh # reset the WordPress installation
./delete_wp.sh # delete the affected files
```
