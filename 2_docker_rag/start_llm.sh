#!/usr/bin/env bash

set -x 
source ./setenv.sh

sudo -E docker compose up -d
