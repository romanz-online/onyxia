-- =====================================================================
-- Onyxia: Phase B — initial Supabase schema
-- See plan: emancipation.md (Phase B)
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Extensions
-- ---------------------------------------------------------------------
create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------
-- 2. Tables
--    Audit columns repeat on every table:
--      created_at  timestamptz not null default now()
--      created_by  uuid        references auth.users(id)
--      updated_at  timestamptz not null default now()
--      updated_by  uuid        references auth.users(id)
-- ---------------------------------------------------------------------

create table public.users (
  id          uuid primary key references auth.users(id) on delete cascade,
  email       text not null unique,
  name        text not null default '',
  about_me    text not null default '',
  image_url   text,
  created_at  timestamptz not null default now(),
  created_by  uuid references auth.users(id),
  updated_at  timestamptz not null default now(),
  updated_by  uuid references auth.users(id)
);

create table public.projects (
  id          uuid primary key default gen_random_uuid(),
  name        text not null default '',
  owner_id    uuid not null references public.users(id),
  created_at  timestamptz not null default now(),
  created_by  uuid references auth.users(id),
  updated_at  timestamptz not null default now(),
  updated_by  uuid references auth.users(id)
);

create table public.project_members (
  id          uuid not null default gen_random_uuid(),
  project_id  uuid not null references public.projects(id) on delete cascade,
  user_id     uuid not null references public.users(id) on delete cascade,
  role        text not null check (role in ('member', 'admin', 'owner')),
  created_at  timestamptz not null default now(),
  created_by  uuid references auth.users(id),
  updated_at  timestamptz not null default now(),
  updated_by  uuid references auth.users(id),
  primary key (project_id, user_id)
);

create table public.artifacts (
  id                uuid primary key default gen_random_uuid(),
  project_id        uuid not null references public.projects(id) on delete cascade,
  parent_folder_id  uuid references public.artifacts(id) on delete cascade,
  type              text not null check (type in ('folder', 'note', 'canvas')),
  name              text not null default '',
  body              jsonb,
  created_at        timestamptz not null default now(),
  created_by        uuid references auth.users(id),
  updated_at        timestamptz not null default now(),
  updated_by        uuid references auth.users(id)
);

create table public.canvas_objects (
  id                  uuid primary key default gen_random_uuid(),
  canvas_artifact_id  uuid not null references public.artifacts(id) on delete cascade,
  kind                text not null check (kind in (
                        'rectangle','diamond','oblong','circle','rhombus','trapezoid',
                        'cylinder','house','reverseHouse','text','image','brush','arrow','artifact'
                      )),
  payload             jsonb not null default '{}'::jsonb,
  created_at          timestamptz not null default now(),
  created_by          uuid references auth.users(id),
  updated_at          timestamptz not null default now(),
  updated_by          uuid references auth.users(id)
);

create table public.pins (
  id                  uuid primary key default gen_random_uuid(),
  canvas_artifact_id  uuid not null references public.artifacts(id) on delete cascade,
  linked_artifact_id  uuid references public.artifacts(id) on delete set null,
  target_object_id    uuid references public.canvas_objects(id) on delete set null,
  x                   double precision not null default 0,
  y                   double precision not null default 0,
  created_at          timestamptz not null default now(),
  created_by          uuid references auth.users(id),
  updated_at          timestamptz not null default now(),
  updated_by          uuid references auth.users(id)
);

create table public.comments (
  id                uuid primary key default gen_random_uuid(),
  target_id         uuid not null references public.artifacts(id) on delete cascade,
  target_type       text not null default 'canvas' check (target_type in ('canvas', 'note')),
  author_id         uuid not null references public.users(id),
  body              text not null default '',
  x                 double precision,
  y                 double precision,
  color             integer not null default 0,
  pinned_object_id  uuid references public.canvas_objects(id) on delete set null,
  resolved          boolean not null default false,
  created_at        timestamptz not null default now(),
  created_by        uuid references auth.users(id),
  updated_at        timestamptz not null default now(),
  updated_by        uuid references auth.users(id)
);

