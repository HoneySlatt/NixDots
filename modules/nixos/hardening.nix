{
  # Blocks kexec and hibernation, so a running kernel cannot be replaced
  security.protectKernelImage = true;

  # Only wheel members may even execute sudo
  security.sudo.execWheelOnly = true;

  boot.kernel.sysctl = {
    # Hide kernel pointers from everyone, root included
    "kernel.kptr_restrict" = 2;
    "net.core.bpf_jit_harden" = 2;
    # No core dumps of setuid programs
    "fs.suid_dumpable" = 0;

    # Ignore ICMP redirects and never send them (rp_filter stays loose for the VPN)
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.secure_redirects" = 0;
    "net.ipv4.conf.default.secure_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
  };
}
