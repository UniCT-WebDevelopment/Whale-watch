PORT="2375"
# Use the local or the remote application address
BROWSER_ADDRESS="http://localhost:3000"
# BROWSER_ADDRESS="https://tendto.github.io"
# BROWSER_ADDRESS="*"


# Stop running docker daemon
systemctl stop docker.service
# Start the server
dockerd --api-cors-header=$BROWSER_ADDRESS --tls --tlsverify=false --tlscacert=ca.pem --tlscert=server-cert.pem --tlskey=server-key.pem -H=0.0.0.0:$PORT