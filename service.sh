#!/bin/bash

# Função de construção da imagem
build_image() {
    local service_name=$1

    case $service_name in
        dns)
            echo "Construindo a imagem DNS..."
            docker build -t my-dns ./dns
            ;;
        web)
            echo "Construindo a imagem Web..."
            docker build -t my-web ./web
            ;;
        *)
            echo "Serviço desconhecido: $service_name"
            exit 1
            ;;
    esac
}

# Função inicializando serviço
start_service() {
    local service_name=$1

    # Tentativa de inicialização do contêiner e, caso não exista, constrói a imagem
    if [ "$(docker ps -aq -f name=${service_name}-server)" ]; then
        echo "Iniciando o contêiner ${service_name}..."
        docker start ${service_name}-server
    else
        echo "Contêiner ${service_name} não encontrado. Construindo a imagem e iniciando o contêiner..."
        build_image "$service_name"
        case $service_name in
            dns)
                docker run -d --name dns-server --restart unless-stopped -p 53:53/udp my-dns
                ;;
            web)
                docker run -d --name web-server --restart unless-stopped -p 80:80 my-web
                ;;
        esac
    fi
}

# Função para parar o serviço
stop_service() {
    local service_name=$1

    case $service_name in
        dns)
            echo "Parando o contêiner DNS..."
            docker stop dns-server
            docker rm dns-server
            ;;
        web)
            echo "Parando o contêiner Web..."
            docker stop web-server
            docker rm web-server
            ;;
        *)
            echo "Serviço desconhecido: $service_name"
            exit 1
            ;;
    esac
}

# Verificação do argumento passado
if [ "$#" -ne 2 ]; then
    echo "Uso: $0 {start|stop} {serviço}"
    exit 1
fi

command=$1
service=$2

case $command in
    start)
        start_service "$service"
        ;;
    stop)
        stop_service "$service"
        ;;
    *)
        echo "Comando desconhecido: $command"
        exit 1
        ;;
esac