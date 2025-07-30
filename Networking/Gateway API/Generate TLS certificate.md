\# Create private key

openssl genrsa -out webapp-tls.key 2048



\# **Create certificate signing request**

openssl req -new -key webapp-tls.key -out webapp-tls.csr -subj "/CN=\*.local/O=Lab Organization"



\# **Create self-signed certificate**

openssl x509 -req -in webapp-tls.csr -signkey webapp-tls.key -out webapp-tls.crt -days 365 -extensions v3\_req -extfile <(cat <<EOF

\[v3\_req]

keyUsage = keyEncipherment, dataEncipherment

extendedKeyUsage = serverAuth

subjectAltName = @alt\_names

\[alt\_names]

DNS.1 = app1.local

DNS.2 = app2.local

DNS.3 = myapp.local

DNS.4 = gateway-app1.local

DNS.5 = gateway-app2.local

DNS.6 = secure-app.local

EOF

)

