save_config_file() {
    xrandr --listmonitors > "$CONFIG_PREVIOUS"
}
read_config_file(){
    return $(cat "$HOME")
}