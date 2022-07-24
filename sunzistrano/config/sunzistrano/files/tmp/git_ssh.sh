#!/bin/sh -e
exec /usr/bin/env ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no "$@"
