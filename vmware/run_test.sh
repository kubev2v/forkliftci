

uri="nbd+unix:///?socket=/tmp/nbd2.sock"
nbdkit --foreground --readonly --exit-with-parent -U /tmp/nbd2.sock --pidfile /tmp/nbd2.pid --filter=retry --filter=cacheextents vddk libdir=/opt/vmware-vix-disklib-distrib server=localhost user=user thumbprint=2C:11:ED:D7:13:87:7D:B5:74:18:B8:1C:42:C2:56:1F:0D:B9:5B:B9 vm=moref=vm-22 --verbose -D nbdkit.backend.controlpath=0 -D nbdkit.backend.datapath=0 file=[teststore] testvm/testvm.vmdk password=pass &

sleep 2
nbdinfo --size $uri

#cleanup
kill -9 $(cat /tmp/nbd2.pid)
rm -rf /tmp/nbd2.sock
