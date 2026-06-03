


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."add_owner_to_members"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$begin
  insert into public.vault_members (vault_id, user_id, role)
  values (new.id, new.created_by, 'owner')
  on conflict (vault_id, user_id) do nothing;
  return new;
end;$$;


ALTER FUNCTION "public"."add_owner_to_members"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."users" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "email" "text" NOT NULL,
    "name" "text" DEFAULT ''::"text" NOT NULL,
    "is_registered" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_by" "uuid"
);


ALTER TABLE "public"."users" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."add_vault_member_by_email"("p_vault_id" "uuid", "p_email" "text", "p_role" "text" DEFAULT 'member'::"text") RETURNS "public"."users"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'auth'
    AS $$
declare
  caller uuid := auth.uid();
  v_email text := lower(trim(p_email));
  target public.users%rowtype;
begin
  if caller is null then
    raise exception 'unauthenticated';
  end if;

  -- Only an owner/admin of the vault may add members.
  if not exists (
    select 1 from public.vault_members pm
    where pm.vault_id = p_vault_id
      and pm.user_id = caller
      and pm.role = any (array['admin','owner'])
  ) then
    raise exception 'not_authorized';
  end if;

  select * into target from public.users where lower(email) = v_email;

  if target.id is null then
    insert into public.users (email, name, is_registered)
    values (v_email, '', false)
    returning * into target;
  end if;

  insert into public.vault_members (vault_id, user_id, role, created_by, updated_by)
  values (p_vault_id, target.id, coalesce(nullif(p_role, ''), 'member'), caller, caller)
  on conflict (vault_id, user_id) do nothing;

  return target;
end;
$$;


