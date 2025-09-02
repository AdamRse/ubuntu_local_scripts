#!/bin/bash

source ./.env
source ./utils/global/nas_fct.sh

# if [ -n "$1" ]; then
#     unmount_nas
# else
#     mount_nas
# fi

test_alias_token="1Ahc6Zal41-#"
echo "TEST_ALIAS='$test_alias_token'" >> "$BASH_ALIASES"
source "$HOME/.bashrc"
echo "$TEST_ALIAS --- $test_alias_token"
if [ "$TEST_ALIAS" != "$test_alias_token" ]; then
    echo "Token non trouvé..."
else
    echo "TOKEN TROUVE !"
fi
if [ "$TEST_ALIAS" == "$test_alias_token" ]; then
    echo "TOKEN TROUVE !"
else
    echo "Token non trouvé..."
fi
sed -i "/TEST_ALIAS/d" "$BASH_ALIASES"