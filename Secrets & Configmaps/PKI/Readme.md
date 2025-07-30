##### **PKI**



a.

\# Create main PKI directory

mkdir -p ~/k8s-pki/{ca,certs,keys,csr}



\# Navigate to the PKI directory

cd ~/k8s-pki



\# Create subdirectories for better organization

mkdir -p ca/{private,certs}

mkdir -p api-server/{private,certs}

mkdir -p etcd/{private,certs}

mkdir -p kubelet/{private,certs}

Generate the Root CA private key:

\# Generate a 4096-bit RSA private key for the CA

openssl genrsa -out ca/private/ca-key.pem 4096



\# Set appropriate permissions for the private key

chmod 400 ca/private/ca-key.pem





b. 

Generate the CA certificate using OpenSSL:

\# Generate the CA certificate

openssl req -new -x509 -key ca/private/ca-key.pem -out ca/certs/ca.pem -days 365 -config <(

cat << EOF

\[req]

distinguished\_name = req\_distinguished\_name

x509\_extensions = v3\_ca

prompt = no



\[req\_distinguished\_name]

C = US

ST = California

L = San Francisco

O = Kubernetes

OU = CA

CN = Kubernetes CA



\[v3\_ca]

basicConstraints = CA:TRUE

keyUsage = keyCertSign, cRLSign

subjectKeyIdentifier = hash

authorityKeyIdentifier = keyid:always,issuer:always

EOF

)

Verify the CA certificate:

\# Display CA certificate details

openssl x509 -in ca/certs/ca.pem -text -noout



\# Check certificate validity

openssl x509 -in ca/certs/ca.pem -noout -dates



c. 



Create the API Server private key:

\# Generate API Server private key

openssl genrsa -out api-server/private/api-server-key.pem 2048



\# Set appropriate permissions

chmod 400 api-server/private/api-server-key.pem

Generate API Server certificate:

\# Create certificate signing request

openssl req -new -key api-server/private/api-server-key.pem -out api-server/api-server.csr -config <(

cat << EOF

\[req]

distinguished\_name = req\_distinguished\_name

req\_extensions = v3\_req

prompt = no



\[req\_distinguished\_name]

C = US

ST = California

L = San Francisco

O = system:masters

OU = Kubernetes The Hard Way

CN = kube-apiserver



\[v3\_req]

basicConstraints = CA:FALSE

keyUsage = nonRepudiation, digitalSignature, keyEncipherment

subjectAltName = @alt\_names



\[alt\_names]

DNS.1 = kubernetes

DNS.2 = kubernetes.default

DNS.3 = kubernetes.default.svc

DNS.4 = kubernetes.default.svc.cluster.local

DNS.5 = localhost

IP.1 = 127.0.0.1

IP.2 = 10.96.0.1

EOF

)



\# Sign the certificate with our CA

openssl x509 -req -in api-server/api-server.csr -CA ca/certs/ca.pem -CAkey ca/private/ca-key.pem -CAcreateserial -out api-server/certs/api-server.pem -days 365 -extensions v3\_req -extfile <(

cat << EOF

\[v3\_req]

basicConstraints = CA:FALSE

keyUsage = nonRepudiation, digitalSignature, keyEncipherment

subjectAltName = @alt\_names



\[alt\_names]

DNS.1 = kubernetes

DNS.2 = kubernetes.default

DNS.3 = kubernetes.default.svc

DNS.4 = kubernetes.default.svc.cluster.local

DNS.5 = localhost

IP.1 = 127.0.0.1

IP.2 = 10.96.0.1

EOF

)



d.

\# Generate etcd private key

openssl genrsa -out etcd/private/etcd-key.pem 2048



\# Set permissions

chmod 400 etcd/private/etcd-key.pem



\# Create etcd certificate signing request

openssl req -new -key etcd/private/etcd-key.pem -out etcd/etcd.csr -config <(

cat << EOF

\[req]

distinguished\_name = req\_distinguished\_name

req\_extensions = v3\_req

prompt = no



\[req\_distinguished\_name]

C = US

ST = California

L = San Francisco

O = etcd

OU = Kubernetes The Hard Way

CN = etcd



\[v3\_req]

basicConstraints = CA:FALSE

keyUsage = nonRepudiation, digitalSignature, keyEncipherment

subjectAltName = @alt\_names



\[alt\_names]

DNS.1 = localhost

DNS.2 = etcd.kube-system.svc.cluster.local

IP.1 = 127.0.0.1

EOF

)



\# Sign the etcd certificate

openssl x509 -req -in etcd/etcd.csr -CA ca/certs/ca.pem -CAkey ca/private/ca-key.pem -CAcreateserial -out etcd/certs/etcd.pem -days 365 -extensions v3\_req -extfile <(

cat << EOF

\[v3\_req]

basicConstraints = CA:FALSE

keyUsage = nonRepudiation, digitalSignature, keyEncipherment

subjectAltName = @alt\_names



\[alt\_names]

DNS.1 = localhost

DNS.2 = etcd.kube-system.svc.cluster.local

IP.1 = 127.0.0.1

EOF

)



e.

\# Create admin client private key

openssl genrsa -out certs/admin-key.pem 2048



\# Create admin client certificate

openssl req -new -key certs/admin-key.pem -out csr/admin.csr -subj "/C=US/ST=California/L=San Francisco/O=system:masters/OU=Kubernetes The Hard Way/CN=admin"



\# Sign admin certificate

openssl x509 -req -in csr/admin.csr -CA ca/certs/ca.pem -CAkey ca/private/ca-key.pem -CAcreateserial -out certs/admin.pem -days 365

Create kubelet client certificate:

\# Create kubelet client private key

openssl genrsa -out kubelet/private/kubelet-key.pem 2048



\# Create kubelet client certificate

openssl req -new -key kubelet/private/kubelet-key.pem -out kubelet/kubelet.csr -subj "/C=US/ST=California/L=San Francisco/O=system:nodes/OU=Kubernetes The Hard Way/CN=system:node:worker-1"



\# Sign kubelet certificate

openssl x509 -req -in kubelet/kubelet.csr -CA ca/certs/ca.pem -CAkey ca/private/ca-key.pem -CAcreateserial -out kubelet/certs/kubelet.pem -days 365



f.

\# Make the script executable

chmod +x rotate-certificates.sh



Set up Automated Certificate Rotation

Create a cron job for certificate monitoring:

\# Add cron job for daily certificate monitoring

(crontab -l 2>/dev/null; echo "0 9 \* \* \* $HOME/k8s-pki/monitor-certificates.sh") | crontab -



\# Verify cron job was added

crontab -l

Test the certificate rotation process:

\# Run the certificate monitoring script

./monitor-certificates.sh



\# Check the log file

cat ~/k8s-pki/cert-monitor.log





g.

Implement Automated Certificate Monitoring

chmod +x monitor-certificates.sh



h. 

Create a certificate verification script:

chmod +x verify-certificates.sh



I.

Create a test script for certificate-based authentication

chmod +x test-auth.sh

