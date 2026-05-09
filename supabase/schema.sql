


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


CREATE EXTENSION IF NOT EXISTS "pg_net" WITH SCHEMA "extensions";






COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."add_owner_to_members"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  insert into public.project_members (project_id, user_id, role)
  values (new.id, new.owner_id, 'owner')
  on conflict (project_id, user_id) do nothing;
  return new;
end;
$$;


ALTER FUNCTION "public"."add_owner_to_members"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."assign_history_diff_seq"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  new.seq := coalesce(
    (select max(seq) from public.history_diffs where canvas_artifact_id = new.canvas_artifact_id),
    0
  ) + 1;
  return new;
end;
$$;


ALTER FUNCTION "public"."assign_history_diff_seq"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."bump_project_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
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


ALTER FUNCTION "public"."bump_project_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_project_member"("p_project_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select exists(
    select 1 from public.project_members
    where project_id = p_project_id and user_id = auth.uid()
  );
$$;


ALTER FUNCTION "public"."is_project_member"("p_project_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."mirror_auth_user_to_public"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
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


ALTER FUNCTION "public"."mirror_auth_user_to_public"() OWNER TO "postgres";


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

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."artifacts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "project_id" "uuid" NOT NULL,
    "parent_folder_id" "uuid",
    "type" "text" NOT NULL,
    "name" "text" DEFAULT ''::"text" NOT NULL,
    "body" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_by" "uuid",
    CONSTRAINT "artifacts_type_check" CHECK (("type" = ANY (ARRAY['folder'::"text", 'note'::"text", 'canvas'::"text"])))
);


ALTER TABLE "public"."artifacts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."canvas_objects" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "canvas_artifact_id" "uuid" NOT NULL,
    "kind" "text" NOT NULL,
    "payload" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_by" "uuid",
    CONSTRAINT "canvas_objects_kind_check" CHECK (("kind" = ANY (ARRAY['rectangle'::"text", 'diamond'::"text", 'oblong'::"text", 'circle'::"text", 'rhombus'::"text", 'trapezoid'::"text", 'cylinder'::"text", 'house'::"text", 'reverseHouse'::"text", 'text'::"text", 'image'::"text", 'brush'::"text", 'arrow'::"text", 'artifact'::"text"])))
);

ALTER TABLE ONLY "public"."canvas_objects" REPLICA IDENTITY FULL;


ALTER TABLE "public"."canvas_objects" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."comments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "target_id" "uuid" NOT NULL,
    "target_type" "text" DEFAULT 'canvas'::"text" NOT NULL,
    "author_id" "uuid" NOT NULL,
    "body" "text" DEFAULT ''::"text" NOT NULL,
    "x" double precision,
    "y" double precision,
    "color" integer DEFAULT 0 NOT NULL,
    "pinned_object_id" "uuid",
    "resolved" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_by" "uuid",
    CONSTRAINT "comments_target_type_check" CHECK (("target_type" = ANY (ARRAY['canvas'::"text", 'note'::"text"])))
);

ALTER TABLE ONLY "public"."comments" REPLICA IDENTITY FULL;


ALTER TABLE "public"."comments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."history_diffs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "canvas_artifact_id" "uuid" NOT NULL,
    "seq" integer NOT NULL,
    "diff" "jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_by" "uuid"
);

ALTER TABLE ONLY "public"."history_diffs" REPLICA IDENTITY FULL;


ALTER TABLE "public"."history_diffs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."pins" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "canvas_artifact_id" "uuid" NOT NULL,
    "linked_artifact_id" "uuid",
    "target_object_id" "uuid",
    "x" double precision DEFAULT 0 NOT NULL,
    "y" double precision DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_by" "uuid"
);

ALTER TABLE ONLY "public"."pins" REPLICA IDENTITY FULL;


