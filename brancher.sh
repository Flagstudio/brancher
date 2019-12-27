#!/bin/bash

# Brancher
# https://github.com/Flagstudio/brancher

function brancher() {
    RED='\033[1;31m'
    GREEN='\033[1;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m' # No Color

    COLUMNS=12  
    ENV_FILE=".env"
    REQUIRED_APP_ENV="trash"

    # Check previous command error status
    check_command_exec_status () {
      if [[ $1 -eq 0 ]]
        then
          echo -e "${YELLOW}Success!${NC}"
          echo
      else
        echo -e "${RED}ERROR${NC}"
        echo
      fi
    }

    echo -e "Looking for ${ENV_FILE} in current directory..."
    if [ ! -f "$ENV_FILE" ]; then
        echo -e "${RED}${ENV_FILE} not found${NC}"
        return
    fi

    echo -e "Sourcing ${ENV_FILE} file..."
    source "$ENV_FILE"
    check_command_exec_status $?

    if [ "$APP_ENV" != "$REQUIRED_APP_ENV" ]; then
        echo -e "${RED}APP_ENV in ${ENV_FILE} should be ${REQUIRED_APP_ENV}. Current APP_ENV is ${APP_ENV}${NC}"
        return
    fi

    echo -e "Fetching data from remote..."
    git fetch
    check_command_exec_status $?

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
                echo -e "Working like a nigger..."
                git reset --hard origin/$branch
                composer install --quiet
                php artisan migrate:fresh --seed
                npm run --silent prod
                php artisan view:clear
                echo -e "${GREEN}branch changed${NC}"
                break
            else
                echo -e "${RED}fail${NC}"
            fi
        fi
    done
}
