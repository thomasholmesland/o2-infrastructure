
## Lag `docs/CHANGELOG.md`

Kopier og lim inn:

```bash
cat > docs/CHANGELOG.md <<'EOF'
# Production Change Log

Denne filen dokumenterer endringer som påvirker produksjonsmiljøet for O2 Method.

Hver endring skal inneholde:

- dato og klokkeslett
- hvem som utførte endringen
- hva som ble endret
- hvorfor endringen ble utført
- hvordan endringen ble verifisert
- eventuell rollback-prosedyre

---

## 2026-07-28

**Utført av:** Thomas Holmesland

### Endringer

- Produksjonsmiljøet ble kartlagt.
- VM-ressurser og operativsystem ble dokumentert.
- Docker Compose-prosjektet ble identifisert.
- Persistent PostgreSQL-lagring ble identifisert.
- Containerenes restart-policy ble kontrollert.
- Cloudflare Tunnel ble identifisert som ekstern tilgangsmetode.
- Daglig databasebackup ble identifisert og kontrollert.
- Produksjonsrisikoer og forbedringspunkter ble dokumentert.

### Verifisering

- Alle tolv produksjonscontainere kjørte.
- Supabase-tjenestene rapporterte healthy.
- PostgreSQL-data var persistent montert fra verten.
- Backupfiler eksisterte.
- Backup-loggen viste vellykkede kjøringer.

### Rollback

Ingen produksjonsendringer ble utført. Kun lesende kartlegging og dokumentasjon.

---

## Mal for nye endringer

Kopier seksjonen under ved fremtidige endringer:

```text
## YYYY-MM-DD HH:MM

**Utført av:**

### Endring

Beskriv hva som ble endret.

### Begrunnelse

Beskriv hvorfor endringen var nødvendig.

### Før endringen

Beskriv kontrollert backup, status og forutsetninger.

### Verifisering

Beskriv hvordan det ble bekreftet at endringen fungerte.

### Rollback

Beskriv hvordan endringen kan reverseres.

### Resultat

Vellykket / reversert / delvis gjennomført.