ALTER TABLE "public"."pins" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."project_members" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "project_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "role" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_by" "uuid",
    CONSTRAINT "project_members_role_check" CHECK (("role" = ANY (ARRAY['member'::"text", 'admin'::"text", 'owner'::"text"])))
);


ALTER TABLE "public"."project_members" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."projects" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" DEFAULT ''::"text" NOT NULL,
    "owner_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_by" "uuid"
);


ALTER TABLE "public"."projects" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."storage_files" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "project_id" "uuid",
    "canvas_id" "uuid",
    "user_id" "uuid" NOT NULL,
    "name" "text" DEFAULT ''::"text" NOT NULL,
    "path" "text" NOT NULL,
    "mime" "text" DEFAULT ''::"text" NOT NULL,
    "size" bigint NOT NULL,
    "metadata" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_by" "uuid"
);


ALTER TABLE "public"."storage_files" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."sub_comments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "comment_id" "uuid" NOT NULL,
    "author_id" "uuid" NOT NULL,
    "body" "text" DEFAULT ''::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_by" "uuid"
);

ALTER TABLE ONLY "public"."sub_comments" REPLICA IDENTITY FULL;


ALTER TABLE "public"."sub_comments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."users" (
    "id" "uuid" NOT NULL,
    "email" "text" NOT NULL,
    "name" "text" DEFAULT ''::"text" NOT NULL,
    "about_me" "text" DEFAULT ''::"text" NOT NULL,
    "image_url" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_by" "uuid"
);


ALTER TABLE "public"."users" OWNER TO "postgres";


ALTER TABLE ONLY "public"."artifacts"
    ADD CONSTRAINT "artifacts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."canvas_objects"
    ADD CONSTRAINT "canvas_objects_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."history_diffs"
    ADD CONSTRAINT "history_diffs_canvas_artifact_id_seq_key" UNIQUE ("canvas_artifact_id", "seq");



ALTER TABLE ONLY "public"."history_diffs"
    ADD CONSTRAINT "history_diffs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pins"
    ADD CONSTRAINT "pins_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."project_members"
    ADD CONSTRAINT "project_members_pkey" PRIMARY KEY ("project_id", "user_id");



ALTER TABLE ONLY "public"."projects"
    ADD CONSTRAINT "projects_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."storage_files"
    ADD CONSTRAINT "storage_files_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."sub_comments"
    ADD CONSTRAINT "sub_comments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_email_key" UNIQUE ("email");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_pkey" PRIMARY KEY ("id");



CREATE INDEX "artifacts_project_id_idx" ON "public"."artifacts" USING "btree" ("project_id");



CREATE INDEX "artifacts_project_id_parent_folder_id_idx" ON "public"."artifacts" USING "btree" ("project_id", "parent_folder_id");



CREATE INDEX "artifacts_project_id_type_idx" ON "public"."artifacts" USING "btree" ("project_id", "type");



CREATE INDEX "canvas_objects_canvas_artifact_id_idx" ON "public"."canvas_objects" USING "btree" ("canvas_artifact_id");



CREATE INDEX "comments_pinned_object_id_idx" ON "public"."comments" USING "btree" ("pinned_object_id") WHERE ("pinned_object_id" IS NOT NULL);



CREATE INDEX "comments_target_id_idx" ON "public"."comments" USING "btree" ("target_id");



CREATE INDEX "history_diffs_canvas_artifact_id_seq_idx" ON "public"."history_diffs" USING "btree" ("canvas_artifact_id", "seq");



CREATE INDEX "pins_canvas_artifact_id_idx" ON "public"."pins" USING "btree" ("canvas_artifact_id");



CREATE INDEX "pins_linked_artifact_id_idx" ON "public"."pins" USING "btree" ("linked_artifact_id") WHERE ("linked_artifact_id" IS NOT NULL);



CREATE INDEX "pins_target_object_id_idx" ON "public"."pins" USING "btree" ("target_object_id") WHERE ("target_object_id" IS NOT NULL);