ALTER FUNCTION "public"."add_vault_member_by_email"("p_vault_id" "uuid", "p_email" "text", "p_role" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."artifacts_resolve_unique_name"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$DECLARE
  base_name TEXT := NEW.name;
  candidate TEXT := NEW.name;
  counter   INT  := 1;
BEGIN
  IF NEW.vault_id IS NULL OR NEW.name IS NULL THEN RETURN NEW; END IF;
  PERFORM pg_advisory_xact_lock(hashtext(NEW.vault_id::text));
  WHILE EXISTS (
    SELECT 1 FROM public.artifacts
    WHERE vault_id = NEW.vault_id AND name = candidate
  ) LOOP
    candidate := base_name || ' (' || counter || ')';
    counter   := counter + 1;
  END LOOP;
  NEW.name := candidate;
  RETURN NEW;
END;$$;


ALTER FUNCTION "public"."artifacts_resolve_unique_name"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."bump_vault_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$declare
  v_vault_id uuid;
  v_canvas_id  uuid;
  v_target_id  uuid;
begin
  if tg_table_name = 'artifacts' then
    v_vault_id := case when tg_op = 'DELETE' then old.vault_id else new.vault_id end;
  elsif tg_table_name in ('canvas_objects', 'pins', 'history_diffs') then
    v_canvas_id := case when tg_op = 'DELETE' then old.canvas_artifact_id else new.canvas_artifact_id end;
    select vault_id into v_vault_id from public.artifacts where id = v_canvas_id;
  elsif tg_table_name = 'comments' then
    v_target_id := case when tg_op = 'DELETE' then old.target_id else new.target_id end;
    select vault_id into v_vault_id from public.artifacts where id = v_target_id;
  elsif tg_table_name = 'artifact_ops' then
    v_vault_id := new.vault_id;
  end if;

  if v_vault_id is not null then
    if tg_table_name = 'artifact_ops' then
      -- Ops fire on every keystroke; throttle so the vault row is touched at
      -- most once per 30s. The client's debounced body.content writeback bumps
      -- updated_at on the artifacts table path anyway — this just guarantees
      -- recency on the first keystroke even before/without that writeback.
      update public.vaults set updated_at = now()
        where id = v_vault_id and now() - updated_at > interval '30 seconds';
    else
      update public.vaults set updated_at = now() where id = v_vault_id;
    end if;
  end if;

  return null; -- AFTER trigger; return value ignored
end;$$;


ALTER FUNCTION "public"."bump_vault_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_delete_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'auth'
    AS $$
begin
  delete from public.users where id = old.id;
  return old;
end;
$$;


ALTER FUNCTION "public"."handle_delete_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'auth'
    AS $$
declare
  meta_name text := coalesce(
    new.raw_user_meta_data ->> 'name',
    new.raw_user_meta_data ->> 'full_name'
  );
begin
  if exists (select 1 from public.users where lower(email) = lower(new.email)) then
    -- A ghost was created for this email; promote it to the real account. The
    -- id change cascades to vault_members.user_id, inheriting any memberships.
    update public.users
       set id = new.id,
           is_registered = true,
           name = coalesce(meta_name, name)
     where lower(email) = lower(new.email);
  else
    insert into public.users (id, email, name, is_registered)
    values (new.id, new.email, coalesce(meta_name, ''), true);
  end if;
  return new;
end;
$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_update_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'auth'
    AS $$
begin
  update public.users
     set email = new.email,
         name  = coalesce(
                   new.raw_user_meta_data ->> 'name',
                   new.raw_user_meta_data ->> 'full_name',
                   name)
   where id = new.id;
  return new;
end;
$$;


ALTER FUNCTION "public"."handle_update_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_vault_member"("p_project_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$select exists(
    select 1 from public.vault_members
    where vault_id = p_project_id and user_id = auth.uid()
  );$$;


ALTER FUNCTION "public"."is_vault_member"("p_project_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_created_audit"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  new.created_at := now();
  new.created_by := auth.uid();
  new.updated_at := now();
  new.updated_by := auth.uid();
  return new;
end;
$$;


ALTER FUNCTION "public"."set_created_audit"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_updated_audit"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  new.updated_at := now();
  new.updated_by := auth.uid();
  return new;
end;
$$;


ALTER FUNCTION "public"."set_updated_audit"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."shares_vault"("p_other" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select exists(
    select 1
      from public.vault_members a
      join public.vault_members b on b.vault_id = a.vault_id
     where a.user_id = auth.uid()
       and b.user_id = p_other
  );
$$;


ALTER FUNCTION "public"."shares_vault"("p_other" "uuid") OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."artifact_ops" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "artifact_id" "uuid" NOT NULL,
    "vault_id" "uuid" NOT NULL,
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "op_bytes" "text" NOT NULL,
    "op_seq" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."artifact_ops" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."artifact_ops_op_seq_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."artifact_ops_op_seq_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."artifact_ops_op_seq_seq" OWNED BY "public"."artifact_ops"."op_seq";



CREATE TABLE IF NOT EXISTS "public"."artifact_snapshots" (
    "artifact_id" "uuid" NOT NULL,
    "vault_id" "uuid" NOT NULL,
    "snapshot_bytes" "text" NOT NULL,
    "version_vector" "jsonb" NOT NULL,
    "max_op_seq" bigint,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."artifact_snapshots" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."artifacts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "vault_id" "uuid" NOT NULL,
    "parent_folder_id" "uuid",
    "type" "text" NOT NULL,
    "name" "text" DEFAULT ''::"text" NOT NULL,
    "body" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_by" "uuid",
    CONSTRAINT "artifacts_type_check" CHECK (("type" = ANY (ARRAY['folder'::"text", 'note'::"text", 'canvas'::"text", 'image'::"text"])))
);

ALTER TABLE ONLY "public"."artifacts" REPLICA IDENTITY FULL;


ALTER TABLE "public"."artifacts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."canvas_objects" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "canvas_artifact_id" "uuid" NOT NULL,
    "type" "text" NOT NULL,
    "payload" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_by" "uuid",
    CONSTRAINT "canvas_objects_kind_check" CHECK (("type" = ANY (ARRAY['rectangle'::"text", 'diamond'::"text", 'oblong'::"text", 'circle'::"text", 'rhombus'::"text", 'trapezoid'::"text", 'cylinder'::"text", 'house'::"text", 'reverseHouse'::"text", 'text'::"text", 'image'::"text", 'brush'::"text", 'arrow'::"text", 'artifact'::"text"])))
);

ALTER TABLE ONLY "public"."canvas_objects" REPLICA IDENTITY FULL;


ALTER TABLE "public"."canvas_objects" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."comments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "canvas_artifact_id" "uuid" NOT NULL,
    "body" "text" DEFAULT ''::"text" NOT NULL,
    "pinned_object_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_by" "uuid",
    "position" "jsonb"
);

ALTER TABLE ONLY "public"."comments" REPLICA IDENTITY FULL;


ALTER TABLE "public"."comments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."pins" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "canvas_artifact_id" "uuid" NOT NULL,
    "linked_artifact_id" "uuid",
    "pinned_object_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_by" "uuid",
    "position" "jsonb"
);

