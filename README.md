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

## Production boundary

`app.o2method.com` runs on a separate production VM.

The production VM is business-critical and contains the application used by
active O2 Method customers. It is not part of the homelab development
environment.

### Production rules

- No experimental workloads are deployed to the production VM.
- No automated infrastructure scripts may modify or stop production services.
- Changes require a verified backup and a documented rollback plan.
- Development and testing must take place outside the production VM.
- Production is monitored externally from `o2-core`.
- Secrets, credentials and customer data must never be committed to Git.

### Environments

| Environment | Purpose | Change policy |
|---|---|---|
| Production | `app.o2method.com` and active customer workloads | Controlled changes only |
| Homelab | Infrastructure, integrations, AI and development | Experimental |
| Staging | Pre-production validation | To be established |