create table public.sub_comments (
  id          uuid primary key default gen_random_uuid(),
  comment_id  uuid not null references public.comments(id) on delete cascade,
  author_id   uuid not null references public.users(id),
  body        text not null default '',
  created_at  timestamptz not null default now(),
  created_by  uuid references auth.users(id),
  updated_at  timestamptz not null default now(),
  updated_by  uuid references auth.users(id)
);

create table public.history_diffs (
  id                  uuid primary key default gen_random_uuid(),
  canvas_artifact_id  uuid not null references public.artifacts(id) on delete cascade,
  seq                 integer not null,
  diff                jsonb not null,
  created_at          timestamptz not null default now(),
  created_by          uuid references auth.users(id),
  updated_at          timestamptz not null default now(),
  updated_by          uuid references auth.users(id),
  unique (canvas_artifact_id, seq)
);

create table public.storage_files (
  id          uuid primary key default gen_random_uuid(),
  project_id  uuid references public.projects(id) on delete cascade,
  canvas_id   uuid references public.artifacts(id) on delete set null,
  user_id     uuid not null references public.users(id),
  name        text not null default '',
  path        text not null,
  mime        text not null default '',
  size        bigint not null,
  metadata    jsonb,
  created_at  timestamptz not null default now(),
  created_by  uuid references auth.users(id),
  updated_at  timestamptz not null default now(),
  updated_by  uuid references auth.users(id)
);

-- ---------------------------------------------------------------------
-- 3. Audit trigger functions + attachments
-- ---------------------------------------------------------------------

create or replace function public.set_created_audit() returns trigger
language plpgsql as $$
begin
  new.created_at := now();
  new.created_by := auth.uid();
  new.updated_at := now();
  new.updated_by := auth.uid();
  return new;
end;
$$;

create or replace function public.set_updated_audit() returns trigger
language plpgsql as $$
begin
  new.updated_at := now();
  new.updated_by := auth.uid();
  return new;
end;
$$;

do $$
declare
  t text;
  tables text[] := array[
    'users', 'projects', 'project_members', 'artifacts',
    'canvas_objects', 'pins', 'comments', 'sub_comments',
    'history_diffs', 'storage_files'
  ];
begin
  foreach t in array tables loop
    execute format(
      'create trigger %I_set_created before insert on public.%I
         for each row execute function public.set_created_audit();',
      t, t
    );
    execute format(
      'create trigger %I_set_updated before update on public.%I
         for each row execute function public.set_updated_audit();',
      t, t
    );
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- 4. Project metadata bump trigger
--    Bumps projects.updated_at whenever child content changes.
-- ---------------------------------------------------------------------

create or replace function public.bump_project_updated_at() returns trigger
language plpgsql as $$
declare
  v_project_id uuid;
  v_canvas_id  uuid;
  v_target_id  uuid;
begin
  if tg_table_name = 'artifacts' then
    v_project_id := case when tg_op = 'DELETE' then old.project_id else new.project_id end;
  elsif tg_table_name in ('canvas_objects', 'pins', 'history_diffs') then
    v_canvas_id := case when tg_op = 'DELETE' then old.canvas_artifact_id else new.canvas_artifact_id end;
    select project_id into v_project_id from public.artifacts where id = v_canvas_id;
  elsif tg_table_name = 'comments' then
    v_target_id := case when tg_op = 'DELETE' then old.target_id else new.target_id end;
    select project_id into v_project_id from public.artifacts where id = v_target_id;
  end if;

  if v_project_id is not null then
    update public.projects set updated_at = now() where id = v_project_id;
  end if;

  return null; -- AFTER trigger; return value ignored
end;
$$;

