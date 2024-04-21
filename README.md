# mac-ssh-keys-manager

## Overview
The `mac_ssh_keys_manager.sh` script is a comprehensive tool designed to simplify the management of SSH keys on macOS systems. It provides a menu-driven interface to facilitate the generation, transfer, and backup of SSH keys, making it an essential utility for developers and system administrators who frequently interact with secure remote servers.

## Features

- **Generate SSH Keys:** Offers the ability to create RSA 4096 or ED25519 keys, tailored to modern security standards.
- **Transfer SSH Keys:** Simplifies the process of securely transferring public keys to remote servers, ensuring ease of access without compromising security.
- **Backup SSH Keys:** Provides a reliable mechanism for backing up one or all of your SSH keys, safeguarding your access credentials.

## Getting Started

### Prerequisites
- Ensure you have macOS with Bash.
- SSH and `zip` utilities must be installed.

### Installation
1. Clone the repository or download the `mac_ssh_keys_manager.sh` script directly.
2. Move the script to a directory of your choice, such as `~/scripts/`.
3. Give executable permissions:
   ```bash
   chmod +x ~/scripts/mac_ssh_keys_manager.sh
   ```

### Running the Script
To start the script, navigate to the directory where it's stored and run:
```bash
./mac_ssh_keys_manager.sh
```
Follow the on-screen prompts to select the operation you wish to perform from the main menu.

## Detailed Usage Guide

### Generating an SSH Key
- Choose to generate a new key if none exist or if additional keys are needed.
- Select the type of key and optionally change the default filename.

### Transferring an SSH Key
- Select the public key file you wish to use for remote server authentication.
- Provide the remote server's IP address and username to establish a secure connection.

### Backing Up SSH Keys
- Choose to back up specific keys or all available keys.
- Backups are saved in a specified directory, ensuring they are readily available for recovery.

## Contributing
Contributions are welcome. Please fork the repository, make changes, and submit a pull request with an explanation of your modifications or additions.

## License
This script is distributed under the GNU General Public License v3.0. See the [LICENSE](LICENSE) file for more details.
