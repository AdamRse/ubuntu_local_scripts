PARSED_OPTIONS=$(getopt -o hmu --long help,mount,unmount,debug -- "${@}")

if [ $? -ne 0 ]; then
    eout "L'interpreteur de commande n'a pas fonctionné"
fi

eval set -- "${PARSED_OPTIONS}"

while true; do
    case "${1}" in
        -h|--help)
            usage
            ;;
        -m|--mont)
            MOUNT=true
            shift
            ;;
        -u|--unmount)
            MOUNT=false
            shift
            ;;
        --debug)
            DEBUG_MODE=true
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            eout "Erreur interne de parsing"
            ;;
    esac
done

usage(){
    echo "Usage : ${COMMAND_NAME} [OPTIONS]"
    echo ""
    echo "Options :"
    echo "    -h                        Afficher cette aide"
    echo "    -m,   --mount             Forcer le montage du NAS"
    echo "    -u,   --unmount           Forcer le démontage du NAS"
    echo "          --debug             Activer les logs de debug"
    exit 0
}