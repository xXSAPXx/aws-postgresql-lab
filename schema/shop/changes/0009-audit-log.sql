--liquibase formatted sql

--changeset lab:0009-audit-log
--comment: BIG, partitioned by month. Old months are detached and dropped (retention); future months must exist before data arrives.
CREATE TABLE shop.audit_log (
    id           bigint GENERATED ALWAYS AS IDENTITY,
    occurred_at  timestamptz NOT NULL DEFAULT now(),
    actor        text NOT NULL,
    action       text NOT NULL,
    entity       text NOT NULL,
    entity_id    bigint,
    details      jsonb,
    PRIMARY KEY (id, occurred_at)
) PARTITION BY RANGE (occurred_at);
CREATE INDEX audit_log_entity_idx ON shop.audit_log (entity, entity_id);
--rollback DROP TABLE shop.audit_log;

--changeset lab:0009-audit-log-partitions splitStatements:false
--comment: One partition per month: the last 12 months and the next 3. No default partition: a missing month makes inserts fail, so creating future partitions on time is part of the job.
DO $$
DECLARE
    month date;
BEGIN
    FOR month IN
        SELECT generate_series(date_trunc('month', now()) - interval '12 months',
                               date_trunc('month', now()) + interval '3 months',
                               interval '1 month')::date
    LOOP
        EXECUTE format('CREATE TABLE shop.%I PARTITION OF shop.audit_log FOR VALUES FROM (%L) TO (%L)',
                       'audit_log_' || to_char(month, 'YYYY_MM'), month, (month + interval '1 month')::date);
    END LOOP;
END $$;
--rollback SELECT 1;
