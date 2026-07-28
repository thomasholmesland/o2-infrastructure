# O2 Method Production Environment

**Status:** Production  
**Criticality:** High  
**Owner:** Thomas Holmesland  
**Last updated:** 2026-07-28

---

## Overview

Denne serveren kjører O2 Method-plattformen som benyttes av betalende kunder.

Serveren skal behandles som et produksjonsmiljø. Ingen eksperimentering, testing eller utvikling skal utføres direkte på denne VM-en.

---

## Infrastructure

| Felt | Verdi |
|---|---|
| Hostname | `o2method-app` |
| Virtualisering | KVM / Proxmox |
| Operativsystem | Debian GNU/Linux 13 (Trixie) |
| Kernel | Linux 6.12.96+deb13-cloud-amd64 |
| Arkitektur | x86-64 |
| vCPU | 4 |
| RAM | 8 GB |
| Disk | 40 GB |
| Swap | Ingen |

---

## Network

| Felt | Verdi |
|---|---|
| Internt IP-adresse | `192.168.1.161` |
| Adressemetode | DHCP |
| Ekstern publisering | Cloudflare Tunnel |
| Tunnel-service | `cloudflared.service` |

Det er ikke funnet Nginx, Traefik, Caddy eller Apache på verten.

Cloudflare Tunnel publiserer applikasjonen eksternt uten tradisjonell port forwarding.

### Porter som lytter på verten

| Port | Tjeneste |
|---|---|
| 22 | SSH |
| 3000 | O2 Method-app |
| 5432 | PostgreSQL |
| 6543 | Supavisor connection pooler |
| 8000 | Supabase Kong HTTP |
| 8443 | Supabase Kong HTTPS |

Portene er publisert av Docker på alle nettverksgrensesnitt. Om de er tilgjengelige utenfor lokalnettet avhenger av ruter- og brannmurkonfigurasjon.

---

## Docker

Compose-arbeidsmappe:

