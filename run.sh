#set default worker container count if it's unset
if [ -z "$1" ]; then
    workerCount=1
else
    workerCount=$1
fi

echo "$workerCount worker and 1 master container will be created..."

# Cleanup workers file
> ./conf/workers

# Add all worker container names to workers file
for (( i=1; i<=$workerCount; i++ )); do
    echo "Exporting worker$i to slaves file..."
    echo "worker$i" >> ./conf/workers
done

# Create base hadoop image named "base-hadoop:1.0"
docker build -t base-hadoop:1.0 .

# Run base-hadoop:1.0 image as master container
master_container_id=$(docker run -itd -p 9870:9870 -p 8088:8088 -p 9864:9864 --name master --hostname master base-hadoop:1.0)

master_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $master_container_id)

for (( c=1; c<=$workerCount; c++ )); do
    tmpName="worker$c"
    # Run base-hadoop:1.0 image as worker container
    worker_container_id=$(docker run -itd --name $tmpName --hostname $tmpName base-hadoop:1.0)
    worker_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $worker_container_id)
    # Update /etc/hosts file of worker container with entries for master and workers
    docker exec -it $worker_container_id bash -c "echo '$master_ip master' >> /etc/hosts"
done

# Update /etc/hosts file of master container with entries for workers
for (( c=1; c<=$workerCount; c++ )); do
    tmpName="worker$c"
    worker_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $tmpName)
    # Add worker IPs and hostnames to /etc/hosts of master container
    docker exec -it $master_container_id bash -c "echo '$worker_ip $tmpName' >> /etc/hosts"

    # add worker hostnames and IPs to /etc/hosts of each worker container to each other worker container
    for (( d=1; d<=$workerCount; d++ )); do
        tmpName2="worker$d"
        worker_ip2=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $tmpName2)
        docker exec -it $tmpName bash -c "echo '$worker_ip2 $tmpName2' >> /etc/hosts"
    done

done

# Run hadoop commands
docker exec -ti $master_container_id bash -c "hadoop namenode -format && /usr/local/hadoop/sbin/start-dfs.sh && yarn --daemon start resourcemanager && yarn --daemon start nodemanager && mapred --daemon start historyserver"
docker exec -ti $master_container_id bash