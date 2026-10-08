{
  # Only keys that differ from their defaults; org/gnome/desktop/interface belongs to themes/apps/gtk.sh
  dconf.settings = {
    "org/gnome/nautilus/icon-view".default-zoom-level = "large";
    "org/gtk/settings/file-chooser".show-hidden = true;

    "org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu:///system" ];
      uris = [ "qemu:///system" ];
    };
    "org/virt-manager/virt-manager/confirm" = {
      delete-storage = false;
      forcepoweroff = false;
    };
  };
}
