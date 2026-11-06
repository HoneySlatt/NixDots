{ config, lib, pkgs, ... }:

# macOS (Tahoe) VM following OSX-KVM, as two libvirt domains over the same disk:
#   macos      emulated screen in virt-manager, for installing and repairing
#   macos-gpu  Radeon and CPU USB controller passed through, like the Windows VM
# The two share the Radeon with win11, so only one of the three runs at a time.

let
  state = "/NAS/VMs/macos";
  disk  = "${state}/mac_hdd.qcow2";
  media = "${state}/BaseSystem.img";
  nvram = "/var/lib/libvirt/qemu/nvram/macos_VARS.fd";

  osxKvm = pkgs.fetchFromGitHub {
    owner = "kholia";
    repo = "OSX-KVM";
    rev = "4c378a4b5e0b219783683012bec680325eb40719";
    hash = "sha256-BmMWWGkNtZwEH9utoc3Mj5gGCjlgIicGsTEPxAxG7hw=";
  };
  openCore = "${osxKvm}/OpenCore/OpenCore.qcow2";
  ovmfCode = "${osxKvm}/OVMF_CODE_4M.fd";
  ovmfVars = "${osxKvm}/OVMF_VARS-1920x1080.fd";

  # Host cores 1-6 (threads 1-6 + 9-14) go to the guest, core 0 (0,8) stays for the host.
  vcpus = 12;
  vcpuPins = lib.concatMapStringsSep "\n" (i:
    let core = i / 2 + 1; in
    "    <vcpupin vcpu='${toString i}' cpuset='${toString (if lib.mod i 2 == 0 then core else core + 8)}'/>"
  ) (lib.range 0 (vcpus - 1));

  pciHostdev = bus: slot: function: ''
    <hostdev mode='subsystem' type='pci' managed='yes'>
      <source>
        <address domain='0x0000' bus='0x${bus}' slot='0x${slot}' function='0x${function}'/>
      </source>
    </hostdev>'';

  # OpenCore sits on SATA unit 0, the macOS disk on 1, the installer image on 2.
  sataDisk = { unit, file, type, readonly ? false, order ? null }: ''
    <disk type='file' device='disk'>
      <driver name='qemu' type='${type}' cache='writeback' discard='unmap'/>
      <source file='${file}'/>
      <target dev='sd${lib.substring unit 1 "abc"}' bus='sata'/>
      ${lib.optionalString readonly "<readonly/>"}
      ${lib.optionalString (order != null) "<boot order='${toString order}'/>"}
      <address type='drive' controller='0' bus='0' target='0' unit='${toString unit}'/>
    </disk>'';

  domainXml = { name, uuid, memoryGiB, passthrough }: pkgs.writeText "${name}.xml" ''
    <domain type='kvm' xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>
      <name>${name}</name>
      <uuid>${uuid}</uuid>
      <memory unit='GiB'>${toString memoryGiB}</memory>
      <currentMemory unit='GiB'>${toString memoryGiB}</currentMemory>
      <vcpu placement='static'>${toString vcpus}</vcpu>
    ${lib.optionalString passthrough ''
      <cputune>
    ${vcpuPins}
        <emulatorpin cpuset='0,8'/>
      </cputune>''}
      <os>
        <type arch='x86_64' machine='q35'>hvm</type>
        <loader readonly='yes' type='pflash' format='raw'>${ovmfCode}</loader>
        <nvram template='${ovmfVars}' templateFormat='raw' format='raw'>${nvram}</nvram>
      </os>
      <features>
        <acpi/>
        <apic/>
        <kvm>
          <hidden state='on'/>
        </kvm>
      </features>
      <cpu mode='host-passthrough' check='none'>
        <topology sockets='1' dies='1' cores='${toString (vcpus / 2)}' threads='2'/>
      </cpu>
      <clock offset='utc'>
        <timer name='rtc' tickpolicy='catchup'/>
        <timer name='pit' tickpolicy='delay'/>
        <timer name='hpet' present='no'/>
      </clock>
      <on_poweroff>destroy</on_poweroff>
      <on_reboot>restart</on_reboot>
      <on_crash>destroy</on_crash>
      <pm>
        <suspend-to-mem enabled='no'/>
        <suspend-to-disk enabled='no'/>
      </pm>
      <devices>
        ${sataDisk { unit = 0; file = openCore; type = "qcow2"; readonly = true; order = 1; }}
        ${sataDisk { unit = 1; file = disk; type = "qcow2"; }}
        ${sataDisk { unit = 2; file = media; type = "raw"; readonly = true; }}
        <controller type='usb' model='qemu-xhci' ports='15'/>
        <interface type='network'>
          <mac address='52:54:00:c9:18:27'/>
          <source network='default'/>
          <model type='virtio'/>
          <!-- Traffic goes through the Nym VPN tunnel (MTU 1340), 1280 fits any tunnel -->
          <mtu size='1280'/>
        </interface>
        <sound model='ich9'/>
    ${if passthrough then ''
        ${pciHostdev "0d" "00" "0"}
        ${pciHostdev "0d" "00" "1"}
        <!-- CPU USB controller (keyboard, Scarlett): native xHCI -->
        ${pciHostdev "0f" "00" "3"}
        <video>
          <model type='none'/>
        </video>'' else ''
        <input type='keyboard' bus='usb'/>
        <input type='tablet' bus='usb'/>
        <graphics type='spice'>
          <listen type='none'/>
          <image compression='off'/>
          <gl enable='no'/>
        </graphics>
        <video>
          <model type='vmvga' vram='65536'/>
        </video>''}
        <memballoon model='none'/>
      </devices>
      <qemu:commandline>
        <qemu:arg value='-device'/>
        <qemu:arg value='isa-applesmc,osk=ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc'/>
        <qemu:arg value='-smbios'/>
        <qemu:arg value='type=2'/>
        <!-- The CPU string OSX-KVM validates for macOS Sequoia and Tahoe -->
        <qemu:arg value='-cpu'/>
        <qemu:arg value='Skylake-Client,-hle,-rtm,kvm=on,vendor=GenuineIntel,+invtsc,vmware-cpuid-freq=on,+ssse3,+sse4.2,+popcnt,+avx,+aes,+xsave,+xsaveopt,check'/>
      </qemu:commandline>
    </domain>
  '';

  domains = {
    macos = domainXml {
      name = "macos";
      uuid = "7f3c1d52-4b8e-4a0c-9d61-2e5a8b3c4f10";
      memoryGiB = 8;
      passthrough = false;
    };
    macos-gpu = domainXml {
      name = "macos-gpu";
      uuid = "a1d94e07-63b2-47f5-8c3e-9b0f5d7e2a68";
      memoryGiB = 16;
      passthrough = true;
    };
  };

  # The same hand-over as the Windows VM, for macos-gpu only.
  hook = pkgs.writeShellScript "macos-gpu-hook" ''
    export PATH=${lib.makeBinPath [ config.systemd.package pkgs.coreutils pkgs.psmisc pkgs.procps ]}
    [ "$1" = "macos-gpu" ] || exit 0

    gpu=/dev/dri/by-path/pci-0000:0d:00.0

    pinHost() {
      for unit in system.slice user.slice init.scope; do
        systemctl set-property --runtime -- "$unit" AllowedCPUs="$1"
      done
    }

    case "$2/$3" in
      prepare/begin)
        # Refuse before touching the session: win11 holds the Radeon.
        pgrep -f 'guest=win11' >/dev/null && exit 1
        systemctl stop display-manager.service ollama.service lactd.service
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
      release/end)
        pinHost 0-15
        for vt in /sys/class/vtconsole/vtcon*/bind; do echo 1 > "$vt"; done
        systemctl start lactd.service ollama.service display-manager.service
        ;;
    esac
    exit 0
  '';
in
{
  # macOS reads model-specific registers KVM does not know; without this it panics on AMD.
  boot.extraModprobeConfig = ''
    options kvm ignore_msrs=1 report_ignored_msrs=0
  '';

  virtualisation.libvirtd.hooks.qemu."macos-gpu" = hook;
  systemd.services.libvirtd-config.restartTriggers = [ hook ];

  systemd.services.macos-define = {
    description = "Define the macOS libvirt domains";
    after = [ "libvirtd.service" ];
    requires = [ "libvirtd.service" ];
    wantedBy = [ "multi-user.target" ];
    restartTriggers = builtins.attrValues domains;
    path = [ config.virtualisation.libvirtd.package ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = lib.concatMapStringsSep "\n"
      (xml: "virsh -c qemu:///system define ${xml}") (builtins.attrValues domains);
  };
}
