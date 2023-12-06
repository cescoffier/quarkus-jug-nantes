set projects:=movie-rater movie-stream

# Start the database
start-database:
    docker run --ulimit memlock=-1:-1 -d -it --rm=true --memory-swappiness=0 \
        -e POSTGRES_USER=movies \
        -e POSTGRES_PASSWORD=movies \
        -e POSTGRES_DB=movies \
        -p 5432:5432 postgres:15-bullseye

build-images:
    cd movie-rater && quarkus build --clean -Dquarkus.container-image.push=true -DskipTests
    cd movie-stream && quarkus build --clean -Dquarkus.container-image.push=true -DskipTests

kube-prerequisites:
    kubectl apply -f kubernetes/kafka.yaml -f kubernetes/database.yaml -f kubernetes/routes.yaml -f kubernetes/secret.yaml
    kubectl wait pods -l name=kafka --for condition=Ready --timeout=90s
    kubectl wait pods -l name=movies-db --for condition=Ready --timeout=90s

deploy-to-kube: kube-prerequisites
    cd movie-rater && quarkus deploy kubernetes
    cd movie-stream && quarkus deploy kubernetes
    echo "Movie Stream route: https://`oc get routes -o json --field-selector metadata.name=movie-stream | jq -r '.items[0].spec.host'`"
    echo "Movie Rater route: https://`oc get routes -o json --field-selector metadata.name=movie-rater | jq -r '.items[0].spec.host'`"