ALTER TABLE ONLY "public"."pins" REPLICA IDENTITY FULL;


ALTER TABLE "public"."pins" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."sub_comments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "comment_id" "uuid" NOT NULL,
    "content" "text" DEFAULT ''::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_by" "uuid"
);

ALTER TABLE ONLY "public"."sub_comments" REPLICA IDENTITY FULL;


ALTER TABLE "public"."sub_comments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."vault_members" (
    "vault_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "role" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_by" "uuid",
    CONSTRAINT "vault_members_role_check" CHECK (("role" = ANY (ARRAY['member'::"text", 'owner'::"text"])))
);


ALTER TABLE "public"."vault_members" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."vaults" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" DEFAULT ''::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_by" "uuid",
    CONSTRAINT "vaults_name_check" CHECK (("length"("name") < 40))
);

ALTER TABLE ONLY "public"."vaults" REPLICA IDENTITY FULL;


ALTER TABLE "public"."vaults" OWNER TO "postgres";


ALTER TABLE ONLY "public"."artifact_ops" ALTER COLUMN "op_seq" SET DEFAULT "nextval"('"public"."artifact_ops_op_seq_seq"'::"regclass");



ALTER TABLE ONLY "public"."artifact_ops"
    ADD CONSTRAINT "artifact_ops_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."artifact_snapshots"
    ADD CONSTRAINT "artifact_snapshots_pkey" PRIMARY KEY ("artifact_id");



ALTER TABLE ONLY "public"."artifacts"
    ADD CONSTRAINT "artifacts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."artifacts"
    ADD CONSTRAINT "artifacts_vault_name_unique" UNIQUE ("vault_id", "name");



ALTER TABLE ONLY "public"."canvas_objects"
    ADD CONSTRAINT "canvas_objects_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pins"
    ADD CONSTRAINT "pins_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."sub_comments"
    ADD CONSTRAINT "sub_comments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."vault_members"
    ADD CONSTRAINT "vault_members_pkey" PRIMARY KEY ("vault_id", "user_id");



ALTER TABLE ONLY "public"."vaults"
    ADD CONSTRAINT "vaults_pkey" PRIMARY KEY ("id");



CREATE INDEX "artifact_ops_artifact_id_idx" ON "public"."artifact_ops" USING "btree" ("artifact_id");



CREATE INDEX "artifact_ops_artifact_seq_idx" ON "public"."artifact_ops" USING "btree" ("artifact_id", "op_seq");



CREATE INDEX "artifact_snapshots_vault_id_idx" ON "public"."artifact_snapshots" USING "btree" ("vault_id");



CREATE INDEX "artifacts_vault_id_idx" ON "public"."artifacts" USING "btree" ("vault_id");



CREATE INDEX "artifacts_vault_id_parent_folder_id_idx" ON "public"."artifacts" USING "btree" ("vault_id", "parent_folder_id");



CREATE INDEX "artifacts_vault_id_type_idx" ON "public"."artifacts" USING "btree" ("vault_id", "type");



CREATE INDEX "canvas_objects_canvas_artifact_id_idx" ON "public"."canvas_objects" USING "btree" ("canvas_artifact_id");



CREATE INDEX "comments_pinned_object_id_idx" ON "public"."comments" USING "btree" ("pinned_object_id") WHERE ("pinned_object_id" IS NOT NULL);



