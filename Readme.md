There are two public repositories related to this:

* https://github.com/dstroppa/openstack-smartos-nova-grizzly
* https://github.com/dstroppa/openstack-smartos-bootstrap

On the SmartOS machine execute:

	imgadm update	
	imgadm import f9e4be48-9466-11e1-bc41-9f993f5dff36
	zfs snapshot zones/f9e4be48-9466-11e1-bc41-9f993f5dff36@image	
	zfs send zones/f9e4be48-9466-11e1-bc41-9f993f5dff36@image > /zones/workspace/smartos.img

and then:

	glance image-create --name 'smartos' --is-public 'true' --container-format 'bare' --disk-format 'raw' --property 'zone=true' < smartos.img

Get the OS metadata service running:

1. Add these options to `compute.conf`: `metadata_listen=169.254.169.254` and `metadata_listen_port=80`
2. Configure metadata interface like this:

		dladm create-vnic -l e1000g0 meta0
		ifconfig meta0 plumb
		ifconfig meta0 169.254.169.254/32
		ifconfig meta0 up

3. Then start `/openstack/nova/bin/nova-api-metadata --config-file=/openstack/cfg/compute.conf` in the global (compute) zone

4. When booting VMs I currently force the default route IP to be the IP of the compute zone, so that the metadata IP is reachable

Using this approach I was able to boot a standard ubuntu cloud image. It got all the meta data info that it needed.

I'm not sure if this approach is the right one but it seems to be better than the linux iptables NATtting stuff. And it works :)

At this point the next step would be to get the actual network stuff working. As I said I'd like to go with quantum and a  special VLANManager for Crossbow at first. VLANs are the way tenant separation is handled in smartos/vmadm  so that should be the easiest way to get started.


	import sys

	from nova import flags
	from nova.openstack.common import log as logging
	from nova import service
	from nova import utils

	if __name__ == '__main__':
    	flags.parse_args(sys.argv)
	    logging.setup('nova')
    	utils.monkey_patch()
	    flags.FLAGS.compute_driver = 'smartos.virt.driver.SmartOSDriver'
    	server = service.Service.create(binary='nova-compute')
	    service.serve(server)
    	service.wait()
