#!/usr/bin/env bash
set -euo pipefail
# Scaffold-ETH often runs both hardhat + nextjs via workspaces; but our pages don't need hardhat now.
# You can run Next.js directly for speed.
cd packages/nextjs
yarn dev
