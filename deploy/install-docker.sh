#!/bin/bash
set -e

env=$1
tag=$2
baseDir=/var/www/mawaqit
repoDir=$baseDir/repo
dockerContainer=mawaqit

cd $repoDir

docker exec $dockerContainer git fetch && git checkout $tag

echo "Creating symlinks"
docker exec $dockerContainer sh -c "(cd web && ln -snf robots.txt.$env robots.txt)"

echo "Set version"
docker exec $dockerContainer sed -i "s/version: .*/version: $tag/" app/config/parameters.yml

# Install vendors and assets
docker exec $dockerContainer sh -c "SYMFONY_ENV=prod composer install -on --no-dev"
docker exec $dockerContainer bin/console assets:install --env=prod --no-debug
docker exec $dockerContainer bin/console assetic:dump --env=prod --no-debug
docker exec $dockerContainer chmod -R 777 var/cache var/logs var/sessions

# backup DB if prod deploy
#if [ "$env" == "prod" ]; then
#    echo "Backup prod DB"
#    $baseDir/tools/dbBackup.sh
#fi

# Migrate DB
docker exec $dockerContainer bin/console doc:mig:mig -n --allow-no-migration -e prod

# Restart php
docker exec $dockerContainer kill -USR2 1

echo ""
echo "####################################################"
echo "The upgrade to $tag has been successfully done ;)"
echo "####################################################"