CREATE INDEX "comments_target_id_idx" ON "public"."comments" USING "btree" ("canvas_artifact_id");



CREATE INDEX "pins_canvas_artifact_id_idx" ON "public"."pins" USING "btree" ("canvas_artifact_id");



CREATE INDEX "pins_linked_artifact_id_idx" ON "public"."pins" USING "btree" ("linked_artifact_id") WHERE ("linked_artifact_id" IS NOT NULL);



CREATE INDEX "pins_target_object_id_idx" ON "public"."pins" USING "btree" ("pinned_object_id") WHERE ("pinned_object_id" IS NOT NULL);



CREATE INDEX "sub_comments_comment_id_idx" ON "public"."sub_comments" USING "btree" ("comment_id");



CREATE UNIQUE INDEX "users_email_lower_key" ON "public"."users" USING "btree" ("lower"("email"));



CREATE INDEX "vault_members_user_id_idx" ON "public"."vault_members" USING "btree" ("user_id");



CREATE OR REPLACE TRIGGER "artifacts_bump_vault" AFTER INSERT OR DELETE OR UPDATE ON "public"."artifacts" FOR EACH ROW EXECUTE FUNCTION "public"."bump_vault_updated_at"();



CREATE OR REPLACE TRIGGER "artifact_ops_bump_vault" AFTER INSERT ON "public"."artifact_ops" FOR EACH ROW EXECUTE FUNCTION "public"."bump_vault_updated_at"();



CREATE OR REPLACE TRIGGER "artifacts_resolve_unique_name" BEFORE INSERT ON "public"."artifacts" FOR EACH ROW EXECUTE FUNCTION "public"."artifacts_resolve_unique_name"();



CREATE OR REPLACE TRIGGER "artifacts_set_created" BEFORE INSERT ON "public"."artifacts" FOR EACH ROW EXECUTE FUNCTION "public"."set_created_audit"();



CREATE OR REPLACE TRIGGER "artifacts_set_updated" BEFORE UPDATE ON "public"."artifacts" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_audit"();



CREATE OR REPLACE TRIGGER "canvas_objects_bump_vault" AFTER INSERT OR DELETE OR UPDATE ON "public"."canvas_objects" FOR EACH ROW EXECUTE FUNCTION "public"."bump_vault_updated_at"();



CREATE OR REPLACE TRIGGER "canvas_objects_set_created" BEFORE INSERT ON "public"."canvas_objects" FOR EACH ROW EXECUTE FUNCTION "public"."set_created_audit"();



CREATE OR REPLACE TRIGGER "canvas_objects_set_updated" BEFORE UPDATE ON "public"."canvas_objects" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_audit"();



CREATE OR REPLACE TRIGGER "comments_bump_vault" AFTER INSERT OR DELETE OR UPDATE ON "public"."comments" FOR EACH ROW EXECUTE FUNCTION "public"."bump_vault_updated_at"();



CREATE OR REPLACE TRIGGER "comments_set_created" BEFORE INSERT ON "public"."comments" FOR EACH ROW EXECUTE FUNCTION "public"."set_created_audit"();



CREATE OR REPLACE TRIGGER "comments_set_updated" BEFORE UPDATE ON "public"."comments" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_audit"();



CREATE OR REPLACE TRIGGER "pins_bump_vault" AFTER INSERT OR DELETE OR UPDATE ON "public"."pins" FOR EACH ROW EXECUTE FUNCTION "public"."bump_vault_updated_at"();



CREATE OR REPLACE TRIGGER "pins_set_created" BEFORE INSERT ON "public"."pins" FOR EACH ROW EXECUTE FUNCTION "public"."set_created_audit"();



CREATE OR REPLACE TRIGGER "pins_set_updated" BEFORE UPDATE ON "public"."pins" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_audit"();



CREATE OR REPLACE TRIGGER "sub_comments_set_created" BEFORE INSERT ON "public"."sub_comments" FOR EACH ROW EXECUTE FUNCTION "public"."set_created_audit"();



CREATE OR REPLACE TRIGGER "sub_comments_set_updated" BEFORE UPDATE ON "public"."sub_comments" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_audit"();



