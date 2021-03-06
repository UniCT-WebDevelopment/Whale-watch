# ![favicon](/public/favicon.ico) Whale watch
[![Website shields.io](https://img.shields.io/website-up-down-green-red/http/shields.io.svg)](https://tendto.github.io/Whale-watch/)
![CI/CD](https://github.com/TendTo/Whale-watch/workflows/Production/badge.svg)
[![codecov](https://codecov.io/gh/TendTo/Whale-watch/branch/master/graph/badge.svg?token=mHQ10TaJii)](https://codecov.io/gh/TendTo/Whale-watch)

**Simple browser-based Docker GUI. It can be used to connect to remote Docker instances.**

![Home page](/docs/img/Main.JPG)
![Images section](/docs/img/Images.JPG)
![Containers section](/docs/img/Containers.JPG)

## Setup the Docker daemon 🐳

### Requirements
- [docker](https://www.docker.com/)

You may find some scripts in the _scripts_ folder to automate the following procedures.

### HTTP - Simplest - ONLY LOCAL
The simplest way to make the Docker daemon listen for remote connections is with the following command:
```bash
dockerd --api-cors-header=$BROWSER_ADDRESS -H unix:///var/run/docker.sock -H tcp://0.0.0.0:$PORT
```
Where 
- $BROWSER_ADDRESS is the GitHub page address or the address of the machine you are using this program on, or _*_ to match all addresses
- $PORT is the port you want to expose. The default one is port 2375

You may need to stop the docker.service if it is already running with
```bash
sudo systemctl stop docker.service
```

### HTTPS only server - Medium
To make the connection more secure, you could use TLS (HTTPS) to protect the traffic to the Docker daemon socket.  
Only the server is verified, but not the client.  
You could use an actual certificate, but you can also sign one yourself with the following procedure.  
Be mindful that if you follow the latter path, your browser may complain about _untrusted certificates_ and you may need to disable the feature temporarily.  
Alternatively, you coul add the ca.pem file in a ca.crt file and add it to your browser's _certificate authorities_ list.
```bash
# Convert the ca.pem file in a ca.crt file
openssl x509 -outform der -in ca.pem -out ca.crt
```
The term _host_ refers to the machine running the Docker daemon, while _client_ refers to the machine running _Whale watch_.  
See the **Learn more** session for more details. In short:
```bash
# Generate a pair of keys for the Certificate Authority
openssl genrsa -aes256 -out ca-key.pem 4096

# Create a Certificate Authority. When asked for a "Common Name", you should provide the hostname of the remote machine
openssl req -new -x509 -days 365 -key ca-key.pem -sha256 -out ca.pem

# Generate another pair of keys for the server's certificate
openssl genrsa -out server-key.pem 4096

# Create a certificate request. $HOST should be the same "Common Name" provided before
openssl req -subj "/CN=$HOST" -sha256 -new -key server-key.pem -out server.csr

# Additional connection settings. You may want to add the ip of the host. $HOST should be the same "Common Name" provided before, while $HOST_IP is its public ip address
echo subjectAltName = DNS:$HOST,IP:10.10.10.20,IP:127.0.0.1,IP:$HOST_IP >> extfile.cnf
echo extendedKeyUsage = serverAuth >> extfile.cnf

# Generate the signed certificate
openssl x509 -req -days 365 -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem \
  -CAcreateserial -out server-cert.pem -extfile extfile.cnf
```
To make the Docker daemon listen for remote connections with the certificates use the following command:
```bash
dockerd \
     --api-cors-header=$BROWSER_ADDRESS \
    --tls \
    --tlsverify=false \
    --tlscacert=ca.pem \
    --tlscert=server-cert.pem \
    --tlskey=server-key.pem \
    -H=0.0.0.0:$PORT
```
Where 
- $BROWSER_ADDRESS is the GitHub page address or the address of the machine you are using _Whale watch_ on, or _*_ to match all addresses
- $PORT is the port you want to expose. The default one is port 2375

You may need to stop the docker.service if it is already running with
```bash
sudo systemctl stop docker.service
```

### HTTPS complete - Complex
To make the connection even more secure, you could use TLS (HTTPS) to protect the Docker daemon socket.  
This mode also verifies the user, meaning that only the users with the correct certificates can access the socket.  
You could use an actual certificate, but you can also sign one yourself with the following procedure.  
There is some additional setup that has to be done on the browser:
- convert the ca.pem certificate authority to a ca.crt file and add it as a trusted _certificate authority_ on your browser
  - ```bash
    # Convert the ca.pem file in a ca.crt file
    openssl x509 -outform der -in ca.pem -out ca.crt
    ```
- convert the cert.pem client certificate to a cert.p12 file that includes the key used to sign it and add it to your list of _client certificates_ on your browser
  - ```bash
    # Convert the cert.pem file to a cert.p12 file
    # $KEY_PASS is the password associated with the key
    openssl pkcs12 -export -out cert.p12 -in cert.pem -inkey key.pem -passin pass:$KEY_PASS -passout pass:$KEY_PASS
    ```

The term _host_ refers to the machine running the Docker daemon, while _client_ refers to the machine running _Whale watch_.  
See the **Learn more** session for more details. In short:
```bash
# Generate a pair of keys for the Certificate Authority
openssl genrsa -aes256 -out ca-key.pem 4096

# Create a Certificate Authority. When asked for a "Common Name", you should provide the hostname of the remote machine
openssl req -new -x509 -days 365 -key ca-key.pem -sha256 -out ca.pem

# Generate another pair of keys for the server's certificate
openssl genrsa -out server-key.pem 4096

# Create a certificate request. $HOST should be the same "Common Name" provided before
openssl req -subj "/CN=$HOST" -sha256 -new -key server-key.pem -out server.csr

# Additional connection settings. You may want to add the ip of the host.
# $HOST should be the same "Common Name" provided before, while $HOST_IP is its public ip address
echo subjectAltName = DNS:$HOST,IP:10.10.10.20,IP:127.0.0.1,IP:$HOST_IP >> extfile.cnf
echo extendedKeyUsage = serverAuth >> extfile.cnf

# Generate the signed certificate
openssl x509 -req -days 365 -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem \
  -CAcreateserial -out server-cert.pem -extfile extfile.cnf

# Generate the key pair for the client
openssl genrsa -out key.pem 4096

# Create the client's certificate request
openssl req -subj '/CN=client' -new -key key.pem -out client.csr

# To make the key suitable for client authentication, create a new extensions config file
echo extendedKeyUsage = clientAuth > extfile-client.cnf

# Finally, generate the client's certificate
openssl x509 -req -days 365 -sha256 -in client.csr -CA ca.pem -CAkey ca-key.pem \
  -CAcreateserial -out cert.pem -extfile extfile-client.cnf

# If you plan to use the client certificate for authentication, you have to use the p12 certificate, that includes the private key.
# $KEY_PASS is the passphrase used in the key creation process
openssl pkcs12 -export -out cert.p12 -in cert.pem -inkey key.pem -passin pass:$KEY_PASS -passout pass:$KEY_PASS
```
To make the Docker daemon listen for remote connections with the certificates use the following command:
```bash
dockerd \
     --api-cors-header=$BROWSER_ADDRESS \
    --tlsverify \
    --tlscacert=ca.pem \
    --tlscert=server-cert.pem \
    --tlskey=server-key.pem \
    -H=0.0.0.0:$PORT
```
Where 
- $BROWSER_ADDRESS is the GitHub page address or the address of the machine you are using _Whale watch_ on, or _*_ to match all addresses
- $PORT is the port you want to expose. The default one is port 2375

You will need the contents of the _ca.pem_, _cert.pem_ and _key.pem_ files to connect to the host from the client.
You may need to stop the docker.service if it is already running with
```bash
sudo systemctl stop docker.service
```

## Starting in local 💻

### Requirements
- [node 16.2.0](https://nodejs.org/)

### Available Scripts
In the project directory, you can run:

#### `npm start`
Runs the app in the development mode.\
Open [http://localhost:3000](http://localhost:3000) to view it in the browser.

The page will reload if you make edits.\
You will also see any lint errors in the console.

#### `npm test`
Launches the test runner in the interactive watch mode.\
See the section about [running tests](https://facebook.github.io/create-react-app/docs/running-tests) for more information.

#### `npm run build`
Builds the app for production to the `build` folder.\
It correctly bundles React in production mode and optimizes the build for the best performance.

The build is minified and the filenames include the hashes.\
Your app is ready to be deployed!

See the section about [deployment](https://facebook.github.io/create-react-app/docs/deployment) for more information.

#### `npm run eject`

**Note: this is a one-way operation. Once you `eject`, you can’t go back!**
If you aren’t satisfied with the build tool and configuration choices, you can `eject` at any time. This command will remove the single build dependency from your project.

Instead, it will copy all the configuration files and the transitive dependencies (webpack, Babel, ESLint, etc) right into your project so you have full control over them. All of the commands except `eject` will still work, but they will point to the copied scripts so you can tweak them. At this point, you’re on your own.

You don’t have to ever use `eject`. The curated feature set is suitable for small and middle deployments, and you shouldn’t feel obligated to use this feature. However, we understand that this tool wouldn’t be useful if you couldn’t customize it when you are ready for it.

## Learn more 📖
You can learn more about Create React App in the [Create React App documentation](https://facebook.github.io/create-react-app/docs/getting-started).  
To learn React, check out the [React documentation](https://reactjs.org/).
The complete documentation of the Docker API can be found [here](https://docs.docker.com/engine/install/linux-postinstall/#configure-where-the-docker-daemon-listens-for-connections).  
Additionally, to use HTTPS, you may want to read [this](https://docs.docker.com/engine/security/protect-access/#use-tls-https-to-protect-the-docker-daemon-socket).

## Made with 🔧
- [react](https://reactjs.org/)
- [Create React App](https://create-react-app.dev/)
- [Darkly bootstrap theme](https://bootswatch.com/darkly/)
- [dockerode typing](https://github.com/apocas/dockerode)
