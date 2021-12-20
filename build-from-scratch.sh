#!/usr/bin/env bash

set -eu -o pipefail

# Global settings

docker_root_dir=/var/lib/docker
storage_driver=overlay2
meta_path_dst_dir="$docker_root_dir/image/$storage_driver/imagedb/content/sha256"
last_updated_dst_dir="$docker_root_dir/image/$storage_driver/imagedb/metadata/sha256/"
repositories_path="$docker_root_dir/image/$storage_driver/repositories.json"

# Image Layer settings

meta_path_src="meta.json"
meta_json_compact="$(cat "$meta_path_src" | jq -c .)"
image_id="$(echo "$meta_json_compact" | sha256sum | cut -d " " -f 1)"

# Image layer creation
echo "$meta_json_compact" > "$meta_path_dst_dir/$image_id"
date +%Y-%m-%dT%H:%M:%S.%N%:z | tr -d '\n' > "$last_updated_dst_dir/lastUpdated"

# Add a tag to the layer

repository="localhost/buildtest"
tag="v7"

cat "$repositories_path" \
  | jq -c \
       --arg repository "$repository" \
       --arg tag "$tag" \
       --arg image_id "$image_id" \
       '. * {
              "Repositories": {
                ($repository): {
                  ($repository + ":" + $tag): ("sha256:" + $image_id)
                }
              }
            }' \
  > "$repositories_path.tmp"

mv "$repositories_path.tmp" "$repositories_path"