CREATE INDEX "project_members_user_id_idx" ON "public"."project_members" USING "btree" ("user_id");



CREATE INDEX "storage_files_canvas_id_idx" ON "public"."storage_files" USING "btree" ("canvas_id") WHERE ("canvas_id" IS NOT NULL);



CREATE INDEX "storage_files_project_id_idx" ON "public"."storage_files" USING "btree" ("project_id");



CREATE INDEX "sub_comments_comment_id_idx" ON "public"."sub_comments" USING "btree" ("comment_id");



CREATE INDEX "users_email_idx" ON "public"."users" USING "btree" ("email");



CREATE OR REPLACE TRIGGER "artifacts_bump_project" AFTER INSERT OR DELETE OR UPDATE ON "public"."artifacts" FOR EACH ROW EXECUTE FUNCTION "public"."bump_project_updated_at"();



CREATE OR REPLACE TRIGGER "artifacts_set_created" BEFORE INSERT ON "public"."artifacts" FOR EACH ROW EXECUTE FUNCTION "public"."set_created_audit"();



CREATE OR REPLACE TRIGGER "artifacts_set_updated" BEFORE UPDATE ON "public"."artifacts" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_audit"();



CREATE OR REPLACE TRIGGER "canvas_objects_bump_project" AFTER INSERT OR DELETE OR UPDATE ON "public"."canvas_objects" FOR EACH ROW EXECUTE FUNCTION "public"."bump_project_updated_at"();



CREATE OR REPLACE TRIGGER "canvas_objects_set_created" BEFORE INSERT ON "public"."canvas_objects" FOR EACH ROW EXECUTE FUNCTION "public"."set_created_audit"();



CREATE OR REPLACE TRIGGER "canvas_objects_set_updated" BEFORE UPDATE ON "public"."canvas_objects" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_audit"();



CREATE OR REPLACE TRIGGER "comments_bump_project" AFTER INSERT OR DELETE OR UPDATE ON "public"."comments" FOR EACH ROW EXECUTE FUNCTION "public"."bump_project_updated_at"();



CREATE OR REPLACE TRIGGER "comments_set_created" BEFORE INSERT ON "public"."comments" FOR EACH ROW EXECUTE FUNCTION "public"."set_created_audit"();



CREATE OR REPLACE TRIGGER "comments_set_updated" BEFORE UPDATE ON "public"."comments" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_audit"();



CREATE OR REPLACE TRIGGER "history_diffs_assign_seq" BEFORE INSERT ON "public"."history_diffs" FOR EACH ROW EXECUTE FUNCTION "public"."assign_history_diff_seq"();



CREATE OR REPLACE TRIGGER "history_diffs_bump_project" AFTER INSERT OR DELETE OR UPDATE ON "public"."history_diffs" FOR EACH ROW EXECUTE FUNCTION "public"."bump_project_updated_at"();



CREATE OR REPLACE TRIGGER "history_diffs_set_created" BEFORE INSERT ON "public"."history_diffs" FOR EACH ROW EXECUTE FUNCTION "public"."set_created_audit"();



CREATE OR REPLACE TRIGGER "history_diffs_set_updated" BEFORE UPDATE ON "public"."history_diffs" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_audit"();



CREATE OR REPLACE TRIGGER "pins_bump_project" AFTER INSERT OR DELETE OR UPDATE ON "public"."pins" FOR EACH ROW EXECUTE FUNCTION "public"."bump_project_updated_at"();



CREATE OR REPLACE TRIGGER "pins_set_created" BEFORE INSERT ON "public"."pins" FOR EACH ROW EXECUTE FUNCTION "public"."set_created_audit"();



CREATE OR REPLACE TRIGGER "pins_set_updated" BEFORE UPDATE ON "public"."pins" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_audit"();



CREATE OR REPLACE TRIGGER "project_members_set_created" BEFORE INSERT ON "public"."project_members" FOR EACH ROW EXECUTE FUNCTION "public"."set_created_audit"();



