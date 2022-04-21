#!/bin/bash
#
# In addition to verify-links.sh, this script additionally check anchors.
#
# See https://docs.npmjs.com/resolving-eacces-permissions-errors-when-installing-packages-globally if you meet permission problems when executing npm install.

ROOT=$(unset CDPATH && cd $(dirname "${BASH_SOURCE[0]}")/.. && pwd)
cd $ROOT

npm install remark-cli@9.0.0 remark-frontmatter
echo "info: checking front matter under $ROOT directory..."

remark --ignore-path .gitignore -u remark-frontmatter . --frail --quiet