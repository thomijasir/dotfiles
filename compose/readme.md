## Install Docker

```sh
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh ./get-docker.sh --dry-run
sudo sh get-docker.sh
```

## Select Compose Up File

docker compose -f custom-compose.yml up

## ADD Permission after installing

sudo usermod -aG docker $USER

## PGADMIN Error due to permission denied cannot create session

sudo chown -R 5050:5050 /data/compose

## Create Network

docker network create web_network
