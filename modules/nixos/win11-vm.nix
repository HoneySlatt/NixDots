{ config, lib, pkgs, ... }:

# Windows 11 VM with single GPU passthrough: starting it stops the host
# graphical session, stopping it brings niri back through greetd.

let
  name   = "win11";
  images = "/var/lib/libvirt/images";
  disk   = "${images}/${name}.img";
  iso    = "${images}/${name}.iso";

  # Host cores 1-7 (threads 1-7 + 9-15) go to the guest, core 0 (0,8) stays for the host.
  vcpuPins = lib.concatMapStringsSep "\n" (i:
    let core = i / 2 + 1; in
    "    <vcpupin vcpu='${toString i}' cpuset='${toString (if lib.mod i 2 == 0 then core else core + 8)}'/>"
  ) (lib.range 0 13);

  usbPassthrough = vendor: product: ''
    <hostdev mode='subsystem' type='usb'>
      <source startupPolicy='optional'>
        <vendor id='${vendor}'/>
        <product id='${product}'/>
      </source>
    </hostdev>'';

  # Local account without Microsoft login, minimal privacy settings.
  autounattend = pkgs.writeText "autounattend.xml" ''
    <?xml version="1.0" encoding="utf-8"?>
    <unattend xmlns="urn:schemas-microsoft-com:unattend" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
      <settings pass="specialize">
        <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
          <RunSynchronous>
            <RunSynchronousCommand wcm:action="add">
              <Order>1</Order>
              <Path>reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" /v BypassNRO /t REG_DWORD /d 1 /f</Path>
            </RunSynchronousCommand>
          </RunSynchronous>
        </component>
      </settings>
      <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
          <OOBE>
            <HideEULAPage>true</HideEULAPage>
            <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
            <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
            <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
            <ProtectYourPC>3</ProtectYourPC>
          </OOBE>
          <UserAccounts>
            <LocalAccounts>
              <LocalAccount wcm:action="add">
                <Name>Honey</Name>
                <Group>Administrators</Group>
                <Password>
                  <Value></Value>
                  <PlainText>true</PlainText>
                </Password>
              </LocalAccount>
            </LocalAccounts>
          </UserAccounts>
        </component>
      </settings>
    </unattend>
  '';

  # Setup picks up autounattend.xml and $WinPEDriver$ from the root of any attached media.
  unattendIso = pkgs.runCommand "${name}-unattend.iso" { nativeBuildInputs = [ pkgs.xorriso ]; } ''
    mkdir -p root/'$WinPEDriver$'
    cp ${autounattend} root/autounattend.xml
    cp -r ${pkgs.virtio-win}/viostor/w11/amd64 root/'$WinPEDriver$'/viostor
    cp -r ${pkgs.virtio-win}/NetKVM/w11/amd64 root/'$WinPEDriver$'/NetKVM
    xorriso -as mkisofs -J -joliet-long -r -V UNATTEND -o $out root
  '';

  domainXml = pkgs.writeText "${name}.xml" ''
    <domain type='kvm'>
      <name>${name}</name>
      <uuid>c9512b88-5a0b-413e-ad2c-06b1f5b44b4f</uuid>
      <memory unit='GiB'>16</memory>
      <currentMemory unit='GiB'>16</currentMemory>
      <vcpu placement='static'>14</vcpu>
      <iothreads>1</iothreads>
      <cputune>
    ${vcpuPins}
        <emulatorpin cpuset='0,8'/>
        <iothreadpin iothread='1' cpuset='0,8'/>
      </cputune>
      <os>
        <type arch='x86_64' machine='q35'>hvm</type>
        <loader readonly='yes' secure='yes' type='pflash' format='raw'>${pkgs.OVMFFull.firmware}</loader>
        <nvram template='${pkgs.OVMFFull.variablesMs}' templateFormat='raw' format='raw'>/var/lib/libvirt/qemu/nvram/${name}_VARS.fd</nvram>
        <smbios mode='host'/>
      </os>
      <features>
        <acpi/>
        <apic/>
        <hyperv mode='custom'>
          <relaxed state='on'/>
          <vapic state='on'/>
          <spinlocks state='on' retries='8191'/>
          <vpindex state='on'/>
          <runtime state='on'/>
          <synic state='on'/>
          <stimer state='on'>
            <direct state='on'/>
          </stimer>
          <reset state='on'/>
          <vendor_id state='on' value='AuthenticAMD'/>
          <frequencies state='on'/>
          <reenlightenment state='on'/>
          <tlbflush state='on'/>
          <ipi state='on'/>
        </hyperv>
        <kvm>
          <hidden state='on'/>
        </kvm>
        <vmport state='off'/>
        <smm state='on'/>
        <ioapic driver='kvm'/>
      </features>
      <cpu mode='host-passthrough' check='none' migratable='off'>
        <topology sockets='1' dies='1' cores='7' threads='2'/>
        <cache mode='passthrough'/>
        <feature policy='require' name='topoext'/>
      </cpu>
      <clock offset='localtime'>
        <timer name='rtc' tickpolicy='catchup'/>
        <timer name='pit' tickpolicy='delay'/>
        <timer name='hpet' present='no'/>
        <timer name='hypervclock' present='yes'/>
        <timer name='tsc' present='yes' mode='native'/>
      </clock>
      <on_poweroff>destroy</on_poweroff>
      <on_reboot>restart</on_reboot>
      <on_crash>destroy</on_crash>
      <pm>
        <suspend-to-mem enabled='no'/>
        <suspend-to-disk enabled='no'/>
      </pm>
      <devices>
        <disk type='file' device='disk'>
          <driver name='qemu' type='raw' cache='none' io='native' discard='unmap' iothread='1'/>
          <source file='${disk}'/>
          <target dev='vda' bus='virtio'/>
          <boot order='1'/>
        </disk>
        <disk type='file' device='cdrom'>
          <driver name='qemu' type='raw'/>
          <source file='${iso}' startupPolicy='optional'/>
          <target dev='sda' bus='sata'/>
          <readonly/>
          <boot order='2'/>
        </disk>
        <disk type='file' device='cdrom'>
          <driver name='qemu' type='raw'/>
          <source file='${pkgs.virtio-win.src}'/>
          <target dev='sdb' bus='sata'/>
          <readonly/>
        </disk>
        <disk type='file' device='cdrom'>
          <driver name='qemu' type='raw'/>
          <source file='${unattendIso}'/>
          <target dev='sdc' bus='sata'/>
          <readonly/>
        </disk>
        <controller type='usb' model='qemu-xhci' ports='15'/>
        <interface type='network'>
          <mac address='52:54:00:2a:b8:99'/>
          <source network='default'/>
          <model type='virtio'/>
        </interface>
        <tpm model='tpm-crb'>
          <backend type='emulator' version='2.0'/>
        </tpm>
        <hostdev mode='subsystem' type='pci' managed='yes'>
          <source>
            <address domain='0x0000' bus='0x0d' slot='0x00' function='0x0'/>
          </source>
        </hostdev>
        <hostdev mode='subsystem' type='pci' managed='yes'>
          <source>
            <address domain='0x0000' bus='0x0d' slot='0x00' function='0x1'/>
          </source>
        </hostdev>
        ${usbPassthrough "0x046d" "0xc547"}
        <!-- CPU USB controller (keyboard): native xHCI, full polling rate -->
        <hostdev mode='subsystem' type='pci' managed='yes'>
          <source>
            <address domain='0x0000' bus='0x0f' slot='0x00' function='0x3'/>
          </source>
        </hostdev>
        ${usbPassthrough "0x1235" "0x8210"}
        <video>
          <model type='none'/>
        </video>
        <memballoon model='none'/>
      </devices>
    </domain>
  '';

  bootKey = pkgs.writeShellScript "${name}-boot-key" ''
    export PATH=${lib.makeBinPath [ config.virtualisation.libvirtd.package pkgs.coreutils ]}
    sleep 2
    for _ in $(seq 15); do
      virsh -c qemu:///system send-key ${name} KEY_ENTER
      sleep 1
    done
  '';

  hook = pkgs.writeShellScript "${name}-hook" ''
    export PATH=${lib.makeBinPath [ config.systemd.package pkgs.coreutils pkgs.psmisc ]}
    [ "$1" = "${name}" ] || exit 0

    gpu=/dev/dri/by-path/pci-0000:0d:00.0

    pinHost() {
      for unit in system.slice user.slice init.scope; do
        systemctl set-property --runtime -- "$unit" AllowedCPUs="$1"
      done
    }

    case "$2/$3" in
      prepare/begin)
        systemctl stop greetd.service ollama.service lactd.service
        systemctl --user -M honey@ stop graphical-session.target
        for _ in $(seq 20); do
          fuser -s "$gpu-card" "$gpu-render" /dev/kfd || break
          sleep 0.5
        done
        fuser -k "$gpu-card" "$gpu-render" /dev/kfd
        sleep 1
        for vt in /sys/class/vtconsole/vtcon*/bind; do echo 0 > "$vt"; done
        pinHost 0,8
        ;;
      started/begin)
        # Firmware ignores the passed-through keyboard: press Enter on the emulated PS/2
        # keyboard for the "boot from CD" prompt while Windows is not installed yet.
        # Run detached since hooks must not call back into libvirt.
        if [ "$(du -k ${disk} | cut -f1)" -lt 1048576 ]; then
          systemd-run --no-block --collect --unit=${name}-boot-key ${bootKey}
        fi
        ;;
      release/end)
        pinHost 0-15
        for vt in /sys/class/vtconsole/vtcon*/bind; do echo 1 > "$vt"; done
        systemctl start lactd.service ollama.service greetd.service
        ;;
    esac
    exit 0
  '';