CREATE OR REPLACE TRIGGER "project_members_set_updated" BEFORE UPDATE ON "public"."project_members" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_audit"();



CREATE OR REPLACE TRIGGER "projects_add_owner" AFTER INSERT ON "public"."projects" FOR EACH ROW EXECUTE FUNCTION "public"."add_owner_to_members"();



CREATE OR REPLACE TRIGGER "projects_set_created" BEFORE INSERT ON "public"."projects" FOR EACH ROW EXECUTE FUNCTION "public"."set_created_audit"();



CREATE OR REPLACE TRIGGER "projects_set_updated" BEFORE UPDATE ON "public"."projects" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_audit"();



CREATE OR REPLACE TRIGGER "storage_files_set_created" BEFORE INSERT ON "public"."storage_files" FOR EACH ROW EXECUTE FUNCTION "public"."set_created_audit"();



CREATE OR REPLACE TRIGGER "storage_files_set_updated" BEFORE UPDATE ON "public"."storage_files" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_audit"();



CREATE OR REPLACE TRIGGER "sub_comments_set_created" BEFORE INSERT ON "public"."sub_comments" FOR EACH ROW EXECUTE FUNCTION "public"."set_created_audit"();



CREATE OR REPLACE TRIGGER "sub_comments_set_updated" BEFORE UPDATE ON "public"."sub_comments" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_audit"();



CREATE OR REPLACE TRIGGER "users_set_created" BEFORE INSERT ON "public"."users" FOR EACH ROW EXECUTE FUNCTION "public"."set_created_audit"();



CREATE OR REPLACE TRIGGER "users_set_updated" BEFORE UPDATE ON "public"."users" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_audit"();



ALTER TABLE ONLY "public"."artifacts"
    ADD CONSTRAINT "artifacts_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."artifacts"
    ADD CONSTRAINT "artifacts_parent_folder_id_fkey" FOREIGN KEY ("parent_folder_id") REFERENCES "public"."artifacts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."artifacts"
    ADD CONSTRAINT "artifacts_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."artifacts"
    ADD CONSTRAINT "artifacts_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."canvas_objects"
    ADD CONSTRAINT "canvas_objects_canvas_artifact_id_fkey" FOREIGN KEY ("canvas_artifact_id") REFERENCES "public"."artifacts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."canvas_objects"
    ADD CONSTRAINT "canvas_objects_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."canvas_objects"
    ADD CONSTRAINT "canvas_objects_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_author_id_fkey" FOREIGN KEY ("author_id") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_pinned_object_id_fkey" FOREIGN KEY ("pinned_object_id") REFERENCES "public"."canvas_objects"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_target_id_fkey" FOREIGN KEY ("target_id") REFERENCES "public"."artifacts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."history_diffs"
    ADD CONSTRAINT "history_diffs_canvas_artifact_id_fkey" FOREIGN KEY ("canvas_artifact_id") REFERENCES "public"."artifacts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."history_diffs"
    ADD CONSTRAINT "history_diffs_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."history_diffs"
    ADD CONSTRAINT "history_diffs_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."pins"
    ADD CONSTRAINT "pins_canvas_artifact_id_fkey" FOREIGN KEY ("canvas_artifact_id") REFERENCES "public"."artifacts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pins"
    ADD CONSTRAINT "pins_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."pins"
    ADD CONSTRAINT "pins_linked_artifact_id_fkey" FOREIGN KEY ("linked_artifact_id") REFERENCES "public"."artifacts"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."pins"
    ADD CONSTRAINT "pins_target_object_id_fkey" FOREIGN KEY ("target_object_id") REFERENCES "public"."canvas_objects"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."pins"
    ADD CONSTRAINT "pins_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."project_members"
    ADD CONSTRAINT "project_members_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."project_members"
    ADD CONSTRAINT "project_members_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."project_members"
    ADD CONSTRAINT "project_members_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."project_members"
    ADD CONSTRAINT "project_members_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."projects"
    ADD CONSTRAINT "projects_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."projects"
    ADD CONSTRAINT "projects_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."projects"
    ADD CONSTRAINT "projects_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."storage_files"
    ADD CONSTRAINT "storage_files_canvas_id_fkey" FOREIGN KEY ("canvas_id") REFERENCES "public"."artifacts"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."storage_files"
    ADD CONSTRAINT "storage_files_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."storage_files"
    ADD CONSTRAINT "storage_files_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."storage_files"
    ADD CONSTRAINT "storage_files_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."storage_files"
    ADD CONSTRAINT "storage_files_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."sub_comments"
    ADD CONSTRAINT "sub_comments_author_id_fkey" FOREIGN KEY ("author_id") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."sub_comments"
    ADD CONSTRAINT "sub_comments_comment_id_fkey" FOREIGN KEY ("comment_id") REFERENCES "public"."comments"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."sub_comments"
    ADD CONSTRAINT "sub_comments_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."sub_comments"
    ADD CONSTRAINT "sub_comments_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "auth"."users"("id");