create trigger artifacts_bump_project       after insert or update or delete on public.artifacts       for each row execute function public.bump_project_updated_at();
create trigger canvas_objects_bump_project  after insert or update or delete on public.canvas_objects  for each row execute function public.bump_project_updated_at();
create trigger pins_bump_project            after insert or update or delete on public.pins            for each row execute function public.bump_project_updated_at();
create trigger comments_bump_project        after insert or update or delete on public.comments        for each row execute function public.bump_project_updated_at();
create trigger history_diffs_bump_project   after insert or update or delete on public.history_diffs   for each row execute function public.bump_project_updated_at();

-- ---------------------------------------------------------------------
-- 5. Auth → public.users mirror trigger
-- ---------------------------------------------------------------------

create or replace function public.mirror_auth_user_to_public() returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (id, email, name, image_url)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'name', new.raw_user_meta_data->>'full_name', ''),
    new.raw_user_meta_data->>'avatar_url'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.mirror_auth_user_to_public();

-- ---------------------------------------------------------------------
-- 6. history_diffs.seq assignment trigger
-- ---------------------------------------------------------------------

create or replace function public.assign_history_diff_seq() returns trigger
language plpgsql as $$
begin
  new.seq := coalesce(
    (select max(seq) from public.history_diffs where canvas_artifact_id = new.canvas_artifact_id),
    0
  ) + 1;
  return new;
end;
$$;

create trigger history_diffs_assign_seq
  before insert on public.history_diffs
  for each row execute function public.assign_history_diff_seq();

-- ---------------------------------------------------------------------
-- 7. RLS — enable on every table, default deny, project-membership policies
-- ---------------------------------------------------------------------

alter table public.users           enable row level security;
alter table public.projects        enable row level security;
alter table public.project_members enable row level security;
alter table public.artifacts       enable row level security;
alter table public.canvas_objects  enable row level security;
alter table public.pins            enable row level security;
alter table public.comments        enable row level security;
alter table public.sub_comments    enable row level security;
alter table public.history_diffs   enable row level security;
alter table public.storage_files   enable row level security;

create or replace function public.is_project_member(p_project_id uuid) returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists(
    select 1 from public.project_members
    where project_id = p_project_id and user_id = auth.uid()
  );
$$;

-- users
create policy users_select on public.users for select
  to authenticated using (true);
create policy users_insert_self on public.users for insert
  to authenticated with check (id = auth.uid());
create policy users_update_self on public.users for update
  to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- projects
-- owner_id = auth.uid() is included so a freshly-created project is visible/manageable
-- by its owner BEFORE they add themselves to project_members (chicken-and-egg).
create policy projects_select on public.projects for select
  to authenticated
  using (owner_id = auth.uid() or public.is_project_member(id));
create policy projects_insert on public.projects for insert
  to authenticated
  with check (owner_id = auth.uid());
create policy projects_update on public.projects for update
  to authenticated
  using (owner_id = auth.uid()
         or exists (select 1 from public.project_members
                     where project_id = projects.id and user_id = auth.uid() and role in ('admin','owner')))
  with check (owner_id = auth.uid()
              or exists (select 1 from public.project_members
                          where project_id = projects.id and user_id = auth.uid() and role in ('admin','owner')));
create policy projects_delete on public.projects for delete
  to authenticated
  using (owner_id = auth.uid()
         or exists (select 1 from public.project_members
                     where project_id = projects.id and user_id = auth.uid() and role in ('admin','owner')));

-- project_members
create policy project_members_select on public.project_members for select
  to authenticated using (public.is_project_member(project_id));
create policy project_members_insert on public.project_members for insert
  to authenticated with check (
    -- Owner adding themselves as 'owner' on a project they just created
    (user_id = auth.uid() and role = 'owner'
       and exists (select 1 from public.projects where id = project_id and owner_id = auth.uid()))
    -- Or an existing admin/owner adding others
    or exists (
      select 1 from public.project_members pm
      where pm.project_id = project_members.project_id
        and pm.user_id = auth.uid()
        and pm.role in ('admin','owner')
    )
  );
