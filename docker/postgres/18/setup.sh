#!/bin/bash
set -e

cp -f /docker-entrypoint-initdb.d/files/postgresql.conf /var/lib/postgresql/18/docker/postgresql.conf
