{ variables, ... }:
{
  vpnNamespaces.wg = { # The name is limited to 7 characters
    enable = true;
    wireguardConfigFile = "${variables.wireguard_config_path}";
    accessibleFrom = [
      "192.168.0.0/24"
    ];
    portMappings = [{
      from = 9091; # port on host
      to = 9091; # port in VPN network namespace
      protocol = "tcp"; # protocol = "tcp"(default), "udp", or "both"
    }];
    openVPNPorts = [{
      port = 60729; # port to access through VPN interface
      protocol = "both"; # protocol = "tcp"(default), "udp", or "both"
    }];
  };

  # Add systemd service to VPN network namespace.
  systemd.services.transmission.vpnConfinement = {
    enable = true;
    vpnNamespace = "wg";
  };

  services.transmission = {
    enable = true;
    settings = {
      "rpc-bind-address" = "192.168.15.1"; # Bind RPC to vpn namespace address
      "rpc-whitelist" = "192.168.15.5"; # Allow WebUI access from bridge on the default namespace
    };
  };
}
