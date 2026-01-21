PARSED_OPTIONS=$(getopt -o h --long help,debug -- "${@}")

if [ $? -ne 0 ]; then
    eout "L'interpreteur de commande n'a pas fonctionné"
fi

eval set -- "${PARSED_OPTIONS}"

while true; do
    case "${1}" in
        -h|--help)
            usage
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
    echo "          --debug             Activer les logs de debug"
    exit 0
}