$TTL    604800
@	IN	SOA     rhel-10-services-01.jugosdelnorte.com. admin.jugosdelnorte.com. (
                  1     ; Serial
             604800     ; Refresh
              86400     ; Retry
            2419200     ; Expire
             604800     ; Negative Cache TTL
)

; name servers - NS records
    IN      NS      rhel-10-services-01

; name servers - A records
rhel-10-services-01.jugosdelnorte.com.          IN	 A	 10.88.0.10


; Kubernetes Cluster Master - A records
rhel-10-master-01.jugosdelnorte.com.         IN      A	   10.88.0.11
rhel-10-master-02.jugosdelnorte.com.         IN      A	   10.88.0.12


; Kubernetes Cluster Master - A records
rhel-10-worker-01.jugosdelnorte.com.         IN      A	   10.88.0.14
rhel-10-worker-01.jugosdelnorte.com.         IN      A	   10.88.0.15


; Kubernetes internal cluster IPs - A records
api.jugosdelnorte.com.       IN    A    10.88.0.10
endpoint.jugosdelnorte.com.    IN    A    10.88.0.20
etcd-0.jugosdelnorte.com.    IN    A    10.88.0.11
etcd-1.jugosdelnorte.com.    IN    A    10.88.0.12


; Kubernetes registry and toolbox - A records
registry.jugosdelnorte.com.      IN    A    10.88.0.10
rhel-10-toolbox-01.jugosdelnorte.com.       IN    A    10.88.0.29


; kubernetes internal cluster IPs - SRV records
_etcd-server-ssl._tcp.jugosdelnorte.com.    86400     IN    SRV     0    10    2380    etcd-0
_etcd-server-ssl._tcp.jugosdelnorte.com.    86400     IN    SRV     0    10    2380    etcd-1
