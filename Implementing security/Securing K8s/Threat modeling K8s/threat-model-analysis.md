**# E-commerce Application Threat Model**



###### \## System Architecture Overview



\### Components:

1\. \*\*Web Frontend (web-frontend)\*\*

   - Technology: Nginx

   - Replicas: 3

   - Exposure: LoadBalancer service

   - Trust Level: Public-facing (Untrusted)



2\. \*\*API Backend (api-backend)\*\*

   - Technology: Nginx (simulating API server)

   - Replicas: 2

   - Exposure: ClusterIP service

   - Trust Level: Internal (Semi-trusted)



3\. \*\*Database (mysql-db)\*\*

   - Technology: MySQL 8.0

   - Replicas: 1

   - Exposure: ClusterIP service

   - Trust Level: Internal (Trusted)



\### Trust Boundaries Identified:

1\. \*\*Internet → Frontend\*\*: External users to web application

2\. \*\*Frontend → Backend\*\*: Web tier to application tier

3\. \*\*Backend → Database\*\*: Application tier to data tier

4\. \*\*Pod → Node\*\*: Container to host system

5\. \*\*Namespace → Cluster\*\*: Application boundary within cluster

###### 

###### \### Lateral Movement Risks



\#### Network Segmentation Analysis:

\- \*\*No network policies\*\*: All pods can communicate with all services

\- \*\*Flat network\*\*: No micro-segmentation between tiers

\- \*\*Service discovery\*\*: All services discoverable via DNS

\- \*\*Port accessibility\*\*: All service ports accessible cluster-wide



\#### Potential Attack Vectors:

1\. \*\*Cross-tier access\*\*: Frontend can directly access database

2\. \*\*Service enumeration\*\*: Attackers can discover all services

3\. \*\*Protocol abuse\*\*: Unrestricted protocol usage

4\. \*\*Data exfiltration\*\*: Direct database access from compromised frontend



###### \### Container Security Risks



\#### Image Security Issues:

\- \*\*Base image vulnerabilities\*\*: Using standard images without security scanning

\- \*\*Outdated packages\*\*: Potential unpatched vulnerabilities

\- \*\*Unnecessary packages\*\*: Increased attack surface



\#### Configuration Issues:

\- \*\*Hardcoded credentials\*\*: Database passwords in environment variables

\- \*\*No resource limits\*\*: Potential for resource exhaustion attacks

\- \*\*Default configurations\*\*: Using default settings without hardening



\#### Runtime Security Issues:

\- \*\*No admission controls\*\*: No validation of pod security standards

\- \*\*Unrestricted capabilities\*\*: Containers have default Linux capabilities

\- \*\*No AppArmor/SELinux\*\*: Missing mandatory access controls

