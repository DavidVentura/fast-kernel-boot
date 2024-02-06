This repo contains a minimal config for the Linux kernel (6.7.3) that only enables:
 - VirtIO devices
 - Ext4
 - IP stack (with autoconfig)

There's a no-smp and an smp config. no-smp boots a bit faster but limits you to 1 CPU.

On my laptop, no-smp boots to PID1 in 10ms.

There are also 2 patches:

- A patch for the kernel (`linux_sleep.patch`) to disable a 10-20ms wait on IP autoconfig
- A patch for firecracker (`firecracker.patch`) to pass the `MAP_HUGETLB` flag to `mmap` for fewer page faults (3-4ms of boot time was spent on page fault handling).
