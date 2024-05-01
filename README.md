# mountperms
A simple way to test &amp; compare various OCI runtime behavior for mountpoint ownership &amp; permissions.


This project uses a sequence of containers and volumes to determine an OCI runtimes behavior with respect to volume permissions.

There are several factors that can contribute to the permissions/ownership seen at runtime. 

- Is this the first container this volume has been mounted to?
- Does the mountpoint exist within the container the volume is mounted to?
- The executing uid/gid of the container

