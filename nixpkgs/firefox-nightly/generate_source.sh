#!/usr/bin/env sh
LOCALE="en-US"
ARCH=$(uname -m)
XML=$(curl -s https://aus4.mozilla.org/update/3/Firefox/1.0/0/Linux_$ARCH-gcc3/$LOCALE/nightly/0/default/default/update.xml?force=1)
VERSION=$(echo "$XML" | awk '/appVersion/ {print $4}' FS='"')
HASH=$(curl ftp://ftp.mozilla.org/pub/firefox/nightly/latest-mozilla-central/firefox-40.0a1.en-US.linux-$ARCH.checksums | grep "firefox-40.0a1.en-US.linux-$ARCH.tar.bz2" | grep "sha1" | cut -d" " -f1)
NIXHASH=$(nix-hash --type sha1 --to-base32 $HASH)
FILE="./source.nix"

cat > $FILE <<EOF
{
  version="$VERSION";
  sources= [
    { locale="$LOCALE"; arch="linux-$ARCH"; sha1="$NIXHASH"; }
  ];
}
EOF
