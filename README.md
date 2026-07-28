# O2 Infrastructure

Infrastructure-as-Code repository for the O2 Method homelab, development environment and future application platform.

The platform is designed to begin as an internal coaching and automation environment, while retaining a clear migration path toward a hosted multi-tenant SaaS platform.

## Architecture

```text
Proxmox VE
├── Home Assistant VM
├── o2method-app LXC
└── o2-core VM
    ├── Ubuntu Server 24.04 LTS
    ├── Docker Engine
    ├── Docker Compose
    ├── Tailscale
    └── Docker services
        └── Portainer CE

## Automatisk generert driftsdokumentasjon

Den faktiske servertilstanden dokumenteres automatisk her:

- [Generert infrastrukturoversikt](docs/generated/README.md)

Dokumentasjonen genereres fra Docker, Compose og systemd med:

```bash
./scripts/generate-docs.sh



