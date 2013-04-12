#!/bin/sh

zfs create zones/ec
zfs set mountpoint=/ec zones/ec
zfs mount zones/ec
cd / && wget -O- -q http://svn.everycity.co.uk/public/solaris/misc/pkg5-smartos-bootstrap-20111221.tar.gz | gtar -zxf-

export LD_LIBRARY_PATH=/ec/lib
/ec/bin/pkg install pkg:/database/mysql-55/client@5.5.16-0.162 pkg:/library/python/mysqldb@1.2.3-0.162
/ec/bin/pkg install python26 git setuptools-26 gcc-44 libxslt gnu-binutils

zfs create zones/workspace
cd /zones/workspace/

export PATH=/ec/bin:$PATH
easy_install pip
#git clone git://github.com/tmetsch/nova.git -b smartosfolsom
git clone https://github.com/dstroppa/openstack-smartos-nova-grizzly.git

cd nova/tools
export CFLAGS="-D_XPG6 -std=c99"
pip install -r pip-requires

mkdir -p /etc/nova
echo "
[DEFAULT]
verbose=True
auth_strategy=keystone
allow_resize_to_same_host=True
api_paste_config=/etc/nova/api-paste.ini
rootwrap_config=/etc/nova/rootwrap.conf
compute_scheduler_driver=nova.scheduler.filter_scheduler.FilterScheduler
dhcpbridge_flagfile=/etc/nova//etc/nova/nova.conf
force_dhcp_release=True
fixed_range=10.0.0.0/24
s3_host=192.168.56.101
s3_port=3333
osapi_compute_extension=nova.api.openstack.compute.contrib.standard_extensions
my_ip=192.168.56.103
sql_connection=mysql://root:os4all@192.168.56.101/nova?charset=utf8
libvirt_type=qemu
libvirt_cpu_mode=none
instance_name_template=instance-%08x
image_service=nova.image.glance.GlanceImageService
enabled_apis=ec2,osapi_compute,metadata
# volume_api_class=nova.volume.cinder.API
state_path=/zones/workspace/nova
instances_path=/zones/workspace/nova/instances
logging_context_format_string=%(asctime)s %(color)s%(levelname)s %(name)s [%(request_id)s %(user_name)s %(project_name)s%(color)s] %(instance)s%(color)s%(message)s
logging_default_format_string=%(asctime)s %(color)s%(levelname)s %(name)s [-%(color)s] %(instance)s%(color)s%(message)s
logging_debug_format_suffix=from (pid=%(process)d) %(funcName)s %(pathname)s:%(lineno)d
logging_exception_prefix=%(color)s%(asctime)s TRACE %(name)s %(instance)s
network_manager=nova.network.manager.FlatDHCPManager
public_interface=br100
vlan_interface=eth0
flat_network_bridge=br100
flat_interface=eth0
novncproxy_base_url=http://192.168.56.101:6080/vnc_auto.html
xvpvncproxy_base_url=http://192.168.56.101:6081/console
vncserver_listen=127.0.0.1
vncserver_proxyclient_address=127.0.0.1
ec2_dmz_host=192.168.56.101
rabbit_host=192.168.56.101
rabbit_password=os4all
glance_api_servers=192.168.56.101:9292
# compute_driver=libvirt.LibvirtDriver
firewall_driver=nova.virt.libvirt.firewall.IptablesFirewallDriver
fake_network=True
compute_driver=nova.virt.smartosapi.driver.SmartOSDriver" > /etc/nova/nova.conf

