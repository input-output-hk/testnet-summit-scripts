# Instructions

1. Download the script for your OS
2. Run the script
3. Once it completes a shell will start with cardano-cli
4. When done, exit shell and the node will automatically exit

# What the script does

The script will download the binaries, a testnet snapshot database
directory and all configuration files. Provided are linux and mac scripts,
both for users with nix installed and users that don't have nix installed.

All files will be extracted in capstone-work directory making it easy to cleanup.
If the capstone-work directory exists, it will utilize the existing state so
it's possible to exit and restart the script at a later date.

The script waits for the node.socket to start, queries the tip endpoint until
the node is fully synced, and then drops into a shell with cardano-cli in the PATH.
