#!/bin/bash

# Using util_functions.sh
[ -f "util_functions.sh" ] && . ./util_functions.sh || { echo "util_functions.sh not found" && exit 1; }

# Load data from script base path if no directory were specified
[ -n "$1" ] && dir=$1 || {
	for dir in ./*; do      # List directory ./*
		if [ -d "$dir" ]; then # Check if it is a directory
			dir=${dir%*/}         # Remove last /
			print_message "Processing \"${dir##*/}\"" debug

			# Build system.prop
			./"${BASH_SOURCE[0]}" "$dir"
		fi
	done
	exit 1
}

vendor_path="$dir/extracted/vendor/build.prop"
system_path="$dir/extracted/system/system/build.prop"

device_name=$(grep_prop "ro.product.vendor.model" "$vendor_path")
device_build_id=$(grep_prop "ro.build.id" "$system_path")
device_code_name=$(grep_prop "ro.product.vendor.name" "$vendor_path")
device_code_name_title=${device_code_name^}
device_build_android_version=$(grep_prop "ro.vendor.build.version.release" "$vendor_path")
device_build_security_patch=$(grep_prop "ro.vendor.build.security_patch" "$vendor_path")

mkdir -p result

base_name=$device_code_name_title.A$device_build_android_version.$(echo "$device_build_security_patch" | sed 's/-//g')
subdir=$(basename "$dir")

mkdir -p "result/$subdir"
ls -la $dir
cp $dir/{module,system}.prop "result/$subdir/"
cp -r ./magisk_module_files/* "result/$subdir/"

cd "result/$subdir" || exit 1
zip -r "../../$base_name.zip" .
cd ../..

print_message "Module saved to $base_name.zip" info

# IMPORTANT: This will save the latest build's (last directory the shell loops thru) base name
# This won't be a problem for GitHub Actions as we have different instances running for each build
if [ -n "$GITHUB_OUTPUT" ]; then
	{
		echo "module_base_name=$base_name" ;
		echo "module_hash=$(sha256sum "$base_name.zip" | awk '{print $1}')";
		echo "device_name=$device_name";
		echo "device_code_name_title=$device_code_name_title";
		echo "device_build_id=$device_build_id";
		echo "device_build_android_version=$device_build_android_version";
		echo "device_build_security_patch=$device_build_security_patch";
	} >> "$GITHUB_OUTPUT"
fi