echo '{
    "context_is_admin":  [["role:admin"]],
    "admin_or_owner":  [["is_admin:True"], ["project_id:%(project_id)s"]],
    "default": [["rule:admin_or_owner"]],


    "compute:create": [],
    "compute:create:attach_network": [],
    "compute:create:attach_volume": [],
    "compute:get_all": [],


    "admin_api": [["is_admin:True"]],
    "compute_extension:accounts": [["rule:admin_api"]],
    "compute_extension:admin_actions": [["rule:admin_api"]],
    "compute_extension:admin_actions:pause": [["rule:admin_or_owner"]],
    "compute_extension:admin_actions:unpause": [["rule:admin_or_owner"]],
    "compute_extension:admin_actions:suspend": [["rule:admin_or_owner"]],
    "compute_extension:admin_actions:resume": [["rule:admin_or_owner"]],
    "compute_extension:admin_actions:lock": [["rule:admin_api"]],
    "compute_extension:admin_actions:unlock": [["rule:admin_api"]],
    "compute_extension:admin_actions:resetNetwork": [["rule:admin_api"]],
    "compute_extension:admin_actions:injectNetworkInfo": [["rule:admin_api"]],
    "compute_extension:admin_actions:createBackup": [["rule:admin_or_owner"]],
    "compute_extension:admin_actions:migrateLive": [["rule:admin_api"]],
    "compute_extension:admin_actions:resetState": [["rule:admin_api"]],
    "compute_extension:admin_actions:migrate": [["rule:admin_api"]],
    "compute_extension:aggregates": [["rule:admin_api"]],
    "compute_extension:certificates": [],
    "compute_extension:cloudpipe": [["rule:admin_api"]],
    "compute_extension:console_output": [],
    "compute_extension:consoles": [],
    "compute_extension:createserverext": [],
    "compute_extension:deferred_delete": [],
    "compute_extension:disk_config": [],
    "compute_extension:extended_server_attributes": [["rule:admin_api"]],
    "compute_extension:extended_status": [],
    "compute_extension:flavor_access": [],
    "compute_extension:flavor_disabled": [],
    "compute_extension:flavor_rxtx": [],
    "compute_extension:flavor_swap": [],
    "compute_extension:flavorextradata": [],
    "compute_extension:flavorextraspecs": [],
    "compute_extension:flavormanage": [["rule:admin_api"]],
    "compute_extension:floating_ip_dns": [],
    "compute_extension:floating_ip_pools": [],
    "compute_extension:floating_ips": [],
    "compute_extension:hosts": [["rule:admin_api"]],
    "compute_extension:hypervisors": [["rule:admin_api"]],
    "compute_extension:instance_usage_audit_log": [["rule:admin_api"]],
    "compute_extension:keypairs": [],
    "compute_extension:multinic": [],
    "compute_extension:networks": [["rule:admin_api"]],
    "compute_extension:networks:view": [],
    "compute_extension:quotas:show": [],
    "compute_extension:quotas:update": [["rule:admin_api"]],
    "compute_extension:quota_classes": [],
    "compute_extension:rescue": [],
    "compute_extension:security_groups": [],
    "compute_extension:server_diagnostics": [["rule:admin_api"]],
    "compute_extension:simple_tenant_usage:show": [["rule:admin_or_owner"]],
    "compute_extension:simple_tenant_usage:list": [["rule:admin_api"]],
    "compute_extension:users": [["rule:admin_api"]],
    "compute_extension:virtual_interfaces": [],
    "compute_extension:virtual_storage_arrays": [],
    "compute_extension:volumes": [],
    "compute_extension:volumetypes": [],


    "volume:create": [],
    "volume:get_all": [],
    "volume:get_volume_metadata": [],
    "volume:get_snapshot": [],
    "volume:get_all_snapshots": [],


    "volume_extension:types_manage": [["rule:admin_api"]],
    "volume_extension:types_extra_specs": [["rule:admin_api"]],
    "volume_extension:volume_admin_actions:reset_status": [["rule:admin_api"]],
    "volume_extension:snapshot_admin_actions:reset_status": [["rule:admin_api"]],
    "volume_extension:volume_admin_actions:force_delete": [["rule:admin_api"]],


    "network:get_all_networks": [],
    "network:get_network": [],
    "network:delete_network": [],
    "network:disassociate_network": [],
    "network:get_vifs_by_instance": [],
    "network:allocate_for_instance": [],
    "network:deallocate_for_instance": [],
    "network:validate_networks": [],
    "network:get_instance_uuids_by_ip_filter": [],

    "network:get_floating_ip": [],
    "network:get_floating_ip_pools": [],
    "network:get_floating_ip_by_address": [],
    "network:get_floating_ips_by_project": [],
    "network:get_floating_ips_by_fixed_address": [],
    "network:allocate_floating_ip": [],
    "network:deallocate_floating_ip": [],
    "network:associate_floating_ip": [],
    "network:disassociate_floating_ip": [],

    "network:get_fixed_ip": [],
    "network:get_fixed_ip_by_address": [],
    "network:add_fixed_ip_to_instance": [],
    "network:remove_fixed_ip_from_instance": [],
    "network:add_network_to_project": [],
    "network:get_instance_nw_info": [],

    "network:get_dns_domains": [],
    "network:add_dns_entry": [],
    "network:modify_dns_entry": [],
    "network:delete_dns_entry": [],
    "network:get_dns_entries_by_address": [],
    "network:get_dns_entries_by_name": [],
    "network:create_private_dns_domain": [],
    "network:create_public_dns_domain": [],
    "network:delete_dns_domain": []
}' > /etc/nova/policy.json

export LD_LIBRARY_PATH=/lib

# get an image
imgadm update
imgadm import f9e4be48-9466-11e1-bc41-9f993f5dff36
zfs snapshot zones/f9e4be48-9466-11e1-bc41-9f993f5dff36@now
zfs send zones/f9e4be48-9466-11e1-bc41-9f993f5dff36@now > /zones/workspace/smartos.img

export LD_LIBRARY_PATH=/ec/lib/
cd /zones/workspace/nova/
echo "You can now run:"
echo "./bin/nova-compute"
echo "./bin/nova-network"

echo "execute on the devstack machine:"
echo "glance image-create --name 'smartos' --is-public 'true' --container-format 'bare' --disk-format 'raw' --property 'zone=true' < smartos.img"
echo "nova boot --flavor=m1.tiny --image=smartos testserver"
