#!/bin/bash
set -e

cp -f /docker-entrypoint-initdb.d/files/postgresql.conf /var/lib/postgresql/data/postgresql.conf
