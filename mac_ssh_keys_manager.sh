#!/bin/bash

# Name: mac_ssh_keys_manager.sh 
# Version: 0.1
# Author: drhdev
# Usage: Copy this script to your desired directory, e.g., ~/scripts/. 
# Make it executable with: chmod +x mac_ssh_keys_manager.sh - Run it with: ./mac_ssh_keys_manager.sh .

echo ""
echo "mac_ssh_keys_manager.sh  - Version 0.1 by DrHDev"
echo ""
echo "This script manages SSH key generation, transfer, and backup on a Mac."
echo ""

# Ensure the SSH directory exists
if [ ! -d ~/.ssh ]; then
    mkdir ~/.ssh
    chmod 700 ~/.ssh
fi

while true; do
    echo ""
    echo "Main Menu:"
    echo "1. Generate SSH Key"
    echo "2. Transfer SSH Key"
    echo "3. Backup SSH Keys"
    echo "4. Exit"
    echo ""
    read -p "Select an option: " choice

    case $choice in
        1) # Generation of the SSH key
            echo ""
            echo "Checking for existing SSH key pairs..."
            existing_keys=$(find ~/.ssh -type f -name '*.pub' -exec basename {} .pub \;)
            valid_keys=""
            for key in $existing_keys; do
                if [ -f "$HOME/.ssh/$key" ]; then
                    valid_keys+="$key\n"
                fi
            done
            if [ ! -z "$valid_keys" ]; then
                echo "Existing key pairs found:"
                echo -e "$valid_keys"
                echo "You can create a new key pair or return to the main menu."
            fi

            echo ""
            echo "Select type of key to generate or other options:"
            echo "1. RSA 4096 (default)"
            echo "2. ED25519"
            echo "3. Return to the main menu"
            echo ""
            read -p "Enter your choice: " key_type_choice

            case $key_type_choice in
                1|2)
                    if [ "$key_type_choice" -eq 1 ]; then
                        key_type="rsa -b 4096"
                        default_name="id_rsa"
                    else
                        key_type="ed25519"
                        default_name="id_ed25519"
                    fi
                    read -p "Enter filename ($default_name): " filename
                    filename="${filename:-$default_name}"
                    full_path="$HOME/.ssh/$filename"
                    if [ -f "$full_path" ]; then
                        echo "A key with filename $filename already exists."
                        echo "Options: 1. Overwrite 2. Backup and create new 3. Return to the main menu"
                        read -p "Select an option: " file_exists_choice
                        case $file_exists_choice in
                            1) rm -f "$full_path" "$full_path.pub" ;;
                            2)
                                backup_file="${filename}_backup_$(date +%Y%m%d%H%M%S)"
                                zip -j "$HOME/.ssh/${backup_file}.zip" "$full_path" "$full_path.pub"
                                mv "$full_path" "$HOME/.ssh/${filename}_backup_old"
                                mv "$full_path.pub" "$HOME/.ssh/${filename}_backup_old.pub"
                                ;;
                            3) continue ;;
                            *) echo "Invalid choice, returning to the main menu."
                               continue ;;
                        esac
                    fi

                    ssh-keygen -t $key_type -f "$full_path" -C "your_email@example.com"
                    if [ -z "$SSH_AUTH_SOCK" ]; then
                        eval "$(ssh-agent -s)"
                    fi
                    ssh-add -K "$full_path" >/dev/null 2>&1
                    echo "SSH key generated successfully at $full_path and added to SSH agent."
                    ;;
                3) continue ;;
                *) echo "Invalid option, returning to the main menu."
                   continue ;;
            esac
            ;;

        2) # Transfer of the SSH key
            echo ""
            echo "Select a public key for transfer and activation in SSH Config:"
            public_keys=$(find ~/.ssh -type f -name '*.pub' -exec basename {} \;)
            if [ -z "$public_keys" ]; then
                echo "No SSH public keys available. Please generate a key first."
                continue
            else
                echo "$public_keys"
                read -p "Enter the filename of the key to use: " selected_key
                if [[ -z $selected_key || ! -f ~/.ssh/$selected_key ]]; then
                    echo "Key does not exist, returning to the main menu."
                    continue
                fi
            fi

            echo "Selected key: $selected_key"
            read -p "Enter the server IP or hostname: " server_ip
            read -p "Enter the server username: " server_user

            if [[ -z $server_ip || -z $server_user ]]; then
                echo "Server IP or username cannot be empty. Returning to the main menu."
                continue
            fi

            if ssh-copy-id -i ~/.ssh/$selected_key ${server_user}@${server_ip}; then
                echo "Key has been successfully transferred."
            else
                echo "Failed to transfer the key. Check the server IP, username, or your network connection."
                continue
            fi

            # Update or create the SSH config file
            ssh_config_path="$HOME/.ssh/config"
            identity_file_path="$HOME/.ssh/${selected_key%.pub}" # Remove .pub extension

            if [ ! -f "$ssh_config_path" ]; then
                echo "# Default SSH Configuration" > "$ssh_config_path"
                echo "Host *" >> "$ssh_config_path"
                echo "    AddKeysToAgent yes" >> "$ssh_config_path"
                echo "    UseKeychain yes" >> "$ssh_config_path"
                echo "    IdentityFile $identity_file_path" >> "$ssh_config_path"
            else
                # Check if "Host *" block exists
                if grep -q "Host \*" "$ssh_config_path"; then
                    # Check for existing IdentityFile under "Host *"
                    if ! grep -q "IdentityFile $identity_file_path" "$ssh_config_path"; then
                        sed -i '' "/Host \*/a\\
    IdentityFile $identity_file_path" "$ssh_config_path"
                    fi
                else
                    # No "Host *" block exists, add it
                    echo "Host *" >> "$ssh_config_path"
                    echo "    AddKeysToAgent yes" >> "$ssh_config_path"
                    echo "    UseKeychain yes" >> "$ssh_config_path"
                    echo "    IdentityFile $identity_file_path" >> "$ssh_config_path"
                fi
            fi
            ;;

        3) # Backup of the keys
            echo ""
            echo "Select a SSH key pair for backup (or press Enter to backup all):"
            available_keys=($(find ~/.ssh -type f -name 'id_*' ! -name '*.pub' -exec basename {} \;))
            if [ ${#available_keys[@]} -eq 0 ]; then
                echo "No keys available for backup. Please generate a key first."
                continue
            else
                index=0
                declare -a keys
                for key in "${available_keys[@]}"; do
                    letter=$(echo "abcdefghijklmnopqrstuvwxyz" | cut -c $((index+1)))
                    echo "$letter) $key"
                    keys[index]=$key
                    ((index++))
                done
                echo "Press Enter to backup all SSH keys."
                echo ""
                read -p "Select a SSH key pair to backup by letter (or press Enter for all): " backup_choice

                if [[ -z $backup_choice ]]; then
                    for key in "${keys[@]}"; do
                        backup_file="${key}_backup_$(date +%Y%m%d%H%M%S).zip"
                        if [ ! -f "$HOME/.ssh/${key}.pub" ]; then
                            echo "Public key for $key is missing, backup will not proceed."
                            continue
                        fi
                        if zip -j "$HOME/Documents/$backup_file" "$HOME/.ssh/$key" "$HOME/.ssh/${key}.pub" >/dev/null 2>&1; then
                            echo "Backup created successfully at ~/Documents/$backup_file"
                        else
                            echo "Failed to create backup for $key. Please check permissions and available disk space."
                            continue
                        fi
                    done
                elif [[ "$backup_choice" =~ ^[a-z]$ && "${keys[backup_choice]}" ]]; then
                    key_index=$(( $(echo "$backup_choice" | tr -d '\n' | od -An -t uC) - 97 ))
                    key=${keys[key_index]}
                    backup_file="${key}_backup_$(date +%Y%m%d%H%M%S).zip"
                    if [ ! -f "$HOME/.ssh/${key}.pub" ]; then
                        echo "Public key for $key is missing, backup will not proceed."
                        continue
                    fi
                    if zip -j "$HOME/Documents/$backup_file" "$HOME/.ssh/$key" "$HOME/.ssh/${key}.pub" >/dev/null 2>&1; then
                        echo "Backup created successfully at ~/Documents/$backup_file"
                    else
                        echo "Failed to create backup. Please check permissions and available disk space."
                        continue
                    fi
                else
                    echo "Invalid choice, returning to the main menu."
                    continue
                fi
            fi
            ;;

        4) # Exit the script
            echo "Exiting..."
            exit 0
            ;;

        *) # Invalid choice
            echo "Invalid option. Please enter a number between 1 and 4."
            ;;
    esac
done
