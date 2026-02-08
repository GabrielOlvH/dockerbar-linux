# DockerBar

Docker container health monitor for [DankMaterialShell](https://github.com/nicko-coder/DankMaterialShell) (DMS/niri).

![Bun](https://img.shields.io/badge/runtime-Bun-f9f1e1?logo=bun)
![TypeScript](https://img.shields.io/badge/lang-TypeScript-3178c6?logo=typescript&logoColor=white)

## What it does

- Monitors local and remote Docker hosts
- Groups containers by **compose project**
- Shows health status, ports, service names, and uptime
- Remote host monitoring via SSH

## Pill

`dns` icon + running/total count (e.g. `10/10`). Green when all healthy, red when any unhealthy/stopped. Shows an unhealthy count badge when containers need attention.

## Popout

Containers grouped by compose project per host, with colored health sidebar, service names, port mappings, and uptime.

## Setup

```bash
bun install
```

### CLI

```bash
# Local containers only
bun run src/index.ts --local

# Remote host via SSH
bun run src/index.ts --remote --host root@your-server --key ~/.ssh/id_rsa

# Both (default)
bun run src/index.ts --all
```

### DMS Plugin

Copy `plugin/` to `~/.config/DankMaterialShell/plugins/DockerBar/` and add the widget to your bar.

Configure the remote host and SSH key in the plugin settings.

## Architecture

Bun TypeScript backend outputs JSON to stdout, consumed by the QML plugin via `Proc.runCommand`.
