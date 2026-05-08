-- =====================================================================
-- When a project row is inserted, add its owner to project_members as
-- 'owner'. Closes the chicken-and-egg gap between project creation and
-- the strict is_project_member() RLS checks on artifacts/canvas_objects/
-- pins/comments/history_diffs.
-- =====================================================================

create or replace function public.add_owner_to_members() returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.project_members (project_id, user_id, role)
  values (new.id, new.owner_id, 'owner')
  on conflict (project_id, user_id) do nothing;
  return new;
end;
$$;

create trigger projects_add_owner
  after insert on public.projects
  for each row execute function public.add_owner_to_members();

-- Backfill: any existing project where the owner isn't already a member.
insert into public.project_members (project_id, user_id, role)
select id, owner_id, 'owner'
  from public.projects p
 where not exists (
   select 1 from public.project_members pm
    where pm.project_id = p.id and pm.user_id = p.owner_id
 );