ALTER TABLE "public"."artifacts" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "artifacts_all" ON "public"."artifacts" TO "authenticated" USING ("public"."is_project_member"("project_id")) WITH CHECK ("public"."is_project_member"("project_id"));



ALTER TABLE "public"."canvas_objects" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "canvas_objects_all" ON "public"."canvas_objects" TO "authenticated" USING ("public"."is_project_member"(( SELECT "artifacts"."project_id"
   FROM "public"."artifacts"
  WHERE ("artifacts"."id" = "canvas_objects"."canvas_artifact_id")))) WITH CHECK ("public"."is_project_member"(( SELECT "artifacts"."project_id"
   FROM "public"."artifacts"
  WHERE ("artifacts"."id" = "canvas_objects"."canvas_artifact_id"))));



ALTER TABLE "public"."comments" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "comments_all" ON "public"."comments" TO "authenticated" USING ("public"."is_project_member"(( SELECT "artifacts"."project_id"
   FROM "public"."artifacts"
  WHERE ("artifacts"."id" = "comments"."target_id")))) WITH CHECK ("public"."is_project_member"(( SELECT "artifacts"."project_id"
   FROM "public"."artifacts"
  WHERE ("artifacts"."id" = "comments"."target_id"))));



ALTER TABLE "public"."history_diffs" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "history_diffs_all" ON "public"."history_diffs" TO "authenticated" USING ("public"."is_project_member"(( SELECT "artifacts"."project_id"
   FROM "public"."artifacts"
  WHERE ("artifacts"."id" = "history_diffs"."canvas_artifact_id")))) WITH CHECK ("public"."is_project_member"(( SELECT "artifacts"."project_id"
   FROM "public"."artifacts"
  WHERE ("artifacts"."id" = "history_diffs"."canvas_artifact_id"))));



ALTER TABLE "public"."pins" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "pins_all" ON "public"."pins" TO "authenticated" USING ("public"."is_project_member"(( SELECT "artifacts"."project_id"
   FROM "public"."artifacts"
  WHERE ("artifacts"."id" = "pins"."canvas_artifact_id")))) WITH CHECK ("public"."is_project_member"(( SELECT "artifacts"."project_id"
   FROM "public"."artifacts"
  WHERE ("artifacts"."id" = "pins"."canvas_artifact_id"))));



ALTER TABLE "public"."project_members" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "project_members_delete" ON "public"."project_members" FOR DELETE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."project_members" "pm"
  WHERE (("pm"."project_id" = "project_members"."project_id") AND ("pm"."user_id" = "auth"."uid"()) AND ("pm"."role" = ANY (ARRAY['admin'::"text", 'owner'::"text"]))))));



