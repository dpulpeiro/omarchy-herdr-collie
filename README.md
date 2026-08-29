# Omarchy Collie

An Omarchy bar widget for [Collie](https://github.com/AltanS/collie), the mobile web UI for Herdr.

The widget shows whether both the Collie user service and its Tailscale Serve endpoint are active. Its panel displays the tailnet URL and can enable or disable both components together.

## Requirements

- Omarchy with the Quattro shell plugin system
- Collie installed as the `herdr.collie` Herdr plugin
- The `collie.service` systemd user unit created by Collie
- Tailscale with Serve enabled
- Bash, systemd, and `awk`

The plugin runs unsandboxed with your user permissions. Enabling it starts `collie.service` and publishes Collie's loopback port through tailnet-only Tailscale Serve. Disabling it removes the HTTPS port 443 Serve mapping and stops the service. It never enables Tailscale Funnel.

## Install

From GitHub:

```sh
omarchy plugin add https://github.com/dpulpeiro/omarchy-collie.git --enable
```

For local development:

```sh
omarchy plugin add ~/Documents/dpulpeiro/omarchy-collie --enable
```

Place it near the Tailscale widget:

```sh
omarchy bar move io.github.dpulpeiro.collie --after omarchy.tailscale
```

## Usage

Click the Collie icon to open its panel. The icon is green when both the service and tailnet endpoint are active, dim when both are disabled, and urgent-colored when only one is active.

Click the displayed tailnet URL to open Collie. Use the panel button to enable or disable the service and endpoint together.

## Configuration

Collie's default loopback port is `8787`. To use a different port, expose `COLLIE_PORT` in the Omarchy shell environment before loading the plugin.

## Validate

```sh
omarchy plugin validate .
qmllint -I /usr/share/omarchy/shell BarWidget.qml Panel.qml
bash -n scripts/collie-control
```

## Remove

```sh
omarchy plugin remove io.github.dpulpeiro.collie
```

Removing this widget does not stop or uninstall Collie.

## License

MIT
