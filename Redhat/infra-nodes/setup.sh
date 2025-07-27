#!/bin/bash

source "$(pwd)/env"

ROOT="${DOMAIN_NAME}"
if [[ ! -e $ROOT || ! -d $ROOT ]]
then
	mkdir -p $ROOT
fi

cat <<EOF
#
# Software installation
#

EOF
#yum install -y bind haproxy nano wget curl nfs-utils httpd mod_ssl mariadb{,-server} docker-distribution


cat <<EOF
#
# Setting up DNS server
#

EOF

if [ ! -d $ROOT/etc/named/zones ]
then
	mkdir -p $ROOT/etc/named/zones
	if [ ! -e $ROOT/etc/named/zones/db.$DOMAIN_NAME ]
	then
		echo "Setting up DNS domain zone"
		if cp templates/db.__DOMAIN_NAME__ $ROOT/etc/named/zones/db.$DOMAIN_NAME
		then
			sed -i \
			-e "s/__DOMAIN_NAME__/$DOMAIN_NAME/g" \
			-e "s/__SERVICE_HOSTNAME__/$SERVICE_HOSTNAME/g" \
			-e "s/__SERVICE_IP__/$SERVICE_IP/g" \
			-e "s/__MASTER_01_IP__/$MASTER_01_IP/g" \
			-e "s/__MASTER_02_IP__/$MASTER_02_IP/g" \
			-e "s/__WORKER_01_IP__/$WORKER_01_IP/g" \
			-e "s/__WORKER_02_IP__/$WORKER_02_IP/g" \
			-e "s/__MASTER_01_HOSTNAME__/$MASTER_01_HOSTNAME/g" \
			-e "s/__MASTER_02_HOSTNAME__/$MASTER_02_HOSTNAME/g" \
			-e "s/__WORKER_01_HOSTNAME__/$WORKER_01_HOSTNAME/g" \
			-e "s/__WORKER_02_HOSTNAME__/$WORKER_02_HOSTNAME/g" \
			-e "s/__KUBERNETES_ENDPOINT_IP__/$KUBERNETES_ENDPOINT_IP/g" \
			-e "s/__KUBERNETES_ENDPOINT_HOSTNAME__/$KUBERNETES_ENDPOINT_HOSTNAME/g" \
			-e "s/__KUBERNETES_CR_IP__/$KUBERNETES_CR_IP/g" \
			-e "s/__KUBERNETES_CR_HOSTNAME__/$KUBERNETES_CR_HOSTNAME/g" \
			-e "s/__TOOLBOX_HOSTNAME__/$TOOLBOX_HOSTNAME/g" \
			-e "s/__TOOLBOX_IP__/$TOOLBOX_IP/g" \
			$ROOT/etc/named/zones/db.$DOMAIN_NAME
		fi
	fi
fi

IFS=.
set -- $SERVICE_IP
PTR="$3.$2.$1"
service_ptr="$4"

set -- $MASTER_01_IP
master_01_ptr="$4"

set -- $MASTER_02_IP
master_02_ptr="$4"

set -- $WORKER_01_IP
worker_01_ptr="$4"

set -- $WORKER_02_IP
worker_02_ptr="$4"

IFS=" "

if [ ! -e $ROOT/etc/named/zones/db.$PTR ]
then

	if cp templates/db.__REVERSE_PTR__ $ROOT/etc/named/zones/db.$PTR
	then
		echo "Setting up reverse DNS zone ..."
		sed -i \
		-e "s/__SERVICE_HOSTNAME__/$SERVICE_HOSTNAME/g" \
		-e "s/__DOMAIN_NAME__/$DOMAIN_NAME/g" \
		-e "s/__MASTER_01_HOSTNAME__/$MASTER_01_HOSTNAME/g" \
		-e "s/__MASTER_02_HOSTNAME__/$MASTER_02_HOSTNAME/g" \
		-e "s/__WORKER_01_HOSTNAME__/$WORKER_01_HOSTNAME/g" \
		-e "s/__WORKER_02_HOSTNAME__/$WORKER_02_HOSTNAME/g" \
		-e "s/__service_ptr__/$service_ptr/g" \
		-e "s/__master_01_ptr__/$master_01_ptr/g" \
		-e "s/__master_02_ptr__/$master_02_ptr/g" \
		-e "s/__worker_01_ptr__/$worker_01_ptr/g" \
		-e "s/__worker_02_ptr__/$worker_02_ptr/g" \
		$ROOT/etc/named/zones/db.$PTR
	fi