```text
/home/o2admin/supabase/docker

Compose-filer:
/home/o2admin/supabase/docker/docker-compose.yml
/home/o2admin/supabase/docker/docker-compose.override.yml

Compose-prosjekt:
supabase

Restart-policy:
unless-stopped

Running services

Produksjonsmiljøet består av følgende containere:

Container	Funksjon
supabase-app-1	O2 Method-applikasjon
supabase-auth	Autentisering
supabase-studio	Supabase Studio
supabase-edge-functions	Edge Functions
supabase-storage	Fillagring
realtime-dev.supabase-realtime	Realtime
supabase-meta	PostgreSQL metadata
supabase-pooler	Database connection pooler
supabase-kong	API gateway
supabase-rest	PostgREST
supabase-db	PostgreSQL
supabase-imgproxy	Bildeprosessering

Database

Databaseplattform:

PostgreSQL 17.6.1

Container:

supabase-db

Persistent datamappe på verten:

/home/o2admin/supabase/docker/volumes/db/data

Mount inne i containeren:

/var/lib/postgresql/data

Docker storage

Navngitte Docker-volumer:

supabase_db-config
supabase_deno-cache

Docker-diskbruk ved kartlegging:

Område	Bruk
Images	9.325 GB
Containere	247.5 MB
Lokale volumes	527.3 kB
Build cache	14.71 GB
Frigjørbar build cache	14.49 GB

Backups

Backupscript:

/home/o2admin/backup-db.sh

Backupmappe:

/home/o2admin/backups

Loggfil:

/home/o2admin/backups/backup.log

Kjøretid:

Daglig klokken 03:00 UTC

Backupmetode:

pg_dumpall

Format:

.sql.gz

Filnavn:

o2method-db-YYYYMMDD-HHMMSS.sql.gz

Retention:

14 dager

Backupscriptet:

Leser POSTGRES_PASSWORD fra /home/o2admin/supabase/docker/.env.
Kjører pg_dumpall i supabase-db.
Komprimerer SQL-dumpen med gzip.
Lagrer filen i /home/o2admin/backups.
Sletter databasebackuper eldre enn 14 dager.
Logger resultat og filstørrelse.
Bekreftet status

Daglige backuper finnes og backup-loggen viser vellykkede kjøringer.

Begrensninger
Backupene ligger på samme VM som produksjonsdatabasen.
Det finnes foreløpig ingen bekreftet offsite-kopi.
Restore er ikke testet.
Databasebackupen dekker ikke nødvendigvis Storage-filer, .env, Compose-filer, Edge Functions eller Cloudflare-konfigurasjon.Deployment

Applikasjonscontainer:

supabase-app-1

Image:

supabase-app

Compose working directory:

/home/o2admin/supabase/docker

Eksakt deployment-prosess er ennå ikke dokumentert.

Følgende må kartlegges:

hvordan ny kode hentes
hvordan app-imaget bygges
hvilke kommandoer som brukes ved deployment
hvordan rollback utføres
hvor kildekoden ligger
om deployment skjer manuelt eller automatisk
Monitoring

Eksisterende:

Docker restart-policy
backup-logg
Cloudflare Tunnel-service

Planlagt fra o2-core:

ekstern HTTPS-overvåkning av app.o2method.com
diskbruk
CPU-bruk
RAM-bruk
Docker-containerstatus
PostgreSQL-status
Cloudflare Tunnel-status
backupens alder
SSL-sertifikat
Disaster recovery objectives

Recovery Time Objective, RTO:

Mål: under 30 minutter

Recovery Point Objective, RPO:

Foreløpig: maksimalt 24 timer

Disse målene er ikke verifisert før en full restore-test er gjennomført.

Production rules
Skal aldri gjøres uten planlagt vedlikehold
teste ny programvare direkte på produksjons-VM-en
oppgradere Docker eller Supabase uten backup og rollback-plan
endre Compose-filer uten å dokumentere endringen
endre .env uten sikker kopi
slette Docker-volumer
kjøre docker system prune ukritisk
stoppe databasecontaineren uten vurdering av konsekvens
utføre restore direkte mot produksjonsdatabasen som test
Skal alltid gjøres
kontrollere siste backup før endringer
dokumentere produksjonsendringer
kontrollere containerstatus etter deployment
verifisere app.o2method.com etter endringer
ha en rollback-plan
teste restore i et separat miljø
Known risks
Kritisk
Backup finnes kun på samme VM.
Restore er ikke testet.
Middels
LAN-adressen er tildelt via DHCP.
Databasen og Supabase-portene lytter på alle vertsgrensesnitt.
Produksjonsdisken er bare 40 GB.
VM-en har ingen swap.
Build cache bruker omtrent 14.7 GB.
Ukjent
Backup av Supabase Storage-filer.
Backup av .env og secrets.
Backup av Compose-konfigurasjon.
Backup av Cloudflare Tunnel-konfigurasjon.
Full deployment- og rollback-prosess.
Proxmox VM-backup.
Ekstern eller offsite-backup.
Improvement roadmap
Dokumentere komplett deployment-prosess.
Dokumentere alle persistente mapper og filer.
Kopiere databasebackup automatisk til o2-core.
Etablere ekstern offsite-backup.
Teste database-restore på separat VM.
Dokumentere full katastrofegjenoppretting.
Overvåke produksjons-VM-en fra o2-core.
Opprette DHCP-reservasjon for 192.168.1.161.
Vurdere begrensning av lokalt eksponerte databaseporter.
Etablere periodisk Proxmox-backup av hele VM-en.

Production boundary

Denne VM-en skal kun brukes til produksjon av O2 Method.

Følgende skal ligge på andre systemer:

overvåkning
dokumentasjonsgenerering
eksperimentering
utviklingsmiljø
AI-tjenester
backupadministrasjon
testing av restore
