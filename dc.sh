#!/usr/bin/env bash

###############################################
# Function: Attempt to install dialog
###############################################
install_dialog() {
    echo
    echo "'dialog' is not installed."
    read -rp "Would you like to attempt to install dialog now? [y/N] " ans

    # Convert answer to lowercase
    ans=${ans,,}  # or use: ans=$(echo "$ans" | tr '[:upper:]' '[:lower:]')

    if [[ "$ans" == "y" || "$ans" == "yes" ]]; then
        # Detect if Debian/Ubuntu or RHEL/CentOS
        if [[ -f /etc/debian_version ]]; then
            echo "Detected a Debian/Ubuntu-based system."
            echo "Running: sudo apt-get update && sudo apt-get install -y dialog"
            sudo apt-get update
            sudo apt-get install -y dialog
        elif [[ -f /etc/redhat-release ]]; then
            echo "Detected a Red Hat-based system."
            echo "Running: sudo yum install -y dialog"
            sudo yum install -y dialog
        else
            echo "Could not detect a supported distro. Please install 'dialog' manually."
        fi

        # Double-check if dialog was installed successfully
        if ! command -v dialog &>/dev/null; then
            echo
            echo "It appears that 'dialog' is still not installed. Exiting."
            exit 1
        fi
    else
        echo "Skipping installation. Exiting."
        exit 1
    fi
}


# Check if dialog is installed
if ! command -v dialog &>/dev/null; then
    install_dialog
fi


#----------------------------------------
# SHARED: Select a container from a menu
#----------------------------------------
select_container() {
    local all_containers
    all_containers=$(docker ps -a --format '{{.ID}}::{{.Names}}::{{.Status}}')

    if [ -z "$all_containers" ]; then
        dialog --msgbox "No containers found." 7 40
        echo ""
        return
    fi

    local menu_options=()
    while IFS= read -r line; do
        local container_id container_name container_status
        container_id=$(awk -F'::' '{print $1}' <<< "$line")
        container_name=$(awk -F'::' '{print $2}' <<< "$line")
        container_status=$(awk -F'::' '{print $3}' <<< "$line")

        menu_options+=( "$container_id" "$container_name ($container_status)" )
    done <<< "$all_containers"

    local chosen
    chosen=$(dialog --clear \
                    --title "Select a Container" \
                    --backtitle "Docker Container Selection" \
                    --menu "Choose one:" 0 0 0 \
                    "${menu_options[@]}" \
                    2>&1 >/dev/tty)

    echo "$chosen"
}

#----------------------------------------
# FUNCTIONS
#----------------------------------------
# 1) List Containers
list_containers() {
    local containers
    containers=$(docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}")

    if [ -z "$containers" ]; then
        containers="No containers found."
    fi

    dialog --clear \
		   --no-collapse \
           --backtitle "Docker Manager" \
           --title "List of Docker Containers" \
           --msgbox "$containers" 30 100
}

# 2)Start Container
start_container() {
    local container_id
    container_id=$(select_container)
    if [ -n "$container_id" ]; then
        local output
        output=$(docker start "$container_id" 2>&1)
        dialog --clear \
               --backtitle "Start Docker Container" \
               --title "Result" \
               --msgbox "$output" 10 60
    fi
}

# 3) Stop Container
stop_container() {
    local container_id
    container_id=$(select_container)
    if [ -n "$container_id" ]; then
        local output
        output=$(docker stop "$container_id" 2>&1)
        dialog --clear \
               --backtitle "Stop Docker Container" \
               --title "Result" \
               --msgbox "$output" 10 60
    fi
}

# 4) Delete Container
remove_container() {
    local container_id
    container_id=$(select_container)
    if [ -n "$container_id" ]; then
        dialog --yesno "Are you sure you want to remove container '$container_id'?" 7 50
        if [ $? -eq 0 ]; then
            local output
            output=$(docker rm "$container_id" 2>&1)
            dialog --clear \
                   --backtitle "Remove Docker Container" \
                   --title "Result" \
                   --msgbox "$output" 10 60
        fi
    fi
}

# 5) Show container logs
show_logs() {
    local container
    container_id=$(select_container)
    if [ -n "$container_id" ]; then
        local logs
        logs=$(docker logs "$container_id" 2>&1)
        dialog --clear \
		       --no-collapse \
               --backtitle "Container Logs" \
               --title "Logs for $container" \
               --msgbox "$logs" 30 100
    fi
}


# 6) Show Docker history for an image
show_history() {
    local image
    image=$(dialog --clear \
                   --backtitle "Docker Image History" \
                   --title "Image Name or ID" \
                   --inputbox "Enter the Image Name or ID (e.g., ubuntu):" 8 50 \
                   2>&1 >/dev/tty)
    if [ -n "$image" ]; then
        local history
        history=$(docker history "$image" 2>&1)
        dialog --clear \
		       --no-collapse \
               --backtitle "Docker Image History" \
               --title "History: $image" \
               --msgbox "$history" 30 100
    fi
}
# 7) Show Docker system info
show_docker_info() {
    local info
    info=$(docker info 2>&1)
    dialog --clear \
	       --no-collapse \
           --backtitle "Docker System Info" \
           --title "docker info" \
           --msgbox "$info" 30 100
}

# 8) Show Docker images
show_images() {
    local images
    images=$(docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.CreatedSince}}\t{{.Size}}")

    if [ -z "$images" ]; then
        images="No images found."
    fi

    dialog --clear \
	       --no-collapse \
           --backtitle "Docker Images" \
           --title "List of Docker Images" \
           --msgbox "$images" 20 120
}

# Exec into a container with bash, not to be confused with famous "drop" command :-)
exec_into_container() {
    local container_id
    container_id=$(select_container)
    if [ -n "$container_id" ]; then
        # Actually exec into container with an interactive bash shell
        # This will bring you *out* of the dialog interface to the container shell.
		clear
		docker exec -it "$container_id" bash

    fi
}


#----------------------------------------
# MAIN MENU
#----------------------------------------
while true; do
    CHOICE=$(dialog --clear \
                    --backtitle "Docker Console Manager" \
                    --title "Main Menu" \
                    --menu "Use ↑↓ arrows to navigate, ENTER to select:" \
                    0 0 10 \
                    1 "List Docker Containers" \
					e "Exec into a Container" \
                    2 "Start a Container" \
                    3 "Stop a Container" \
                    4 "Remove a Container" \
                    5 "Show Container Logs" \
                    6 "Show Docker History (Image)" \
                    7 "Docker System Info" \
                    8 "Show Docker Images" \
                    x "Exit" \
                    2>&1 >/dev/tty)

    case "$CHOICE" in
        1) list_containers ;;
        2) start_container ;;
        3) stop_container ;;
        4) remove_container ;;
        5) show_logs ;;
        6) show_history ;;
        7) show_docker_info ;;
        8) show_images ;;
        e) exec_into_container ;;
        x|*) clear; exit 0 ;;
    esac
done