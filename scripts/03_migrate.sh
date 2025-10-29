#!/usr/bin/env bash
set -euo pipefail
cd packages/nextjs
# create a first migration
npx prisma migrate dev --name init
