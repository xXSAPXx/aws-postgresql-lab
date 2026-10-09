# labapp: the lab's simulated application

`labapp` plays the application in every lab. It runs on the PMM server, connects to the databases over the network like an application server, and measures what the application experiences while you do DBA work: restarts, failovers, maintenance, broken configurations.

It is installed and started by the Ansible role [`labapp`](../../ansible/roles/labapp/). Today it has one part, the **probe**; a realistic **workload** (orders, reports, varying traffic) is planned next.

## The probe

The `labapp-probe` service checks every database target continuously:

| Check | How | Default |
|---|---|---|
| **write** | Writes a heartbeat row (`INSERT ... ON CONFLICT`) on a persistent connection | every 0.25 s |
| **connect** | Opens a new connection and runs `SELECT 1`, like a reconnecting application | every 1 s |

A failed **write** check is downtime, also when the server still accepts reads (for example a primary demoted to replica). An outage starts at the first failed write and ends at the next successful one, so durations are accurate to about 0.25 s. Every connection attempt and statement gives up after 2 s, so a hung or unreachable server counts as down instead of stalling the probe.

For each outage, the probe:

- writes a line to `/var/log/labapp/outages.jsonl`;
- logs its start and end to the journal (`journalctl -u labapp-probe`);
- adds an annotation (a red time range) in PMM, on the **Lab: Application probe** dashboard and on PMM's own dashboards of that service.

## Commands

On the PMM server:

```bash
labapp outages              # the measured outages: start, end, duration, first error
labapp outages --last 5
journalctl -u labapp-probe -f
```

Example after `systemctl restart postgresql-17` and a 10-second stop:

```
  #  target               start (UTC)              end (UTC)                 duration  first error
  1  postgresql-source    2026-10-09T17:26:38.280  2026-10-09T17:26:39.551     1.271s  AdminShutdown: terminating connection due to administrator command
  2  postgresql-source    2026-10-09T17:26:46.784  2026-10-09T17:26:57.308    10.524s  AdminShutdown: terminating connection due to administrator command

2 outages, 11.795 s of write downtime in total.
```

## Metrics

Served on port 9300 (`/metrics`) and collected by PMM as the external service `labapp-probe`:

| Metric | Meaning |
|---|---|
| `labapp_probe_up{target, check}` | 1 if the last check succeeded |
| `labapp_probe_latency_seconds{target, check}` | Histogram of successful check durations |
| `labapp_probe_checks_total{target, check, result}` | Checks run, `result` = ok / error |
| `labapp_probe_outages_total{target}` | Completed write outages |
| `labapp_probe_downtime_seconds_total{target}` | Total write downtime |
| `labapp_probe_current_outage_seconds{target}` | Duration of the ongoing outage, 0 when up |
| `labapp_probe_last_outage_seconds{target}` | Duration of the last completed outage |

The probe's own table, `labapp_probe` in the `labapp` database, holds one heartbeat row per probe and target.