CREATE OR REPLACE TRIGGER "users_set_created" BEFORE INSERT ON "public"."users" FOR EACH ROW EXECUTE FUNCTION "public"."set_created_audit"();



CREATE OR REPLACE TRIGGER "users_set_updated" BEFORE UPDATE ON "public"."users" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_audit"();



CREATE OR REPLACE TRIGGER "vault_members_set_created" BEFORE INSERT ON "public"."vault_members" FOR EACH ROW EXECUTE FUNCTION "public"."set_created_audit"();



CREATE OR REPLACE TRIGGER "vault_members_set_updated" BEFORE UPDATE ON "public"."vault_members" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_audit"();



CREATE OR REPLACE TRIGGER "vaults_add_owner" AFTER INSERT ON "public"."vaults" FOR EACH ROW EXECUTE FUNCTION "public"."add_owner_to_members"();



CREATE OR REPLACE TRIGGER "vaults_set_created" BEFORE INSERT ON "public"."vaults" FOR EACH ROW EXECUTE FUNCTION "public"."set_created_audit"();



CREATE OR REPLACE TRIGGER "vaults_set_updated" BEFORE UPDATE ON "public"."vaults" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_audit"();



ALTER TABLE ONLY "public"."artifact_ops"
    ADD CONSTRAINT "artifact_ops_artifact_id_fkey" FOREIGN KEY ("artifact_id") REFERENCES "public"."artifacts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."artifact_ops"
    ADD CONSTRAINT "artifact_ops_vault_id_fkey" FOREIGN KEY ("vault_id") REFERENCES "public"."vaults"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."artifact_snapshots"
    ADD CONSTRAINT "artifact_snapshots_artifact_id_fkey" FOREIGN KEY ("artifact_id") REFERENCES "public"."artifacts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."artifact_snapshots"
    ADD CONSTRAINT "artifact_snapshots_vault_id_fkey" FOREIGN KEY ("vault_id") REFERENCES "public"."vaults"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."artifacts"
    ADD CONSTRAINT "artifacts_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."artifacts"
    ADD CONSTRAINT "artifacts_parent_folder_id_fkey" FOREIGN KEY ("parent_folder_id") REFERENCES "public"."artifacts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."artifacts"
    ADD CONSTRAINT "artifacts_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."artifacts"
    ADD CONSTRAINT "artifacts_vault_id_fkey" FOREIGN KEY ("vault_id") REFERENCES "public"."vaults"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."canvas_objects"
    ADD CONSTRAINT "canvas_objects_canvas_artifact_id_fkey" FOREIGN KEY ("canvas_artifact_id") REFERENCES "public"."artifacts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."canvas_objects"
    ADD CONSTRAINT "canvas_objects_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."canvas_objects"
    ADD CONSTRAINT "canvas_objects_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_canvas_artifact_id_fkey" FOREIGN KEY ("canvas_artifact_id") REFERENCES "public"."artifacts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_pinned_object_id_fkey" FOREIGN KEY ("pinned_object_id") REFERENCES "public"."canvas_objects"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."pins"
    ADD CONSTRAINT "pins_canvas_artifact_id_fkey" FOREIGN KEY ("canvas_artifact_id") REFERENCES "public"."artifacts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pins"
    ADD CONSTRAINT "pins_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."pins"
    ADD CONSTRAINT "pins_linked_artifact_id_fkey" FOREIGN KEY ("linked_artifact_id") REFERENCES "public"."artifacts"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."pins"
    ADD CONSTRAINT "pins_pinned_object_id_fkey" FOREIGN KEY ("pinned_object_id") REFERENCES "public"."canvas_objects"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."pins"
    ADD CONSTRAINT "pins_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."sub_comments"
    ADD CONSTRAINT "sub_comments_comment_id_fkey" FOREIGN KEY ("comment_id") REFERENCES "public"."comments"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."sub_comments"
    ADD CONSTRAINT "sub_comments_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."sub_comments"
    ADD CONSTRAINT "sub_comments_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."vault_members"
    ADD CONSTRAINT "vault_members_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."vault_members"
    ADD CONSTRAINT "vault_members_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."vault_members"
    ADD CONSTRAINT "vault_members_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."vault_members"
    ADD CONSTRAINT "vault_members_vault_id_fkey" FOREIGN KEY ("vault_id") REFERENCES "public"."vaults"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."vaults"
    ADD CONSTRAINT "vaults_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."vaults"
    ADD CONSTRAINT "vaults_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "auth"."users"("id");



