#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
TZ='UTC'; export TZ

set -euo pipefail

rm -fr ~/.node_repl_history
rm -fr ~/.npm
rm -fr ~/.npmrc
rm -fr /tmp/node*

_tmp_dir="$(mktemp -d)"
cd "${_tmp_dir}"

# https://nodejs.org/dist/v24.13.0/node-v24.13.0-linux-x64.tar.xz
_nodejs_lts_ver="$(wget -qO- 'https://nodejs.org/en/download' | sed 's/"/\n/g' | grep '(LTS)' | sed 's/[<>]/\n/g' | grep '(LTS)' | grep -i '^v' | sed 's/^[Vv]//g; s/ (.*//g' | sort -V | tail -n1)"
wget -q -c -t 9 -T 9 "https://nodejs.org/dist/v${_nodejs_lts_ver}/node-v${_nodejs_lts_ver}-linux-x64.tar.xz"
/bin/ls -lah
tar -xof node-*.tar*
sleep 1
rm -f node-*.tar*
cd node-*
ln -sv node_modules lib/node

echo '# nodejs
NODEJS_HOME='\''/opt/node'\''
export NODEJS_HOME
PATH=$NODEJS_HOME/bin:$PATH
export PATH' > .env
chmod 0644 .env

cd ..

rm -fr /opt/node*
mv node-* /opt/node

# nodejs
NODEJS_HOME='/opt/node'
export NODEJS_HOME
PATH=$NODEJS_HOME/bin:$PATH
export PATH

/opt/node/bin/npm ls -g

_orig_npm_ver="$(/opt/node/bin/npm -v)"
_new_npm_ver="$(wget -qO- 'https://github.com/npm/cli/tags/' | grep -i '<a href="/npm/cli/releases/tag/v' | sed 's|.*<a href="/npm/cli/releases/tag/v||g' | sed 's/".*//g' | sort -V | uniq | tail -n 1)"
if [[ -z "${_new_npm_ver}" ]]; then
    echo ' null _new_npm_ver'
    exit 1
fi

if [ "$(printf '%s\n' "${_orig_npm_ver}" "${_new_npm_ver}" | sort -V | tail -n1)" = "${_new_npm_ver}" ]; then
    /opt/node/bin/npm install -g npm@"${_new_npm_ver}"
    echo
    sleep 1
    _new_npm_ver="$(/opt/node/bin/npm -v)"
    echo "old npm version: ${_orig_npm_ver}"
    echo "new npm version: ${_new_npm_ver}"
fi

# OpenAI Codex
/opt/node/bin/npm install -g @openai/codex@latest
sleep 5
# OpenCode
/opt/node/bin/npm install -g opencode-ai@latest
sleep 5
/opt/node/bin/node -p process.versions
/opt/node/bin/npm version
/opt/node/bin/npm ls -g

/bin/ls -la /opt/node/bin/
/bin/ls -la /opt/node/lib/
/bin/ls -la /opt/node/lib/node_modules/

cd /opt
mv node "node-v${_nodejs_lts_ver}-linux-x64"

#tar -Jcf /tmp/"node-v${_nodejs_lts_ver}-linux-x64.tar.xz" "node-v${_nodejs_lts_ver}-linux-x64"
#tar -cf - "node-v${_nodejs_lts_ver}-linux-x64" | zstd -f -12 -o /tmp/"node-v${_nodejs_lts_ver}-linux-x64.tar.zst"

tar -cf /tmp/"node-v${_nodejs_lts_ver}-linux-x64.tar" "node-v${_nodejs_lts_ver}-linux-x64"
cd /tmp
sleep 1
xz -f -z -9 -k -T$(($(nproc) - 1)) "node-v${_nodejs_lts_ver}-linux-x64.tar"
###zstd -f -9 -k -o "node-v${_nodejs_lts_ver}-linux-x64.tar".zst "node-v${_nodejs_lts_ver}-linux-x64.tar"
sleep 1
sha256sum -b "node-v${_nodejs_lts_ver}-linux-x64.tar".xz > "node-v${_nodejs_lts_ver}-linux-x64.tar".xz.sha256

rm -f node-*.tar
rm -fr /tmp/_output_lts
mkdir /tmp/_output_lts
mv node-*.tar.* /tmp/_output_lts/
/bin/ls -lh /tmp/_output_lts/

cd /tmp
rm -fr "${_tmp_dir}"
rm -fr ~/.node_repl_history
rm -fr ~/.npm
rm -fr ~/.npmrc
rm -fr /tmp/node*

echo
echo ' done'
echo
exit
