#!/usr/bin/env bash

# save your env variables in .env file
source .env

# Initialization time. Failures during that  
# period will not be counted towards RETRIES
while [[ $START_PERIOD != 0 ]]; do
    echo "Checking if $POSTGRES_HOST service is ready in... $START_PERIOD"
    ((START_PERIOD--))
    sleep 1
done
echo "Trying to start $POSTGRES_HOST service container now..."

FAILURES=0
PASSED_TIME=0

# docker exec {container_name} psql -U {POSTGRES_USER} -c 'SELECT CURRENT_DATE;'
until docker exec $POSTGRES_USER psql -U $POSTGRES_USER -c 'SELECT CURRENT_DATE;'
    do
        until docker exec $POSTGRES_USER psql -U $POSTGRES_USER -c 'SELECT CURRENT_DATE;'
            do    
                if [ "${PASSED_TIME}" -gt "${TIMEOUT}" ]; then
                    ((FAILURES++))
                    PASSED_TIME=0
                    >&2 echo "Request timeout. Failures: $FAILURES/$RETRIES"
                    break
                fi
                sleep 1
                ((PASSED_TIME++))
            done

        if [ "${FAILURES}" -eq "${RETRIES}" ]; then
            >&2 echo "Postgres is unavailable!"
            exit 1
        fi

        sleep $INTERVAL
    done

>&2 echo "Postgres is up - Container is ready!"