ALTER TABLE "public"."artifact_ops" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "artifact_ops_insert" ON "public"."artifact_ops" FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."vault_members" "vm"
  WHERE (("vm"."vault_id" = "artifact_ops"."vault_id") AND ("vm"."user_id" = "auth"."uid"())))));



CREATE POLICY "artifact_ops_select" ON "public"."artifact_ops" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."vault_members" "vm"
  WHERE (("vm"."vault_id" = "artifact_ops"."vault_id") AND ("vm"."user_id" = "auth"."uid"())))));



ALTER TABLE "public"."artifact_snapshots" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "artifact_snapshots_insert" ON "public"."artifact_snapshots" FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."vault_members" "vm"
  WHERE (("vm"."vault_id" = "artifact_snapshots"."vault_id") AND ("vm"."user_id" = "auth"."uid"())))));



CREATE POLICY "artifact_snapshots_select" ON "public"."artifact_snapshots" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."vault_members" "vm"
  WHERE (("vm"."vault_id" = "artifact_snapshots"."vault_id") AND ("vm"."user_id" = "auth"."uid"())))));



CREATE POLICY "artifact_snapshots_update" ON "public"."artifact_snapshots" FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM "public"."vault_members" "vm"
  WHERE (("vm"."vault_id" = "artifact_snapshots"."vault_id") AND ("vm"."user_id" = "auth"."uid"()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."vault_members" "vm"
  WHERE (("vm"."vault_id" = "artifact_snapshots"."vault_id") AND ("vm"."user_id" = "auth"."uid"())))));



ALTER TABLE "public"."artifacts" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "artifacts_all" ON "public"."artifacts" TO "authenticated" USING ("public"."is_vault_member"("vault_id")) WITH CHECK ("public"."is_vault_member"("vault_id"));



ALTER TABLE "public"."canvas_objects" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "canvas_objects_all" ON "public"."canvas_objects" TO "authenticated" USING ("public"."is_vault_member"(( SELECT "artifacts"."vault_id" AS "project_id"
   FROM "public"."artifacts"
  WHERE ("artifacts"."id" = "canvas_objects"."canvas_artifact_id")))) WITH CHECK ("public"."is_vault_member"(( SELECT "artifacts"."vault_id" AS "project_id"
   FROM "public"."artifacts"
  WHERE ("artifacts"."id" = "canvas_objects"."canvas_artifact_id"))));



ALTER TABLE "public"."comments" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "comments_all" ON "public"."comments" TO "authenticated" USING ("public"."is_vault_member"(( SELECT "artifacts"."vault_id" AS "project_id"
   FROM "public"."artifacts"
  WHERE ("artifacts"."id" = "comments"."canvas_artifact_id")))) WITH CHECK ("public"."is_vault_member"(( SELECT "artifacts"."vault_id" AS "project_id"
   FROM "public"."artifacts"
  WHERE ("artifacts"."id" = "comments"."canvas_artifact_id"))));



ALTER TABLE "public"."pins" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "pins_all" ON "public"."pins" TO "authenticated" USING ("public"."is_vault_member"(( SELECT "artifacts"."vault_id" AS "project_id"
   FROM "public"."artifacts"
  WHERE ("artifacts"."id" = "pins"."canvas_artifact_id")))) WITH CHECK ("public"."is_vault_member"(( SELECT "artifacts"."vault_id" AS "project_id"
   FROM "public"."artifacts"
  WHERE ("artifacts"."id" = "pins"."canvas_artifact_id"))));