fi


if [ ! -e $ROOT/etc/named.conf ]
then

        if cp templates/named.conf $ROOT/etc/named.conf
        then
		echo "Setting up DNS configuration file ..."

		sed -i \
		-e "s/__SERVICE_IP__/$SERVICE_IP/g" \
		-e "s#__NODES_NETWORK__#$NODES_NETWORK#g" \
		-e "s/__NODES_NETWORK_GW__/$NODES_NETWORK_GW/g" \
		$ROOT/etc/named.conf
        fi
fi


if [ ! -e $ROOT/etc/named/named.conf.local ]
then

        if cp templates/named.conf.local $ROOT/etc/named/named.conf.local
        then
                echo "Setting up DNS configuration local file ..."

                sed -i \
                -e "s/__DOMAIN_NAME__/$DOMAIN_NAME/g" \
                -e "s/__reverse_network__/$PTR/g" \
                $ROOT/etc/named/named.conf.local
        fi
fi

cat <<EOF
#
# Setting up HAproxy
#

EOF

mkdir -p $ROOT/etc/haproxy/
if [ ! -e $ROOT/etc/haproxy/haproxy.cfg ]
then

        if cp templates/haproxy.cfg $ROOT/etc/haproxy/haproxy.cfg
        then
                echo "Setting up HAproxy configuration file ..."

                sed -i \
                -e "s/__SERVICE_IP__/$SERVICE_IP/g" \
                -e "s/__MASTER_01_IP__/$MASTER_01_IP/g" \
                -e "s/__MASTER_02_IP__/$MASTER_02_IP/g" \
                $ROOT/etc/haproxy/haproxy.cfg
        fi
fi

cat <<EOF
#
# Setting up NFS server
#

EOF
echo "Seting up NFS shared resources ..."

mkdir -p $ROOT/var/nfsshare/
if [ -d tls ]
then
	cp -af tls $ROOT/var/nfsshare/
	mkdir -p $ROOT/etc/ssl/$DOMAIN_NAME
fi
cat /etc/fstab > $ROOT/etc/fstab
echo "/var/nfsshare $NODES_NETWORK(rw,sync,no_subtree_check,no_root_squash)" | tee -a $ROOT/etc/exports
if [ -d $ROOT/var/nfsshare/tls ]
then
	echo "/var/nfsshare/tls $NODES_NETWORK(rw,sync,no_subtree_check,no_root_squash)" | tee -a $ROOT/etc/exports
	echo "/localhost:/var/nfsshare/tls    /etc/ssl/$DOMAIN_NAME    nfs    defaults    0 0" | tee -a $ROOT/etc/fstab
fi


cat <<EOF
#
# Seting up container registry
#

EOF

mkdir -p  $ROOT/etc/httpd/{conf.d,{sites-enabled,sites-available}}

echo "Setting up local httpd configuration ..."
if [ ! -f $ROOT/etc/httpd/conf.d/httpd-local.conf ]
then
	cp -af templates/httpd-local.conf $ROOT/etc/httpd/conf.d/httpd-local.conf
fi

echo "Setting up registry virtual host ..."
if [ ! -f $ROOT/etc/httpd/sites-available/000-$KUBERNETES_CR_HOSTNAME.$DOMAIN_NAME.conf ]
then
        cp -af templates/000-__KUBERNETES_CR_HOSTNAME__.__DOMAIN_NAME__.conf $ROOT/etc/httpd/sites-available/000-$KUBERNETES_CR_HOSTNAME.$DOMAIN_NAME.conf
	sed -i \
	-e "s/__KUBERNETES_CR_HOSTNAME__/$KUBERNETES_CR_HOSTNAME/g" \
	-e "s/__DOMAIN_NAME__/$DOMAIN_NAME/g" \
	-e "s/__KUBERNETES_CR_SSL_CER__/$KUBERNETES_CR_SSL_CER/g" \
	-e "s/__KUBERNETES_CR_SSL_KEY__/$KUBERNETES_CR_SSL_KEY/g" \
	-e "s/__KUBERNETES_CR_CAROOT__/$KUBERNETES_CR_CAROOT/g" \
	$ROOT/etc/httpd/sites-available/000-$KUBERNETES_CR_HOSTNAME.$DOMAIN_NAME.conf
fi





#echo ${n%.*}
#echo $n | awk -F'.' '{ print $3"."$2"."$1 }'
