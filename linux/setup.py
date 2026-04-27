#!/usr/bin/env python3
import subprocess
import sys
import os
import shutil

# Your dynamic list mapping to the scripts inside the 'packages' folder
menu_list = [
    {"id": "1", "label": "Setup system essentials", "script": "essential.sh"},
    {"id": "2", "label": "Setup memory swap for server", "script": "swap.sh"},
    {"id": "3", "label": "Setup User disable Root", "script": "setup_user.sh"},
    {"id": "4", "label": "Setup Zsh", "script": "zsh.sh"},
    {"id": "5", "label": "Install docker server", "script": "docker.sh"},
    {"id": "6", "label": "Install bat", "script": "bat.sh"},
    {"id": "7", "label": "Install eza", "script": "eza.sh"},
    {"id": "8", "label": "Install rust", "script": "rust.sh"},
    {"id": "9", "label": "Install Helix Editor", "script": "helix.sh"},
    {"id": "10", "label": "Install Lazygit", "script": "lazygit.sh"},
    {"id": "11", "label": "Install Yazi", "script": "yazi.sh"},
    {"id": "11", "label": "Install Zoxide", "script": "zoxide.sh"},
    {"id": "12", "label": "Setup Symlinks system", "script": "symlink.sh"}
]

def check_os():
    """Checks if the current operating system is Debian or Ubuntu and has apt installed."""
    # 1. Ensure it is a Linux system
    if sys.platform != "linux":
        return False
        
    # 2. Check if the 'apt' package manager exists (Equivalent to `command -v apt`)
    if shutil.which("apt") is None:
        print("\n❌ This script requires the 'apt' package manager.")
        return False
        
    # 3. Verify it is specifically Debian or Ubuntu
    try:
        with open('/etc/os-release', 'r') as f:
            os_info = f.read().lower()
            if 'id=ubuntu' in os_info or 'id=debian' in os_info:
                return True
    except FileNotFoundError:
        pass
        
    return False

def execute_install_script(script_name):
    """Executes the shell script from the packages directory."""
    
    script_path = os.path.join("packages", script_name)
    
    if not os.path.exists(script_path):
        print(f"\n[ERROR] Could not find '{script_path}'. Make sure it exists in the packages directory.\n")
        return False # Return False so we know it failed

    try:
        print(f"\n>>> Executing: {script_path}...")
        subprocess.run(['bash', script_path], check=True)
        print(f">>> Successfully finished {script_name}!\n")
        return True # Return True so we know it succeeded
        
    except subprocess.CalledProcessError as e:
        print(f"\n[ERROR] The script {script_path} failed with exit code {e.returncode}.\n")
        return False

def main():
    try:
        while True:
            print("\n====================================")
            print("       LINUX SETUP UTILITY          ")
            print("====================================")
        
            for item in menu_list:
                print(f"{item['id']:>2}) {item['label']}")
            
            print("------------------------------------")
            print("99) Install Everything (Run All)")
            print(" 0) Exit")
            print("====================================")
        
            choice = input("Enter your choice: ")
        
            # Handle Exit
            if choice == '0':
                print("Exiting Setup. Goodbye!")
                sys.exit(0)
            
            # Handle "Run All"
            elif choice == '99':
                print("\n" + "="*30)
                print("   STARTING COMPLETE INSTALLATION   ")
                print("="*30)
            
                for item in menu_list:
                    execute_install_script(item['script'])
                
                print("\n>>> All tasks in the bulk installation have been processed!\n")
                continue # Skip the rest of the loop and show the menu again
            
            # Match choice to a single script
            selected_script = None
            for item in menu_list:
                if item['id'] == choice:
                    selected_script = item['script']
                    break 
                
            # Execute single script
            if selected_script:
                execute_install_script(selected_script)
            else:
                print(f"\n[!] Invalid choice '{choice}'. Please select a valid number from the menu.\n")

    # Catch the Ctrl+C interrupt gracefully
    except KeyboardInterrupt:
        print("\n\n[!] Setup interrupted by user (Ctrl+C). Exiting cleanly...")
        sys.exit(0)

if __name__ == "__main__":
    # Run the OS check before doing anything else
    if not check_os():
        print("\n[!] FATAL ERROR: This setup script is only designed for Debian and Ubuntu systems.")
        print("Execution aborted to prevent system damage.\n")
        sys.exit(1)
        
    main()
