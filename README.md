# mountperms
A simple way to test &amp; compare various OCI runtime behavior for mountpoint ownership &amp; permissions.


This project uses a sequence of containers and volumes to determine an OCI runtimes behavior with respect to volume permissions.

There are several factors that can contribute to the permissions/ownership seen at runtime. 

- Is this the first container this volume has been mounted to?
- Does the mountpoint exist within the container the volume is mounted to?
- The executing uid/gid of the container


## Process:

With either `docker` or `podman` on your path, run `./test_runtime.sh` (if both are available, it is assumed you have podman, with docker emulation)

The script will build a simple image with a couple of users, and a selection of mountpoints, and will then work through mounting volumes to containers created from the image, noting the ownership (permissions to follow later!!) of the mountpoint in each step.


## Output:

Collected output from systems:

| Client version | Honor ownership for fresh volumes | Honor ownership for reused volumes | Ownership of fresh vol mounted at non-existing mountpoint | Ownership for reused vol with non-existing mountpoint | Ownership for reused vol initially mounted to non-existing mountpoint |
| --- | --- | --- | --- | --- | --- |
| Docker Engine - Community : 24.0.7 | Yes | Yes | Root           | Last Assigned  | Last Assigned  |
| Podman(rootless) : 4.7.0           | Yes | No  | Executing User | First Assigned | First Assigned |
| Podman(rootless) : 4.9.5           | Yes | No  | Executing User | First Assigned | First Assigned | 
| Podman(rootless) : 5.2.5           | Yes | Yes | Executing User | Last Assigned | Last Assigned | |

Notes:
### Honor ownership for fresh volumes
Does a newly created volume, mounted to a directory that exists within the container, result in the mountpoint having the ownership of the existing directory? (Yes/No)

This is just testing "Normal" behaviour, that many containers rely upon. As a container author, you need to be able to control the ownership/permissions that volumes are mounted at, and this is traditionally done by including the mountpoint within the image with the expected ownership/permissions.
 
### Honor ownership for reused volumes
Does a volume that has been previously mounted, when mounted to a directory that exists within the container, result in the mountpoint having the ownership of the existing directory? (Yes/No)

This is testing that regardless of if a volume has been mounted previously to a different container, that when mounted to a mountpoint that DOES exist within the current container, that the current containers permissions are used. Without this being true, it becomes impossible for container authors to know they will ever be able to access mounted volumes, unless they execute within the container as root, which is usually considered unsafe.

### Ownership of fresh volumes mounted at non-existing mountpoints
Who has ownership of a mountpoint created by mounted a newly created volume to a non-existing directory within a container (Root/Executing User)

This is testing the behavior when mounting at mountpoints that do not exist. Since the container author has not specified ownership for the mountpoint, it is left to runtime to decide the ownership & permissions. Options include (but are not limited to!) the mountpoint being owned by the root user, or by the executing user.

### Ownership for reused vol with non-existing mountpoint
When mounting a previously mounted volume to a container, that was initially mounted to an existing directory, is the ownership from the last mounted occurrence, or from the initial mounted directory for the volume? (Last Assigned|First Assigned)

This test looks at a volume that has been mounted three times, the first two times to existing directories, and the last to a non-existing one. The test is looking to see if the volume is retaining ownership from the last time it was mounted, or if it retains its initially determined ownership for all future mounts. 

### Ownership for reused vol initially mounted to non-existing mountpoint
When mounting a previously mounted volume to a container, that was initially mounted to an non-existing directory, is the ownership from the last mounted occurrence, or from the initial ownership for the volume? (Last Assigned|First Assigned)

This test looks at a volume that has been mounted three times, the first time to a non-existing mountpoint, the second to an existing, and finally to a non-existing one. The test is looking to see if the volume is retaining ownership from the last time it was mounted, or if it retains its initially determined ownership for all future mounts.
