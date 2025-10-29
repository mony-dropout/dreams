#!/usr/bin/env bash
set -euo pipefail
ROOT="$(pwd)"
NX="$ROOT/packages/nextjs"

echo ">> Install root deps"
yarn install

echo ">> Add nextjs-side deps"
cd "$NX"
yarn add @prisma/client prisma zod
yarn add openai @types/node
yarn add ethers
# If you want real EAS later: yarn add @ethereum-attestation-service/eas-sdk

echo ">> Generate Prisma client"
npx prisma generate
