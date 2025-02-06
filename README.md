# Docker Container Bash Management Tool

A simple, menu-driven Bash script for basic Docker container management. This tool leverages the `dialog` utility to provide an interactive text-based user interface for managing Docker containers.

## Overview

This program is designed to be a basic Docker container management tool. It allows you to perform common Docker operations such as listing containers, starting/stopping containers, removing containers, viewing logs, checking image history, and more—all from a user-friendly menu.

You can rename the script to `dc` and place it in `/usr/local/bin/` so that you can simply run the command `dc` from anywhere on your system.

## Features

- **List Containers:** Display all running and stopped Docker containers.
- **Exec into a Container:** Open an interactive Bash shell inside a selected container.
- **Start Container:** Start a Docker container.
- **Stop Container:** Stop a running Docker container.
- **Remove Container:** Remove a Docker container after confirmation.
- **Show Container Logs:** View the logs of a selected container.
- **Show Docker Image History:** Display the history of a specific Docker image.
- **Docker System Info:** Get detailed information about the Docker system.
- **List Docker Images:** List all available Docker images.

## Prerequisites

- **Docker:** Make sure Docker is installed and running on your system.
- **dialog:** This utility is required to display the interactive menus.  
  The script includes a function to help install `dialog` if it is not already installed, but you can also install it manually:
  - On **Debian/Ubuntu**:
    ```bash
    sudo apt-get update && sudo apt-get install -y dialog
    ```
  - On **RHEL/CentOS**:
    ```bash
    sudo yum install -y dialog
    ```

## Installation

1. **Download the Script:**

   Clone or download the `dc.sh` script from your repository.

2. **Rename and Move the Script:**

   For system-wide usage, rename the script to `dc` (if desired) and move it to `/usr/local/bin/`:
   ```bash
   sudo mv dc.sh /usr/local/bin/dc
   sudo chmod +x /usr/local/bin/dc