in
{
  boot.kernelParams = [ "iommu=pt" ];
  boot.kernelModules = [ "kvm-amd" ];

  users.users.honey.extraGroups = [ "libvirtd" ];

  virtualisation.libvirtd = {
    hooks.qemu.${name} = hook;
    # Never save/resume the VM across host reboots: a resumed VM grabs the GPU at boot.
    onBoot = "ignore";
    onShutdown = "shutdown";
    shutdownTimeout = 60;
  };

  # Hooks are only symlinked by this unit, refresh them when the hook changes.
  systemd.services.libvirtd-config.restartTriggers = [ hook ];

  # Group-writable so the Windows ISO can be dropped in without sudo.
  systemd.tmpfiles.rules = [ "d ${images} 0775 root libvirtd -" ];

  systemd.services."${name}-define" = {
    description = "Define the Windows 11 libvirt domain";
    after = [ "libvirtd.service" ];
    requires = [ "libvirtd.service" ];
    wantedBy = [ "multi-user.target" ];
    restartTriggers = [ domainXml ];
    path = [ config.virtualisation.libvirtd.package pkgs.e2fsprogs pkgs.coreutils ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    # No copy-on-write on btrfs for the raw image.
    script = ''
      if [ ! -e ${disk} ]; then
        touch ${disk}
        chattr +C ${disk}
        truncate -s 150G ${disk}
      fi
      virsh -c qemu:///system define ${domainXml}
    '';
  };
}