CREATE POLICY "project_members_insert" ON "public"."project_members" FOR INSERT TO "authenticated" WITH CHECK (((("user_id" = "auth"."uid"()) AND ("role" = 'owner'::"text") AND (EXISTS ( SELECT 1
   FROM "public"."projects"
  WHERE (("projects"."id" = "project_members"."project_id") AND ("projects"."owner_id" = "auth"."uid"()))))) OR (EXISTS ( SELECT 1
   FROM "public"."project_members" "pm"
  WHERE (("pm"."project_id" = "project_members"."project_id") AND ("pm"."user_id" = "auth"."uid"()) AND ("pm"."role" = ANY (ARRAY['admin'::"text", 'owner'::"text"])))))));



CREATE POLICY "project_members_select" ON "public"."project_members" FOR SELECT TO "authenticated" USING ("public"."is_project_member"("project_id"));



CREATE POLICY "project_members_update" ON "public"."project_members" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."project_members" "pm"
  WHERE (("pm"."project_id" = "project_members"."project_id") AND ("pm"."user_id" = "auth"."uid"()) AND ("pm"."role" = ANY (ARRAY['admin'::"text", 'owner'::"text"])))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."project_members" "pm"
  WHERE (("pm"."project_id" = "project_members"."project_id") AND ("pm"."user_id" = "auth"."uid"()) AND ("pm"."role" = ANY (ARRAY['admin'::"text", 'owner'::"text"]))))));



ALTER TABLE "public"."projects" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "projects_delete" ON "public"."projects" FOR DELETE TO "authenticated" USING ((("owner_id" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."project_members"
  WHERE (("project_members"."project_id" = "projects"."id") AND ("project_members"."user_id" = "auth"."uid"()) AND ("project_members"."role" = ANY (ARRAY['admin'::"text", 'owner'::"text"])))))));



CREATE POLICY "projects_insert" ON "public"."projects" FOR INSERT TO "authenticated" WITH CHECK (("owner_id" = "auth"."uid"()));



CREATE POLICY "projects_select" ON "public"."projects" FOR SELECT TO "authenticated" USING ((("owner_id" = "auth"."uid"()) OR "public"."is_project_member"("id")));



CREATE POLICY "projects_update" ON "public"."projects" FOR UPDATE TO "authenticated" USING ((("owner_id" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."project_members"
  WHERE (("project_members"."project_id" = "projects"."id") AND ("project_members"."user_id" = "auth"."uid"()) AND ("project_members"."role" = ANY (ARRAY['admin'::"text", 'owner'::"text"]))))))) WITH CHECK ((("owner_id" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."project_members"
  WHERE (("project_members"."project_id" = "projects"."id") AND ("project_members"."user_id" = "auth"."uid"()) AND ("project_members"."role" = ANY (ARRAY['admin'::"text", 'owner'::"text"])))))));



ALTER TABLE "public"."storage_files" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "storage_files_all" ON "public"."storage_files" TO "authenticated" USING (((("project_id" IS NOT NULL) AND "public"."is_project_member"("project_id")) OR (("project_id" IS NULL) AND ("user_id" = "auth"."uid"())))) WITH CHECK (((("project_id" IS NOT NULL) AND "public"."is_project_member"("project_id")) OR (("project_id" IS NULL) AND ("user_id" = "auth"."uid"()))));



ALTER TABLE "public"."sub_comments" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "sub_comments_all" ON "public"."sub_comments" TO "authenticated" USING ("public"."is_project_member"(( SELECT "a"."project_id"
   FROM ("public"."comments" "c"
     JOIN "public"."artifacts" "a" ON (("a"."id" = "c"."target_id")))
  WHERE ("c"."id" = "sub_comments"."comment_id")))) WITH CHECK ("public"."is_project_member"(( SELECT "a"."project_id"
   FROM ("public"."comments" "c"
     JOIN "public"."artifacts" "a" ON (("a"."id" = "c"."target_id")))
  WHERE ("c"."id" = "sub_comments"."comment_id"))));