create policy project_members_update on public.project_members for update
  to authenticated
  using (exists (
    select 1 from public.project_members pm
    where pm.project_id = project_members.project_id and pm.user_id = auth.uid() and pm.role in ('admin','owner')
  ))
  with check (exists (
    select 1 from public.project_members pm
    where pm.project_id = project_members.project_id and pm.user_id = auth.uid() and pm.role in ('admin','owner')
  ));
create policy project_members_delete on public.project_members for delete
  to authenticated
  using (exists (
    select 1 from public.project_members pm
    where pm.project_id = project_members.project_id and pm.user_id = auth.uid() and pm.role in ('admin','owner')
  ));

-- artifacts
create policy artifacts_all on public.artifacts for all
  to authenticated
  using (public.is_project_member(project_id))
  with check (public.is_project_member(project_id));

-- canvas_objects
create policy canvas_objects_all on public.canvas_objects for all
  to authenticated
  using (public.is_project_member((select project_id from public.artifacts where id = canvas_artifact_id)))
  with check (public.is_project_member((select project_id from public.artifacts where id = canvas_artifact_id)));

-- pins
create policy pins_all on public.pins for all
  to authenticated
  using (public.is_project_member((select project_id from public.artifacts where id = canvas_artifact_id)))
  with check (public.is_project_member((select project_id from public.artifacts where id = canvas_artifact_id)));

-- comments
create policy comments_all on public.comments for all
  to authenticated
  using (public.is_project_member((select project_id from public.artifacts where id = target_id)))
  with check (public.is_project_member((select project_id from public.artifacts where id = target_id)));

-- sub_comments
create policy sub_comments_all on public.sub_comments for all
  to authenticated
  using (public.is_project_member((
    select a.project_id
      from public.comments c
      join public.artifacts a on a.id = c.target_id
     where c.id = comment_id
  )))
  with check (public.is_project_member((
    select a.project_id
      from public.comments c
      join public.artifacts a on a.id = c.target_id
     where c.id = comment_id
  )));

-- history_diffs
create policy history_diffs_all on public.history_diffs for all
  to authenticated
  using (public.is_project_member((select project_id from public.artifacts where id = canvas_artifact_id)))
  with check (public.is_project_member((select project_id from public.artifacts where id = canvas_artifact_id)));

-- storage_files (project_id can be null → user-scoped uploads owned by user_id)
create policy storage_files_all on public.storage_files for all
  to authenticated
  using (
    (project_id is not null and public.is_project_member(project_id))
    or (project_id is null and user_id = auth.uid())
  )
  with check (
    (project_id is not null and public.is_project_member(project_id))
    or (project_id is null and user_id = auth.uid())
  );

-- ---------------------------------------------------------------------
-- 8. Indexes
-- ---------------------------------------------------------------------

create index on public.users           (email);
create index on public.artifacts       (project_id);
create index on public.artifacts       (project_id, parent_folder_id);
create index on public.artifacts       (project_id, type);
create index on public.canvas_objects  (canvas_artifact_id);
create index on public.pins            (canvas_artifact_id);
create index on public.pins            (target_object_id) where target_object_id is not null;
create index on public.pins            (linked_artifact_id) where linked_artifact_id is not null;
create index on public.comments        (target_id);
create index on public.comments        (pinned_object_id) where pinned_object_id is not null;
create index on public.sub_comments    (comment_id);
create index on public.history_diffs   (canvas_artifact_id, seq);
create index on public.storage_files   (project_id);
create index on public.storage_files   (canvas_id) where canvas_id is not null;
create index on public.project_members (user_id);

-- ---------------------------------------------------------------------
-- 9. Realtime publication
-- ---------------------------------------------------------------------

-- High-churn tables get REPLICA IDENTITY FULL so DELETE events carry the row.
alter table public.canvas_objects replica identity full;
alter table public.pins           replica identity full;
alter table public.comments       replica identity full;
alter table public.sub_comments   replica identity full;
alter table public.history_diffs  replica identity full;

alter publication supabase_realtime add table
  public.artifacts,
  public.canvas_objects,
  public.comments,
  public.sub_comments,
  public.history_diffs,
  public.pins,
  public.storage_files,
  public.users;
