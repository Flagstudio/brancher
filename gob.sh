#!/bin/bash

RED='\033[1;31m'
GREEN='\033[1;32m'
NC='\033[0m' # No Color

COLUMNS=12  
ENV_FILE=.env
REQUIRED_APP_ENV="trash"

if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}${ENV_FILE} not found${NC}"
    return
fi

source "$ENV_FILE"

if [ "$APP_ENV" != "$REQUIRED_APP_ENV" ]; then
    echo -e "${RED}APP_ENV should equal ${REQUIRED_APP_ENV}. Current APP_ENV=${APP_ENV}${NC}"
    return
fi

git fetch
branches=()
eval "$(git for-each-ref --shell --format='branches+=(%(refname:strip=3))' refs/remotes/)"
branches+=('Exit')

PS3='Enter your choice: '
select branch in "${branches[@]}"
do
    if [ $REPLY -eq ${#branches[@]} ]; then
        break
    fi
    if [ $REPLY -gt ${#branches[@]} ] || [ $REPLY -lt 1 ]; then
        echo -e "${RED}invalid number${NC}"
    else
        git stash
        git checkout $branch
        if [ $? -eq 0 ]; then
            git reset --hard origin/$branch
            composer install --quiet
            php artisan migrate:fresh --seed
            npm run --silent prod
            pa view:clear
            echo -e "${GREEN}branch changed${NC}"
            break
        else
            echo -e "${RED}fail${NC}"
        fi
    fi
done
