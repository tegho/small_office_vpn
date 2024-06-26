#!/bin/bash

current_dir=$(dirname $(realpath -ms $0))
package_dir=$(realpath "$current_dir/..")
package_name=$(basename "$package_dir")
source "$current_dir/vars" || exit 1
source "$current_dir/version" || exit 1

cd "$package_dir"
[ -d "$package_dir/debian" ] || exit 1
sed -i 's!^Depends: .*!Depends: '"$package_depends"'!' "$package_dir/debian/control"

#######################
cp "$current_dir/install" "$package_dir/debian"
#######################

debuild -i -us -uc -b
