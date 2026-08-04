create table runtime_foundation (
    foundation_id uuid primary key,
    schema_version varchar(32) not null,
    installed_at timestamptz not null default current_timestamp
);

insert into runtime_foundation (foundation_id, schema_version)
values ('00000000-0000-0000-0000-000000000001', 'phase-1');
