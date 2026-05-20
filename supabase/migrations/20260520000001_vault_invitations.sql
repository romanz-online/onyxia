-- Vault invitation system: app-owned tokens for inviting non-registered users
-- to a vault. Existing users are added directly to vault_members; this table
-- only carries the gap between sending an invite and the invitee signing up.
--
-- The token IS the row identity and the URL secret (UUIDv4 is unguessable
-- enough for this use case). Invitations are deleted on accept (not marked
-- accepted) — they're ephemeral, not audited.

create table public.vault_invitations (
  token uuid primary key default gen_random_uuid(),
  vault_id uuid not null references public.vaults(id) on delete cascade,
  email text not null,
  expires_at timestamptz not null default (now() + interval '14 days')
);

create index vault_invitations_vault_id_email_idx
  on public.vault_invitations (vault_id, lower(email));

alter table public.vault_invitations enable row level security;

create policy "vault_invitations: select for owners"
  on public.vault_invitations for select
  using (exists (
    select 1 from public.vault_members vm
     where vm.vault_id = vault_invitations.vault_id
       and vm.user_id  = auth.uid()
       and vm.role = 'owner'
  ));

create policy "vault_invitations: insert by owners"
  on public.vault_invitations for insert
  with check (exists (
    select 1 from public.vault_members vm
     where vm.vault_id = vault_invitations.vault_id
       and vm.user_id  = auth.uid()
       and vm.role = 'owner'
  ));

create or replace function public.accept_vault_invitation(p_token uuid)
returns uuid
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  inv public.vault_invitations%rowtype;
  caller_id uuid := auth.uid();
  caller_email text;
begin
  if caller_id is null then
    raise exception 'unauthenticated';
  end if;

  select email into caller_email from auth.users where id = caller_id;

  select * into inv
    from public.vault_invitations
   where token = p_token;

  if inv.token is null then
    raise exception 'invitation_not_found';
  end if;
  if inv.expires_at < now() then
    raise exception 'invitation_expired';
  end if;
  if lower(inv.email) <> lower(caller_email) then
    raise exception 'invitation_email_mismatch';
  end if;

  insert into public.vault_members
    (vault_id, user_id, role, created_by, updated_by)
  values
    (inv.vault_id, caller_id, 'member', caller_id, caller_id)
  on conflict (vault_id, user_id) do nothing;

  delete from public.vault_invitations where token = inv.token;

  return inv.vault_id;
end;
$$;

revoke all on function public.accept_vault_invitation(uuid) from public;
grant execute on function public.accept_vault_invitation(uuid) to authenticated;