ALTER TABLE "public"."sub_comments" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "sub_comments_all" ON "public"."sub_comments" TO "authenticated" USING ("public"."is_vault_member"(( SELECT "a"."vault_id" AS "project_id"
   FROM ("public"."comments" "c"
     JOIN "public"."artifacts" "a" ON (("a"."id" = "c"."canvas_artifact_id")))
  WHERE ("c"."id" = "sub_comments"."comment_id")))) WITH CHECK ("public"."is_vault_member"(( SELECT "a"."vault_id" AS "project_id"
   FROM ("public"."comments" "c"
     JOIN "public"."artifacts" "a" ON (("a"."id" = "c"."canvas_artifact_id")))
  WHERE ("c"."id" = "sub_comments"."comment_id"))));



ALTER TABLE "public"."users" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "users_select" ON "public"."users" FOR SELECT TO "authenticated" USING ((("id" = "auth"."uid"()) OR "public"."shares_vault"("id")));



ALTER TABLE "public"."vault_members" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "vault_members_delete" ON "public"."vault_members" FOR DELETE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."vault_members" "pm"
  WHERE (("pm"."vault_id" = "vault_members"."vault_id") AND ("pm"."user_id" = "auth"."uid"()) AND ("pm"."role" = ANY (ARRAY['admin'::"text", 'owner'::"text"]))))));



CREATE POLICY "vault_members_insert" ON "public"."vault_members" FOR INSERT TO "authenticated" WITH CHECK (((("user_id" = "auth"."uid"()) AND ("role" = 'owner'::"text") AND (EXISTS ( SELECT 1
   FROM "public"."vaults" "p"
  WHERE (("p"."id" = "vault_members"."vault_id") AND ("p"."created_by" = "auth"."uid"()))))) OR (EXISTS ( SELECT 1
   FROM "public"."vault_members" "pm"
  WHERE (("pm"."vault_id" = "vault_members"."vault_id") AND ("pm"."user_id" = "auth"."uid"()) AND ("pm"."role" = ANY (ARRAY['admin'::"text", 'owner'::"text"])))))));



CREATE POLICY "vault_members_select" ON "public"."vault_members" FOR SELECT TO "authenticated" USING ("public"."is_vault_member"("vault_id"));



CREATE POLICY "vault_members_update" ON "public"."vault_members" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."vault_members" "pm"
  WHERE (("pm"."vault_id" = "vault_members"."vault_id") AND ("pm"."user_id" = "auth"."uid"()) AND ("pm"."role" = ANY (ARRAY['admin'::"text", 'owner'::"text"])))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."vault_members" "pm"
  WHERE (("pm"."vault_id" = "vault_members"."vault_id") AND ("pm"."user_id" = "auth"."uid"()) AND ("pm"."role" = ANY (ARRAY['admin'::"text", 'owner'::"text"]))))));



ALTER TABLE "public"."vaults" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "vaults_delete" ON "public"."vaults" FOR DELETE TO "authenticated" USING ((("created_by" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."vault_members" "pm"
  WHERE (("pm"."vault_id" = "vaults"."id") AND ("pm"."user_id" = "auth"."uid"()) AND ("pm"."role" = ANY (ARRAY['admin'::"text", 'owner'::"text"])))))));



CREATE POLICY "vaults_insert" ON "public"."vaults" FOR INSERT TO "authenticated" WITH CHECK (("created_by" = "auth"."uid"()));



CREATE POLICY "vaults_select" ON "public"."vaults" FOR SELECT TO "authenticated" USING ((("created_by" = "auth"."uid"()) OR "public"."is_vault_member"("id")));



CREATE POLICY "vaults_update" ON "public"."vaults" FOR UPDATE TO "authenticated" USING ((("created_by" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."vault_members" "pm"
  WHERE (("pm"."vault_id" = "vaults"."id") AND ("pm"."user_id" = "auth"."uid"()) AND ("pm"."role" = ANY (ARRAY['admin'::"text", 'owner'::"text"]))))))) WITH CHECK ((("created_by" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."vault_members" "pm"
  WHERE (("pm"."vault_id" = "vaults"."id") AND ("pm"."user_id" = "auth"."uid"()) AND ("pm"."role" = ANY (ARRAY['admin'::"text", 'owner'::"text"])))))));





ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";






ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."artifact_ops";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."artifact_snapshots";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."artifacts";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."canvas_objects";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."comments";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."pins";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."sub_comments";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."vault_members";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."vaults";



GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";






















































































































































GRANT ALL ON FUNCTION "public"."add_owner_to_members"() TO "anon";
GRANT ALL ON FUNCTION "public"."add_owner_to_members"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."add_owner_to_members"() TO "service_role";



GRANT ALL ON TABLE "public"."users" TO "anon";
GRANT ALL ON TABLE "public"."users" TO "authenticated";
GRANT ALL ON TABLE "public"."users" TO "service_role";



GRANT ALL ON FUNCTION "public"."add_vault_member_by_email"("p_vault_id" "uuid", "p_email" "text", "p_role" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."add_vault_member_by_email"("p_vault_id" "uuid", "p_email" "text", "p_role" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."add_vault_member_by_email"("p_vault_id" "uuid", "p_email" "text", "p_role" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."artifacts_resolve_unique_name"() TO "anon";
GRANT ALL ON FUNCTION "public"."artifacts_resolve_unique_name"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."artifacts_resolve_unique_name"() TO "service_role";



GRANT ALL ON FUNCTION "public"."bump_vault_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."bump_vault_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."bump_vault_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_delete_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_delete_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_delete_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_update_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_update_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_update_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."is_vault_member"("p_project_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."is_vault_member"("p_project_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_vault_member"("p_project_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."set_created_audit"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_created_audit"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_created_audit"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_updated_audit"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_updated_audit"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_updated_audit"() TO "service_role";



GRANT ALL ON FUNCTION "public"."shares_vault"("p_other" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."shares_vault"("p_other" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."shares_vault"("p_other" "uuid") TO "service_role";


















GRANT ALL ON TABLE "public"."artifact_ops" TO "anon";
GRANT ALL ON TABLE "public"."artifact_ops" TO "authenticated";
GRANT ALL ON TABLE "public"."artifact_ops" TO "service_role";



GRANT ALL ON SEQUENCE "public"."artifact_ops_op_seq_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."artifact_ops_op_seq_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."artifact_ops_op_seq_seq" TO "service_role";



GRANT ALL ON TABLE "public"."artifact_snapshots" TO "anon";
GRANT ALL ON TABLE "public"."artifact_snapshots" TO "authenticated";
GRANT ALL ON TABLE "public"."artifact_snapshots" TO "service_role";



GRANT ALL ON TABLE "public"."artifacts" TO "anon";
GRANT ALL ON TABLE "public"."artifacts" TO "authenticated";
GRANT ALL ON TABLE "public"."artifacts" TO "service_role";



GRANT ALL ON TABLE "public"."canvas_objects" TO "anon";
GRANT ALL ON TABLE "public"."canvas_objects" TO "authenticated";
GRANT ALL ON TABLE "public"."canvas_objects" TO "service_role";



GRANT ALL ON TABLE "public"."comments" TO "anon";
GRANT ALL ON TABLE "public"."comments" TO "authenticated";
GRANT ALL ON TABLE "public"."comments" TO "service_role";



GRANT ALL ON TABLE "public"."pins" TO "anon";
GRANT ALL ON TABLE "public"."pins" TO "authenticated";
GRANT ALL ON TABLE "public"."pins" TO "service_role";



GRANT ALL ON TABLE "public"."sub_comments" TO "anon";
GRANT ALL ON TABLE "public"."sub_comments" TO "authenticated";
GRANT ALL ON TABLE "public"."sub_comments" TO "service_role";



GRANT ALL ON TABLE "public"."vault_members" TO "anon";
GRANT ALL ON TABLE "public"."vault_members" TO "authenticated";
GRANT ALL ON TABLE "public"."vault_members" TO "service_role";



GRANT ALL ON TABLE "public"."vaults" TO "anon";
GRANT ALL ON TABLE "public"."vaults" TO "authenticated";
GRANT ALL ON TABLE "public"."vaults" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";































