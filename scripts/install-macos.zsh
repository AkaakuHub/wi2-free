#!/bin/zsh
set -euo pipefail

if pgrep -x wi2-agent >/dev/null; then
  print -u2 "Wi2Agentを終了してから、もう一度インストールしてください。"
  exit 1
fi

zsh scripts/build-macos.zsh
ditto macos/Wi2Agent/.build/Wi2Agent.app /Applications/Wi2Agent.app
codesign --verify --strict /Applications/Wi2Agent.app
open /Applications/Wi2Agent.app