ALTER TABLE "public"."users" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "users_insert_self" ON "public"."users" FOR INSERT TO "authenticated" WITH CHECK (("id" = "auth"."uid"()));



CREATE POLICY "users_select" ON "public"."users" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "users_update_self" ON "public"."users" FOR UPDATE TO "authenticated" USING (("id" = "auth"."uid"())) WITH CHECK (("id" = "auth"."uid"()));





ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."artifacts";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."canvas_objects";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."comments";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."history_diffs";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."pins";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."storage_files";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."sub_comments";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."users";






GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";




























































































































































GRANT ALL ON FUNCTION "public"."add_owner_to_members"() TO "anon";
GRANT ALL ON FUNCTION "public"."add_owner_to_members"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."add_owner_to_members"() TO "service_role";



GRANT ALL ON FUNCTION "public"."assign_history_diff_seq"() TO "anon";
GRANT ALL ON FUNCTION "public"."assign_history_diff_seq"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."assign_history_diff_seq"() TO "service_role";



GRANT ALL ON FUNCTION "public"."bump_project_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."bump_project_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."bump_project_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."is_project_member"("p_project_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."is_project_member"("p_project_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_project_member"("p_project_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."mirror_auth_user_to_public"() TO "anon";
GRANT ALL ON FUNCTION "public"."mirror_auth_user_to_public"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."mirror_auth_user_to_public"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_created_audit"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_created_audit"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_created_audit"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_updated_audit"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_updated_audit"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_updated_audit"() TO "service_role";


















GRANT ALL ON TABLE "public"."artifacts" TO "anon";
GRANT ALL ON TABLE "public"."artifacts" TO "authenticated";
GRANT ALL ON TABLE "public"."artifacts" TO "service_role";



GRANT ALL ON TABLE "public"."canvas_objects" TO "anon";
GRANT ALL ON TABLE "public"."canvas_objects" TO "authenticated";
GRANT ALL ON TABLE "public"."canvas_objects" TO "service_role";



GRANT ALL ON TABLE "public"."comments" TO "anon";
GRANT ALL ON TABLE "public"."comments" TO "authenticated";
GRANT ALL ON TABLE "public"."comments" TO "service_role";



GRANT ALL ON TABLE "public"."history_diffs" TO "anon";
GRANT ALL ON TABLE "public"."history_diffs" TO "authenticated";
GRANT ALL ON TABLE "public"."history_diffs" TO "service_role";



GRANT ALL ON TABLE "public"."pins" TO "anon";
GRANT ALL ON TABLE "public"."pins" TO "authenticated";
GRANT ALL ON TABLE "public"."pins" TO "service_role";



GRANT ALL ON TABLE "public"."project_members" TO "anon";
GRANT ALL ON TABLE "public"."project_members" TO "authenticated";
GRANT ALL ON TABLE "public"."project_members" TO "service_role";



GRANT ALL ON TABLE "public"."projects" TO "anon";
GRANT ALL ON TABLE "public"."projects" TO "authenticated";
GRANT ALL ON TABLE "public"."projects" TO "service_role";



GRANT ALL ON TABLE "public"."storage_files" TO "anon";
GRANT ALL ON TABLE "public"."storage_files" TO "authenticated";
GRANT ALL ON TABLE "public"."storage_files" TO "service_role";



GRANT ALL ON TABLE "public"."sub_comments" TO "anon";
GRANT ALL ON TABLE "public"."sub_comments" TO "authenticated";
GRANT ALL ON TABLE "public"."sub_comments" TO "service_role";



GRANT ALL ON TABLE "public"."users" TO "anon";
GRANT ALL ON TABLE "public"."users" TO "authenticated";
GRANT ALL ON TABLE "public"."users" TO "service_role";









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































