# Parmeters: install.h -t [coordinator|worker|standby]
#                      -p [token]

PG_MAJOR=16
DATABASE_PORT=54322
SERVICE_PORT=54323

while getopts "t:p:" opt;
do
    case $opt in
        t)
            TYPE=$OPTARG
            ;;
        p)
            TOKEN=$OPTARG
            ;;
        ?)
            echo "Usage: install.sh -t [coordinator|worker|standby] -p [token]"
            exit 1
            ;;
    esac
done

if [ "$TYPE" != "coordinator" ] && [ "$TYPE" != "worker" ] && [ "$TYPE" != "standby" ]; then
    echo "Unknown type: $TYPE"
    echo "Usage: install.sh -t [coordinator|worker|standby] -p [token]"
    exit 1
fi

if [ -z "$TOKEN" ]; then
    echo "Token is required."
    echo "Usage: install.sh -t [coordinator|worker|standby] -p [token]"
    exit 1
fi

DOCKER_IMAGE_NAME=postgres-ha-$TYPE
DOCKER_IMAGE_VERSION=latest
DOCKER_CONTAINER_NAME=postgres-ha-$TYPE

# Install curl
sudo apt-get update && \
sudo apt-get install -y ca-certificates curl

# Auto install docker
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | sudo bash -s docker
fi

# Remove old container and image
sudo docker stop $DOCKER_CONTAINER_NAME && \
sudo docker rm $DOCKER_CONTAINER_NAME && \
sudo docker rmi $DOCKER_IMAGE_NAME:$DOCKER_IMAGE_VERSION

# Create data directory
sudo mkdir -p /postgres-ha/data/postgresql
sudo mkdir -p /postgres-ha/data/service
sudo mkdir -p /postgres-ha/log/postgresql
sudo mkdir -p /postgres-ha/log/service
sudo mkdir -p /postgres-ha/docker
sudo chmod -R 777 /postgres-ha

# Download dockerfile
curl -fsSL https://download.lhabc.net/postgres-ha/docker/$DOCKER_IMAGE_NAME-$DOCKER_IMAGE_VERSION.dockerfile \
     -o /postgres-ha/docker/$DOCKER_IMAGE_NAME-$DOCKER_IMAGE_VERSION.dockerfile
curl -fsSL https://download.lhabc.net/postgres-ha/docker/app.py \
     -o /postgres-ha/docker/app.py

# Build docker image
cd /postgres-ha/docker && \
sudo docker build -t $DOCKER_IMAGE_NAME:$DOCKER_IMAGE_VERSION \
                  -f $DOCKER_IMAGE_NAME-$DOCKER_IMAGE_VERSION.dockerfile .

# Run docker container
sudo docker run -d \
                --name=$DOCKER_CONTAINER_NAME \
                -p $DATABASE_PORT:5432 \
                -p $SERVICE_PORT:54323 \
                -v /postgres-ha/data:/postgres-ha/data \
                -v /postgres-ha/log:/postgres-ha/log \
                -e TOKEN=$TOKEN \
                $DOCKER_IMAGE_NAME:$DOCKER_IMAGE_VERSION

echo "Done."
exit 0
