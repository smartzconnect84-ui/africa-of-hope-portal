-- Africa of Hope portal — full database schema baseline
-- Captured from project gatnzfjpuokopqyksqoy on 2026-11-28T07:07:54.353Z by scripts/capture-schema.mjs
-- Server: PostgreSQL 17.11
-- Capturable schemas: public
--
-- This is a reference snapshot of production, generated from pg_catalog.
-- Do NOT replay it onto a database that already contains these objects:
-- it is a baseline to diff against, not an incremental migration.
-- Owner assignments, default privileges, extension internals and Supabase
-- platform schemas (auth, cron, extensions, graphql, graphql_public, information_schema, net, pg_catalog, pgbouncer, realtime, storage, supabase_functions, supabase_migrations, vault) are out of scope.
-- Defaults or CHECK constraints that call a portal function expect that
-- function to exist already; replay such objects after the Functions section.
--
-- Regenerate with:
--   SUPABASE_DB_URL=... node scripts/capture-schema.mjs

-- ---------------------------------------------------------------------------
-- Schemas
-- ---------------------------------------------------------------------------
-- (public already exists in a Supabase database)

-- ---------------------------------------------------------------------------
-- Extensions
-- ---------------------------------------------------------------------------
create extension if not exists "pg_cron" with schema "pg_catalog" version '1.6.4';
create extension if not exists "pg_net" with schema "public" version '0.20.4';
create extension if not exists "pg_stat_statements" with schema "extensions" version '1.11';
create extension if not exists "pgcrypto" with schema "extensions" version '1.3';
create extension if not exists "supabase_vault" with schema "vault" version '0.3.1';
create extension if not exists "uuid-ossp" with schema "extensions" version '1.1';

-- ---------------------------------------------------------------------------
-- Enum and domain types
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- Sequences
-- ---------------------------------------------------------------------------
create sequence if not exists "public"."certificate_serial_sequence" as bigint start with 1 increment by 1 minvalue 1 maxvalue 9223372036854775807 cache 1 no cycle;
create sequence if not exists "public"."payment_receipt_seq" as bigint start with 1 increment by 1 minvalue 1 maxvalue 9223372036854775807 cache 1 no cycle;

-- ---------------------------------------------------------------------------
-- Tables and columns
-- ---------------------------------------------------------------------------
create table if not exists "public"."alumni_businesses" (
  "id" uuid default gen_random_uuid() not null,
  "name" text not null,
  "owner_name" text default ''::text not null,
  "category" text default 'Other'::text not null,
  "location" text default ''::text not null,
  "contact" text default ''::text not null,
  "description" text default ''::text not null,
  "logo_url" text,
  "is_approved" boolean default false not null,
  "created_by" uuid,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);
create table if not exists "public"."announcements" (
  "id" uuid default gen_random_uuid() not null,
  "title" text not null,
  "body" text default ''::text not null,
  "author_id" uuid,
  "audience" text default 'all'::text not null,
  "status" text default 'published'::text not null,
  "scheduled_at" timestamp with time zone,
  "expires_at" timestamp with time zone,
  "published_at" timestamp with time zone,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null,
  "published_date" date default CURRENT_DATE not null,
  "author" text
);
create table if not exists "public"."app_integration_events" (
  "id" uuid default gen_random_uuid() not null,
  "app_slug" text not null,
  "manifest_id" text not null,
  "event_type" text,
  "external_id" text,
  "user_id" uuid,
  "payload" jsonb,
  "received_at" timestamp with time zone default now() not null
);
create table if not exists "public"."app_integration_usage" (
  "day" date not null,
  "manifest_id" text not null,
  "person" text not null,
  "count" integer default 0 not null,
  "refused" integer default 0 not null,
  "anon" boolean default false not null
);
create table if not exists "public"."app_integration_watch" (
  "day" date not null,
  "manifest_id" text not null,
  "op" text not null,
  "rule" text not null,
  "count" integer default 0 not null
);
create table if not exists "public"."app_integrations" (
  "id" uuid default gen_random_uuid() not null,
  "app_slug" text not null,
  "manifest_id" text not null,
  "manifest" jsonb not null,
  "public_values" jsonb default '{}'::jsonb not null,
  "secret_refs" jsonb default '{}'::jsonb not null,
  "edge_function_slug" text,
  "last_probe_at" timestamp with time zone,
  "last_probe_ok" boolean,
  "last_probe_message" text,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null,
  "platform_invoke_token" text,
  "configure_state" jsonb,
  "policy" jsonb
);
create table if not exists "public"."application_drafts" (
  "id" uuid default gen_random_uuid() not null,
  "email" text not null,
  "payload" jsonb default '{}'::jsonb not null,
  "updated_at" timestamp with time zone default now() not null,
  "created_at" timestamp with time zone default now() not null
);
create table if not exists "public"."approval_events" (
  "id" uuid default gen_random_uuid() not null,
  "entity_type" text not null,
  "entity_id" uuid not null,
  "action" text not null,
  "actor_id" uuid,
  "note" text default ''::text not null,
  "snapshot" jsonb default '{}'::jsonb not null,
  "created_at" timestamp with time zone default now() not null
);
create table if not exists "public"."aptitude_control_settings" (
  "id" integer default 1 not null,
  "require_pass" boolean default true not null,
  "pass_mark" numeric default 50 not null,
  "time_minutes" integer default 15 not null,
  "max_attempts" integer default 3 not null,
  "prep_pack_url" text default ''::text not null,
  "prep_instructions" text default ''::text not null,
  "updated_at" timestamp with time zone default now() not null
);
create table if not exists "public"."aptitude_preparations" (
  "id" uuid default gen_random_uuid() not null,
  "title" text not null,
  "body" text default ''::text not null,
  "sort_order" integer default 0 not null,
  "published" boolean default true not null,
  "created_at" timestamp with time zone default now() not null
);
create table if not exists "public"."assignments" (
  "id" uuid default gen_random_uuid() not null,
  "cohort_id" uuid not null,
  "title" text not null,
  "description" text default ''::text not null,
  "due_date" date,
  "max_score" numeric default 100 not null,
  "status" text default 'Draft'::text not null,
  "created_by" uuid,
  "learning_unit_id" uuid,
  "time_limit_minutes" integer,
  "grade_weight" numeric default 0 not null,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null,
  "max_marks" numeric default 100
);
create table if not exists "public"."assistant_research_resources" (
  "id" uuid default gen_random_uuid() not null,
  "owner_id" uuid default auth.uid() not null,
  "title" text not null,
  "content" text not null,
  "source_url" text,
  "visibility" text default 'private'::text not null,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);
create table if not exists "public"."assistant_usage" (
  "bucket" text not null,
  "window_start" timestamp with time zone not null,
  "requests" integer default 0 not null,
  "tokens" integer default 0 not null
);
create table if not exists "public"."attendance" (
  "id" uuid default gen_random_uuid() not null,
  "cohort_id" uuid not null,
  "student_id" uuid not null,
  "attendance_date" date default CURRENT_DATE not null,
  "status" text default 'Absent'::text not null,
  "notes" text default ''::text not null,
  "recorded_by" uuid,
  "class_session_id" uuid,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);
create table if not exists "public"."blog_posts" (
  "id" uuid default gen_random_uuid() not null,
  "slug" text not null,
  "title" text not null,
  "excerpt" text default ''::text not null,
  "body" text default ''::text not null,
  "cover_image_url" text,
  "cover_image_path" text,
  "category" text default 'News'::text not null,
  "tags" text[] default '{}'::text[] not null,
  "author_id" uuid,
  "author_name" text default ''::text not null,
  "status" text default 'draft'::text not null,
  "featured" boolean default false not null,
  "published_at" timestamp with time zone,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null,
  "program_id" uuid,
  "program_title" text
);
create table if not exists "public"."certificate_audit" (
  "id" uuid default gen_random_uuid() not null,
  "certificate_id" uuid,
  "serial" text not null,
  "action" text not null,
  "actor_id" uuid,
  "reason" text,
  "created_at" timestamp with time zone default now() not null
);
create table if not exists "public"."certificates" (
  "id" uuid default gen_random_uuid() not null,
  "student_id" uuid not null,
  "program_id" uuid,
  "cohort_id" uuid,
  "certificate_number" text default ('AOH-CERT-'::text || upper(replace((gen_random_uuid())::text, '-'::text, ''::text))) not null,
  "issue_date" date default CURRENT_DATE not null,
  "certificate_url" text,
  "status" text default 'issued'::text not null,
  "issued_by" uuid,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null,
  "serial" text not null,
  "honors" text,
  "grade" text,
  "revoked_at" timestamp with time zone,
  "revoked_by" uuid,
  "revocation_reason" text,
  "certificate_type" text default 'Certificate of Completion'::text,
  "completion_date" date
);
create table if not exists "public"."chat_drafts" (
  "id" uuid default gen_random_uuid() not null,
  "user_id" uuid not null,
  "thread_key" text not null,
  "body" text default ''::text not null,
  "updated_at" timestamp with time zone default now() not null
);
comment on table "public"."chat_drafts" is 'Per-conversation message drafts. The workspace mirrors these locally so a draft survives an offline reload.';
create table if not exists "public"."chat_group_invites" (
  "id" uuid default gen_random_uuid() not null,
  "group_id" uuid not null,
  "inviter_id" uuid,
  "invitee_id" uuid,
  "token" text,
  "status" text default 'pending'::text not null,
  "expires_at" timestamp with time zone,
  "created_at" timestamp with time zone default now() not null
);
create table if not exists "public"."chat_group_join_requests" (
  "id" uuid default gen_random_uuid() not null,
  "group_id" uuid not null,
  "user_id" uuid not null,
  "message" text,
  "status" text default 'pending'::text not null,
  "created_at" timestamp with time zone default now() not null
);
create table if not exists "public"."chat_group_members" (
  "group_id" uuid not null,
  "user_id" uuid not null,
  "member_role" text default 'member'::text not null,
  "joined_at" timestamp with time zone default now() not null,
  "last_read_at" timestamp with time zone default now() not null
);
create table if not exists "public"."chat_groups" (
  "id" uuid default gen_random_uuid() not null,
  "name" text not null,
  "description" text default ''::text not null,
  "avatar_url" text,
  "created_by" uuid not null,
  "created_at" timestamp with time zone default now() not null,
  "permissions" jsonb default '{}'::jsonb,
  "join_policy" text default 'invite'::text,
  "background_url" text
);
create table if not exists "public"."chat_poll_votes" (
  "id" uuid default gen_random_uuid() not null,
  "poll_id" uuid not null,
  "user_id" uuid not null,
  "option_index" integer not null,
  "created_at" timestamp with time zone default now() not null
);
create table if not exists "public"."chat_polls" (
  "id" uuid default gen_random_uuid() not null,
  "group_id" uuid,
  "dm_thread" text,
  "creator_id" uuid,
  "question" text not null,
  "options" jsonb default '[]'::jsonb not null,
  "multiple" boolean default false,
  "expires_at" timestamp with time zone,
  "created_at" timestamp with time zone default now() not null
);
create table if not exists "public"."class_sessions" (
  "id" uuid default gen_random_uuid() not null,
  "cohort_id" uuid not null,
  "learning_unit_id" uuid,
  "course_plan_id" uuid,
  "teacher_id" uuid default auth.uid() not null,
  "title" text not null,
  "session_date" date not null,
  "starts_at" time without time zone not null,
  "ends_at" time without time zone not null,
  "room" text default ''::text not null,
  "attendance_required" boolean default true not null,
  "status" text default 'draft'::text not null,
  "notes" text default ''::text not null,
  "submitted_at" timestamp with time zone,
  "approved_at" timestamp with time zone,
  "reviewed_at" timestamp with time zone,
  "reviewed_by" uuid,
  "revision_note" text,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);
create table if not exists "public"."cohort_students" (
  "cohort_id" uuid not null,
  "student_id" uuid not null,
  "enrolled_at" timestamp with time zone default now() not null,
  "enrollment_source" text default 'manual'::text not null,
  "active" boolean default true not null,
  "completed_at" timestamp with time zone
);
create table if not exists "public"."cohort_timetable_slots" (
  "id" uuid default gen_random_uuid() not null,
  "cohort_id" text not null,
  "day_of_week" integer not null,
  "title" text default ''::text not null,
  "teacher_id" text default ''::text not null,
  "room" text default ''::text not null,
  "starts_at" text default '08:00'::text not null,
  "ends_at" text default '09:00'::text not null,
  "notes" text default ''::text not null,
  "created_at" timestamp with time zone default now() not null
);
create table if not exists "public"."cohorts" (
  "id" uuid default gen_random_uuid() not null,
  "program_id" uuid not null,
  "name" text not null,
  "code" text not null,
  "teacher_id" uuid,
  "start_date" date default CURRENT_DATE not null,
  "end_date" date default (CURRENT_DATE + 365) not null,
  "capacity" integer,
  "enrollment_opens_at" timestamp with time zone,
  "enrollment_closes_at" timestamp with time zone,
  "enrollment_status" text default 'open'::text not null,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null,
  "room" text,
  "avatar_url" text
);
create table if not exists "public"."course_completions" (
  "id" uuid default gen_random_uuid() not null,
  "student_id" uuid not null,
  "cohort_id" uuid not null,
  "program_id" uuid not null,
  "status" text default 'in_progress'::text not null,
  "course_grade" numeric,
  "attendance_percent" numeric,
  "completed_at" timestamp with time zone,
  "issued_by" uuid,
  "notes" text default ''::text not null,
  "updated_at" timestamp with time zone default now() not null
);
create table if not exists "public"."course_enrollments" (
  "id" uuid default gen_random_uuid() not null,
  "cohort_id" uuid not null,
  "student_id" uuid not null,
  "status" text default 'submitted'::text not null,
  "workload" jsonb default '{}'::jsonb not null,
  "conflict_warnings" jsonb default '[]'::jsonb not null,
  "workload_warnings" jsonb default '[]'::jsonb not null,
  "requested_at" timestamp with time zone default now() not null,
  "submitted_at" timestamp with time zone,
  "approved_at" timestamp with time zone,
  "progress_percent" numeric default 0 not null,
  "completion_status" text default 'not_started'::text not null,
  "reviewed_at" timestamp with time zone,
  "reviewed_by" uuid,
  "revision_note" text default ''::text not null,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null,
  "learning_arrangement" text default 'blended'::text not null,
  "arrangement_config" jsonb default '{}'::jsonb not null,
  "arrangement_changed_at" timestamp with time zone default now() not null
);
create table if not exists "public"."crash_course_attempts" (
  "id" uuid default gen_random_uuid() not null,
  "course_id" uuid not null,
  "student_id" uuid not null,
  "score" numeric(5,2),
  "status" text default 'in_progress'::text not null,
  "started_at" timestamp with time zone default now() not null,
  "submitted_at" timestamp with time zone
);
create table if not exists "public"."crash_course_enrollments" (
  "id" uuid default gen_random_uuid() not null,
  "course_id" uuid not null,
  "student_id" uuid not null,
  "progress_percent" integer default 0 not null,
  "enrolled_at" timestamp with time zone default now() not null,
  "completed_at" timestamp with time zone
);
create table if not exists "public"."crash_course_lessons" (
  "id" uuid default gen_random_uuid() not null,
  "course_id" uuid not null,
  "title" text not null,
  "lesson_type" text not null,
  "content_url" text,
  "scheduled_at" timestamp with time zone,
  "duration_minutes" integer,
  "position" integer default 0 not null,
  "created_at" timestamp with time zone default now() not null
);
create table if not exists "public"."crash_courses" (
  "id" uuid default gen_random_uuid() not null,
  "title" text not null,
  "description" text,
  "duration_days" integer default 14 not null,
  "status" text default 'draft'::text not null,
  "starts_at" timestamp with time zone,
  "ends_at" timestamp with time zone,
  "created_by" uuid,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);
create table if not exists "public"."crash_programs" (
  "id" uuid default gen_random_uuid() not null,
  "title" text not null,
  "slug" text not null,
  "summary" text default ''::text not null,
  "description" text default ''::text not null,
  "duration_weeks" integer default 2 not null,
  "published" boolean default false not null,
  "created_by" uuid,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);
create table if not exists "public"."data_migrations" (
  "id" text not null,
  "applied_at" timestamp with time zone default now() not null,
  "note" text
);
create table if not exists "public"."direct_messages" (
  "id" uuid default gen_random_uuid() not null,
  "sender_id" uuid not null,
  "receiver_id" uuid not null,
  "body" text not null,
  "created_at" timestamp with time zone default now() not null,
  "seen_at" timestamp with time zone,
  "attachment_path" text,
  "attachment_type" text,
  "attachment_name" text,
  "duration_seconds" integer,
  "reply_to" uuid,
  "edited_at" timestamp with time zone,
  "deleted_at" timestamp with time zone,
  "pinned_at" timestamp with time zone,
  "pinned_by" uuid,
  "starred" boolean default false,
  "scheduled_at" timestamp with time zone,
  "expires_at" timestamp with time zone
);
create table if not exists "public"."discussion_replies" (
  "id" text not null,
  "thread_id" text not null,
  "author_id" uuid not null,
  "author_name" text default ''::text not null,
  "author_role" text default ''::text not null,
  "body" text not null,
  "is_answer" boolean default false not null,
  "created_at" timestamp with time zone default now() not null
);
create table if not exists "public"."discussion_threads" (
  "id" text not null,
  "cohort_id" uuid not null,
  "unit_id" uuid,
  "author_id" uuid not null,
  "author_name" text default ''::text not null,
  "author_role" text default ''::text not null,
  "title" text not null,
  "body" text not null,
  "created_at" timestamp with time zone default now() not null
);
create table if not exists "public"."email_outbox" (
  "id" uuid default gen_random_uuid() not null,
  "to_email" text not null,
  "to_name" text default ''::text not null,
  "template" text not null,
  "subject" text not null,
  "payload" jsonb default '{}'::jsonb not null,
  "status" text default 'queued'::text not null,
  "attempts" integer default 0 not null,
  "last_error" text,
  "provider_message_id" text,
  "send_after" timestamp with time zone default now() not null,
  "sent_at" timestamp with time zone,
  "dedupe_key" text,
  "related_user_id" uuid,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);
create table if not exists "public"."email_templates" (
  "id" uuid default gen_random_uuid() not null,
  "name" text not null,
  "subject" text not null,
  "body" text not null,
  "updated_at" timestamp with time zone default now() not null
);
create table if not exists "public"."enrollment_arrangement_history" (
  "id" uuid default gen_random_uuid() not null,
  "enrollment_id" uuid not null,
  "previous_arrangement" text,
  "next_arrangement" text not null,
  "changed_by" uuid default auth.uid(),
  "reason" text default ''::text not null,
  "created_at" timestamp with time zone default now() not null
);
create table if not exists "public"."entrance_settings" (
  "id" integer default 1 not null,
  "require_pass" boolean default true not null,
  "pass_mark" numeric default 50 not null,
  "time_minutes" integer default 15 not null,
  "max_attempts" integer default 3 not null,
  "updated_at" timestamp with time zone default now() not null
);
create table if not exists "public"."entrance_test_results" (
  "id" uuid default gen_random_uuid() not null,
  "quiz_id" uuid,
  "quiz_title" text default 'Entrance Aptitude Test'::text not null,
  "name" text not null,
  "contact" text not null,
  "programme" text default ''::text not null,
  "score" numeric default 0 not null,
  "max_score" numeric default 1 not null,
  "percent" numeric default 0 not null,
  "passed" boolean default false not null,
  "ref" text not null,
  "applicant_id" uuid,
  "created_at" timestamp with time zone default now() not null
);
create table if not exists "public"."fee_transactions" (
  "id" uuid default gen_random_uuid() not null,
  "student_id" uuid not null,
  "category" text default 'Tuition'::text not null,
  "amount" numeric(12,2) not null,
  "transaction_date" date default CURRENT_DATE not null,
  "method" text default ''::text not null,
  "reference" text default ''::text not null,
  "notes" text default ''::text not null,
  "created_by" uuid,
  "created_at" timestamp with time zone default now() not null
);
create table if not exists "public"."file_submissions" (
  "id" uuid default gen_random_uuid() not null,
  "submitter_id" uuid not null,
  "file_path" text not null,
  "file_name" text not null,
  "category" text default 'Other'::text not null,
  "size_bytes" bigint,
  "status" text default 'pending'::text not null,
  "target_audience" text default 'all'::text not null,
  "target_id" uuid,
  "reviewer_id" uuid,
  "reviewed_at" timestamp with time zone,
  "review_notes" text,
  "created_at" timestamp with time zone default now() not null
);
create table if not exists "public"."grade_appeals" (
  "id" uuid not null,
  "student_id" uuid not null,
  "student_name" text not null,
  "work_kind" text not null,
  "assignment_id" uuid,
  "quiz_attempt_id" uuid,
  "work_title" text not null,
  "original_score" numeric not null,
  "max_score" numeric not null,
  "reason" text not null,
  "status" text default 'submitted'::text not null,
  "adjusted_score" numeric,
  "decision_note" text,
  "decided_by" uuid,
  "decided_by_name" text,
  "decided_at" timestamp with time zone,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);
create table if not exists "public"."grade_assessments" (
  "id" uuid default gen_random_uuid() not null,
  "kind" text not null,
  "title" text not null,
  "cohort_id" uuid,
  "max_marks" numeric default 100 not null,
  "weight" numeric default 0 not null,
  "due_date" date,
  "published" boolean default false not null,
  "created_by" uuid,
  "created_at" timestamp with time zone default now() not null
);
create table if not exists "public"."grade_evaluation_settings" (
  "id" integer default 1 not null,
  "quizzes_weight" numeric default 30 not null,
  "assignments_weight" numeric default 30 not null,
  "exams_weight" numeric default 40 not null,
  "pass_mark" numeric default 50 not null,
  "distinction_mark" numeric default 80 not null,
  "published" boolean default false not null,
  "updated_at" timestamp with time zone default now() not null
);
create table if not exists "public"."group_messages" (
  "id" uuid default gen_random_uuid() not null,
  "group_id" uuid not null,
  "sender_id" uuid not null,
  "body" text default ''::text not null,
  "attachment_path" text,
  "attachment_type" text,
  "attachment_name" text,
  "duration_seconds" integer,
  "created_at" timestamp with time zone default now() not null,
  "reply_to" uuid,
  "edited_at" timestamp with time zone,
  "deleted_at" timestamp with time zone,
  "pinned_at" timestamp with time zone,
  "pinned_by" uuid,
  "starred" boolean default false,
  "scheduled_at" timestamp with time zone,
  "expires_at" timestamp with time zone
);
create table if not exists "public"."helpdesk_messages" (
  "id" uuid default gen_random_uuid() not null,
  "ticket_id" uuid not null,
  "author_id" uuid not null,
  "author_name" text not null,
  "author_role" text not null,
  "kind" text default 'reply'::text not null,
  "body" text not null,
  "created_at" timestamp with time zone default now() not null
);
create table if not exists "public"."helpdesk_tickets" (
  "id" uuid default gen_random_uuid() not null,
  "student_id" uuid not null,
  "student_name" text not null,
  "subject" text not null,
  "category" text not null,
  "status" text default 'open'::text not null,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);
create table if not exists "public"."knock_notification_events" (
  "id" uuid default gen_random_uuid() not null,
  "workflow_key" text not null,
  "recipient_uuid" uuid not null,
  "actor_uuid" uuid,
  "category" text,
  "status" text default 'queued'::text not null,
  "error" text,
  "created_at" timestamp with time zone default now() not null,
  "processed_at" timestamp with time zone
);
create table if not exists "public"."learning_memory" (
  "user_id" uuid default auth.uid() not null,
  "unit_id" uuid not null,
  "program_id" uuid not null,
  "lesson_title" text default ''::text not null,
  "bookmarked" boolean default false not null,
  "last_opened_at" timestamp with time zone,
  "resource_id" uuid,
  "position_seconds" double precision default 0 not null,
  "scroll_top" double precision default 0 not null,
  "updated_at" timestamp with time zone default now() not null
);
create table if not exists "public"."learning_units" (
  "id" uuid default gen_random_uuid() not null,
  "program_id" uuid not null,
  "cohort_id" uuid,
  "course_plan_id" uuid,
  "title" text not null,
  "summary" text default ''::text not null,
  "unit_type" text default 'topic'::text not null,
  "position" integer default 0 not null,
  "available_from" timestamp with time zone,
  "due_at" timestamp with time zone,
  "quiz_id" uuid,
  "classwork_assignment_id" uuid,
  "status" text default 'draft'::text not null,
  "created_by" uuid default auth.uid(),
  "submitted_at" timestamp with time zone,
  "reviewed_at" timestamp with time zone,
  "reviewed_by" uuid,
  "revision_note" text,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);
create table if not exists "public"."message_reactions" (
  "id" uuid default gen_random_uuid() not null,
  "message_id" uuid not null,
  "message_kind" text not null,
  "user_id" uuid not null,
  "emoji" text not null,
  "created_at" timestamp with time zone default now() not null
);
comment on table "public"."message_reactions" is 'Emoji reactions on 1:1 and group messages, addressed by message_kind + message_id.';
create table if not exists "public"."module_responsibilities" (
  "id" uuid default gen_random_uuid() not null,
  "program_module_id" uuid not null,
  "staff_id" uuid not null,
  "responsibility" text not null,
  "assigned_by" uuid default auth.uid() not null,
  "assigned_at" timestamp with time zone default now() not null,
  "active" boolean default true not null
);
comment on table "public"."module_responsibilities" is 'Role-based staff responsibility assignments for programme modules.';
create table if not exists "public"."newsletter_campaigns" (
  "id" uuid default gen_random_uuid() not null,
  "template_id" uuid,
  "subject" text not null,
  "body" text not null,
  "recipient_count" integer default 0 not null,
  "created_by" uuid,
  "created_at" timestamp with time zone default now() not null
);
create table if not exists "public"."newsletter_signup_limits" (
  "bucket" text not null,
  "hits" integer default 1 not null,
  "expires_at" timestamp with time zone not null
);
create table if not exists "public"."newsletter_subscribers" (
  "id" uuid default gen_random_uuid() not null,
  "email" text not null,
  "name" text default ''::text not null,
  "status" text default 'pending'::text not null,
  "consent_text" text not null,
  "consent_at" timestamp with time zone default now() not null,
  "confirmed_at" timestamp with time zone,
  "unsubscribed_at" timestamp with time zone,
  "confirmation_hash" text,
  "confirmation_expires_at" timestamp with time zone,
  "last_requested_at" timestamp with time zone default now() not null,
  "created_at" timestamp with time zone default now() not null
);
create table if not exists "public"."notification_outbox" (
  "id" uuid default gen_random_uuid() not null,
  "idempotency_key" text not null,
  "title" text not null,
  "body" text not null,
  "url" text default '/'::text not null,
  "audience" text default 'all'::text not null,
  "course_id" text,
  "created_by" uuid,
  "status" text default 'queued'::text not null,
  "provider_response" jsonb,
  "created_at" timestamp with time zone default now() not null,
  "recipient_id" uuid,
  "notification_id" uuid,
  "attempts" integer default 0 not null,
  "sent_at" timestamp with time zone,
  "last_attempt_at" timestamp with time zone,
  "next_attempt_at" timestamp with time zone,
  "last_error" text
);
create table if not exists "public"."notifications" (
  "id" uuid default gen_random_uuid() not null,
  "recipient_id" uuid not null,
  "kind" text not null,
  "title" text not null,
  "body" text default ''::text not null,
  "entity_type" text,
  "entity_id" uuid,
  "read_at" timestamp with time zone,
  "created_at" timestamp with time zone default now() not null,
  "user_id" uuid,
  "url" text default '/'::text,
  "read" boolean default false,
  "push_suppressed" boolean default false not null
);
create table if not exists "public"."onesignal_devices" (
  "id" uuid default gen_random_uuid() not null,
  "user_id" uuid not null,
  "external_id" text not null,
  "subscription_id" text,
  "role_tag" text,
  "opted_in" boolean default true not null,
  "user_agent" text,
  "updated_at" timestamp with time zone default now() not null
);
create table if not exists "public"."payment_channels" (
  "id" uuid default gen_random_uuid() not null,
  "provider" text not null,
  "label" text not null,
  "account_name" text not null,
  "account_number" text not null,
  "instructions" text default ''::text not null,
  "active" boolean default true not null,
  "sort" integer default 0 not null,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);
create table if not exists "public"."payment_submissions" (
  "id" uuid default gen_random_uuid() not null,
  "student_id" uuid not null,
  "channel_id" uuid,
  "provider" text not null,
  "amount" numeric(12,2) not null,
  "currency" text default 'USD'::text not null,
  "category" text default 'Tuition'::text not null,
  "payer_phone" text not null,
  "transaction_reference" text not null,
  "paid_on" date not null,
  "note" text default ''::text not null,
  "status" text default 'pending'::text not null,
  "reviewed_by" uuid,
  "reviewed_at" timestamp with time zone,
  "review_note" text default ''::text not null,
  "fee_transaction_id" uuid,
  "receipt_number" text,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null,
  "ledger_amount_usd" numeric(12,2),
  "proof_path" text
);
comment on column "public"."payment_submissions"."ledger_amount_usd" is 'USD amount actually posted to fee_transactions for this submission. Equal to amount for USD submissions; for LRD submissions it is the USD equivalent entered by the reviewer at confirmation time (the ledger is USD-only).';
create table if not exists "public"."permissions" (
  "key" text not null,
  "grp" text not null,
  "label" text not null,
  "description" text default ''::text not null,
  "sort" integer default 0 not null
);
create table if not exists "public"."policy_acceptances" (
  "id" uuid default gen_random_uuid() not null,
  "policy_id" uuid not null,
  "user_id" uuid not null,
  "accepted_version" integer default 1 not null,
  "accepted_at" timestamp with time zone default now() not null
);
create table if not exists "public"."portal_kv" (
  "key" text not null,
  "value" jsonb default '{}'::jsonb not null,
  "updated_by" uuid,
  "updated_at" timestamp with time zone default now() not null
);
create table if not exists "public"."profiles" (
  "id" uuid not null,
  "email" text,
  "full_name" text,
  "name" text,
  "phone" text default ''::text not null,
  "role" text default 'Student'::text not null,
  "status" text default 'Pending Approval'::text not null,
  "title" text,
  "joined_date" date,
  "program_ids" uuid[] default '{}'::uuid[] not null,
  "cohort_ids" uuid[] default '{}'::uuid[] not null,
  "note" text,
  "documents" text,
  "avatar_url" text,
  "bio" text,
  "address" text,
  "date_of_birth" date,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null,
  "education_level" text,
  "account_number" bigint generated always as identity not null,
  "applicant_type" text,
  "last_seen_at" timestamp with time zone,
  "is_online" boolean default false,
  "school_policy_accepted_at" timestamp with time zone
);
create table if not exists "public"."program_applications" (
  "id" uuid default gen_random_uuid() not null,
  "applicant_id" uuid not null,
  "program_id" uuid,
  "blog_post_id" uuid,
  "applicant_type" text not null,
  "status" text default 'pending'::text not null,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);
create table if not exists "public"."program_modules" (
  "id" uuid default gen_random_uuid() not null,
  "program_id" uuid not null,
  "name" text not null,
  "description" text default ''::text not null,
  "position" integer default 0 not null,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null,
  "summary" text,
  "weeks" integer default 1 not null
);
create table if not exists "public"."programs" (
  "id" uuid default gen_random_uuid() not null,
  "name" text not null,
  "code" text not null,
  "description" text default ''::text not null,
  "duration" text default ''::text not null,
  "fee" numeric default 0 not null,
  "image_url" text,
  "is_active" boolean default true not null,
  "completion_pass_mark" numeric default 50 not null,
  "required_attendance_percent" numeric default 75 not null,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null,
  "delivery_modes" text[] default ARRAY['online'::text, 'blended'::text],
  "study_plan" text,
  "category" text,
  "duration_weeks" integer,
  "tuition" numeric,
  "certification" text,
  "entry_requirements" text,
  "title" text,
  "course_number" bigint generated always as identity not null,
  "published" boolean default true not null,
  "delivery_mode" text,
  "is_published" boolean,
  "status" text,
  "self_paced_enabled" boolean default false not null,
  "self_paced_requires_approval" boolean default false not null,
  "self_paced_min_completion_percent" integer default 80 not null,
  "skill_category" text
);
create table if not exists "public"."push_dispatch_token" (
  "id" boolean default true not null,
  "token" text default encode(gen_random_bytes(32), 'hex'::text) not null,
  "created_at" timestamp with time zone default now() not null
);
create table if not exists "public"."push_subscriptions" (
  "id" uuid default gen_random_uuid() not null,
  "user_id" uuid not null,
  "endpoint" text not null,
  "p256dh" text not null,
  "auth" text not null,
  "user_agent" text,
  "enabled" boolean default true not null,
  "preferences" jsonb default '{}'::jsonb not null,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);
create table if not exists "public"."quiz_attempts" (
  "id" uuid default gen_random_uuid() not null,
  "quiz_id" uuid not null,
  "student_id" uuid not null,
  "attempt_no" integer not null,
  "status" text default 'in_progress'::text not null,
  "started_at" timestamp with time zone default now() not null,
  "deadline_at" timestamp with time zone,
  "submitted_at" timestamp with time zone,
  "question_order" uuid[] not null,
  "option_order" jsonb default '{}'::jsonb not null,
  "answers" jsonb default '{}'::jsonb not null,
  "results" jsonb,
  "score" numeric,
  "max_score" numeric,
  "percent" numeric,
  "passed" boolean
);
create table if not exists "public"."quiz_questions" (
  "id" uuid default gen_random_uuid() not null,
  "quiz_id" uuid not null,
  "position" integer default 0 not null,
  "type" text not null,
  "prompt" text not null,
  "options" jsonb default '[]'::jsonb not null,
  "correct" jsonb not null,
  "points" numeric default 1 not null,
  "explanation" text default ''::text not null
);
create table if not exists "public"."quizzes" (
  "id" uuid default gen_random_uuid() not null,
  "title" text not null,
  "description" text default ''::text not null,
  "program_id" uuid,
  "cohort_id" uuid,
  "created_by" uuid default auth.uid(),
  "status" text default 'draft'::text not null,
  "time_limit_minutes" integer,
  "max_attempts" integer default 1 not null,
  "pass_mark" numeric default 50 not null,
  "shuffle_questions" boolean default false not null,
  "shuffle_options" boolean default false not null,
  "show_answers" text default 'after_submit'::text not null,
  "opens_at" timestamp with time zone,
  "closes_at" timestamp with time zone,
  "question_count" integer default 0 not null,
  "total_points" numeric default 0 not null,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null,
  "learning_unit_id" uuid,
  "grade_weight" numeric default 0 not null,
  "is_entrance" boolean default false not null
);
create table if not exists "public"."reminder_items" (
  "id" uuid default gen_random_uuid() not null,
  "user_id" uuid not null,
  "item_key" text not null,
  "kind" text not null,
  "title" text not null,
  "body" text default ''::text not null,
  "url" text default '/'::text not null,
  "due_at" timestamp with time zone not null,
  "sent_at" timestamp with time zone,
  "created_at" timestamp with time zone default now() not null
);
create table if not exists "public"."reminder_settings" (
  "user_id" uuid not null,
  "enabled" boolean default false not null,
  "lessons" boolean default true not null,
  "fees" boolean default true not null,
  "announcements" boolean default true not null,
  "window_hours" integer default 24 not null,
  "updated_at" timestamp with time zone default now() not null,
  "assignments" boolean default true not null
);
comment on column "public"."reminder_settings"."assignments" is 'Whether the user wants assignment deadline notifications.';
create table if not exists "public"."role_permissions" (
  "role" text not null,
  "permission" text not null
);
create table if not exists "public"."roles" (
  "name" text not null,
  "label" text not null,
  "description" text default ''::text not null,
  "sort" integer default 0 not null,
  "is_system" boolean default true not null
);
create table if not exists "public"."school_policies" (
  "id" uuid default gen_random_uuid() not null,
  "slug" text not null,
  "title" text not null,
  "category" text default 'General'::text not null,
  "summary" text default ''::text not null,
  "body" text default ''::text not null,
  "version" integer default 1 not null,
  "effective_date" date default CURRENT_DATE not null,
  "is_published" boolean default true not null,
  "requires_acceptance" boolean default true not null,
  "sort" integer default 0 not null,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);
create table if not exists "public"."self_paced_activities" (
  "id" uuid default gen_random_uuid() not null,
  "week_id" uuid not null,
  "lesson_id" uuid,
  "type" text default 'exercise'::text not null,
  "title" text not null,
  "description" text,
  "max_score" numeric default 100 not null,
  "due_date" date,
  "created_at" timestamp with time zone default now() not null,
  "published" boolean default true not null
);
create table if not exists "public"."self_paced_lessons" (
  "id" uuid default gen_random_uuid() not null,
  "week_id" uuid not null,
  "title" text not null,
  "content" text,
  "resource_urls" jsonb default '[]'::jsonb not null,
  "order_index" integer default 0 not null,
  "created_at" timestamp with time zone default now() not null,
  "published" boolean default true not null
);
create table if not exists "public"."self_paced_participations" (
  "id" uuid default gen_random_uuid() not null,
  "user_id" uuid not null,
  "program_id" uuid not null,
  "cohort_id" uuid,
  "status" text default 'selected'::text not null,
  "requires_approval" boolean default false not null,
  "approved_by" uuid,
  "approved_at" timestamp with time zone,
  "selected_at" timestamp with time zone default now() not null,
  "created_at" timestamp with time zone default now() not null
);
create table if not exists "public"."self_paced_plans" (
  "id" uuid default gen_random_uuid() not null,
  "user_id" uuid not null,
  "program_id" uuid not null,
  "schedule" jsonb default '[]'::jsonb not null,
  "status" text default 'active'::text not null,
  "created_at" timestamp with time zone default now() not null
);
create table if not exists "public"."self_paced_progress" (
  "id" uuid default gen_random_uuid() not null,
  "user_id" uuid not null,
  "week_id" uuid not null,
  "status" text default 'not_started'::text not null,
  "completed_at" timestamp with time zone,
  "score" numeric,
  "created_at" timestamp with time zone default now() not null
);
create table if not exists "public"."self_paced_resources" (
  "id" uuid default gen_random_uuid() not null,
  "week_id" uuid not null,
  "title" text not null,
  "url" text not null,
  "resource_type" text default 'link'::text not null,
  "published" boolean default true not null,
  "created_by" uuid,
  "created_at" timestamp with time zone default now() not null
);
create table if not exists "public"."self_paced_submissions" (
  "id" uuid default gen_random_uuid() not null,
  "activity_id" uuid not null,
  "user_id" uuid not null,
  "content" text,
  "file_url" text,
  "score" numeric,
  "status" text default 'submitted'::text not null,
  "feedback" text,
  "graded_by" uuid,
  "graded_at" timestamp with time zone,
  "submitted_at" timestamp with time zone default now() not null
);
create table if not exists "public"."self_paced_weeks" (
  "id" uuid default gen_random_uuid() not null,
  "program_id" uuid not null,
  "week_number" integer not null,
  "title" text not null,
  "objectives" text,
  "available_from" date,
  "completion_requires_percent" integer default 80 not null,
  "created_by" uuid,
  "created_at" timestamp with time zone default now() not null,
  "published" boolean default true not null
);
create table if not exists "public"."staff_vacancies" (
  "id" uuid default gen_random_uuid() not null,
  "title" text not null,
  "dept" text default 'General'::text not null,
  "location" text default 'Monrovia'::text not null,
  "description" text default ''::text not null,
  "requirements" text default ''::text not null,
  "closing_date" date,
  "is_open" boolean default true not null,
  "image_url" text,
  "created_by" uuid,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);
create table if not exists "public"."student_learning_progress" (
  "id" uuid default gen_random_uuid() not null,
  "student_id" uuid not null,
  "cohort_id" uuid not null,
  "learning_unit_id" uuid not null,
  "status" text default 'not_started'::text not null,
  "progress_percent" numeric default 0 not null,
  "completed_at" timestamp with time zone,
  "updated_at" timestamp with time zone default now() not null
);
create table if not exists "public"."study_materials" (
  "id" uuid default gen_random_uuid() not null,
  "submission_id" uuid,
  "title" text not null,
  "description" text,
  "file_path" text,
  "file_url" text,
  "material_type" text default 'study_material'::text not null,
  "program_id" uuid,
  "cohort_id" uuid,
  "audience" text default 'all'::text not null,
  "published" boolean default false not null,
  "created_by" uuid,
  "created_at" timestamp with time zone default now() not null
);
create table if not exists "public"."study_plans" (
  "id" text not null,
  "name" text not null,
  "email" text not null,
  "phone" text not null,
  "program_id" text,
  "program_title" text not null,
  "mode" text not null,
  "duration" text,
  "registration_fee" text,
  "education_level" text,
  "intake" text,
  "notes" text,
  "status" text default 'new'::text not null,
  "created_at" timestamp with time zone default now() not null
);
create table if not exists "public"."submissions" (
  "id" uuid default gen_random_uuid() not null,
  "assignment_id" uuid not null,
  "student_id" uuid not null,
  "status" text default 'Submitted'::text not null,
  "content" text default ''::text not null,
  "response_text" text default ''::text not null,
  "attachment_path" text,
  "score" numeric,
  "feedback" text default ''::text not null,
  "started_at" timestamp with time zone,
  "submitted_at" timestamp with time zone,
  "is_late" boolean default false not null,
  "time_spent_seconds" integer,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null,
  "marks" numeric,
  "answer_text" text,
  "response" text,
  "graded_at" timestamp with time zone
);
create table if not exists "public"."support_pledges" (
  "id" text not null,
  "kind" text not null,
  "name" text not null,
  "email" text not null,
  "phone" text not null,
  "amount" numeric default 0 not null,
  "frequency" text,
  "method" text,
  "message" text,
  "status" text default 'new'::text not null,
  "created_at" timestamp with time zone default now() not null
);
create table if not exists "public"."system_settings" (
  "id" uuid default gen_random_uuid() not null,
  "academy_name" text default 'Africa of Hope School'::text not null,
  "motto" text default ''::text not null,
  "contact_email" text default ''::text not null,
  "contact_phone" text default ''::text not null,
  "address" text default ''::text not null,
  "accreditation_no" text default ''::text not null,
  "currency" text default 'USD'::text not null,
  "academic_year" text default ''::text not null,
  "semester" text default ''::text not null,
  "self_registration_open" boolean default true not null,
  "student_id_prefix" text default 'AOH'::text not null,
  "pass_mark" numeric default 50 not null,
  "min_attendance" numeric default 75 not null,
  "site_published" boolean default true not null,
  "marketing_banner" text default ''::text not null,
  "intake_status" text default 'open'::text not null,
  "featured_program_ids" uuid[] default '{}'::uuid[] not null,
  "website_settings" jsonb default '{}'::jsonb not null,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null,
  "assistant_enabled" boolean default true not null,
  "theme_settings" jsonb default jsonb_build_object('mode', 'light', 'primaryColor', '#065f46', 'accentColor', '#f59e0b', 'fontFamily', 'sans', 'iconStyle', 'outline', 'contentAlignment', 'left', 'borderRadius', 'rounded') not null
);
create table if not exists "public"."teacher_course_plans" (
  "id" uuid default gen_random_uuid() not null,
  "cohort_id" uuid not null,
  "teacher_id" uuid not null,
  "title" text not null,
  "term_label" text default ''::text not null,
  "overview" text default ''::text not null,
  "objectives" text[] default '{}'::text[] not null,
  "training_plan" text default ''::text not null,
  "plan" jsonb default '{}'::jsonb not null,
  "status" text default 'draft'::text not null,
  "submitted_at" timestamp with time zone,
  "approved_at" timestamp with time zone,
  "reviewed_at" timestamp with time zone,
  "reviewed_by" uuid,
  "revision_note" text,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);
create table if not exists "public"."term_report_comments" (
  "id" uuid default gen_random_uuid() not null,
  "cohort_id" text not null,
  "student_id" text not null,
  "term" text default 'Term 1'::text not null,
  "comment" text default ''::text not null,
  "updated_at" timestamp with time zone default now() not null
);
create table if not exists "public"."training_materials" (
  "id" uuid default gen_random_uuid() not null,
  "program_id" uuid not null,
  "cohort_id" uuid,
  "learning_unit_id" uuid,
  "title" text not null,
  "description" text default ''::text not null,
  "material_type" text default 'document'::text not null,
  "file_path" text,
  "external_url" text,
  "mime_type" text,
  "status" text default 'draft'::text not null,
  "created_by" uuid default auth.uid(),
  "submitted_at" timestamp with time zone,
  "approved_at" timestamp with time zone,
  "reviewed_at" timestamp with time zone,
  "reviewed_by" uuid,
  "revision_note" text,
  "created_at" timestamp with time zone default now() not null,
  "updated_at" timestamp with time zone default now() not null
);
create table if not exists "public"."transparency_reports" (
  "id" uuid default gen_random_uuid() not null,
  "title" text not null,
  "category" text not null,
  "reporting_year" integer not null,
  "summary" text default ''::text not null,
  "file_path" text not null,
  "published" boolean default false not null,
  "created_at" timestamp with time zone default now() not null
);
create table if not exists "public"."vacancy_applications" (
  "id" uuid default gen_random_uuid() not null,
  "vacancy_id" uuid,
  "role_title" text default ''::text not null,
  "name" text not null,
  "contact" text not null,
  "cover_note" text default ''::text not null,
  "cv_url" text,
  "status" text default 'new'::text not null,
  "created_at" timestamp with time zone default now() not null
);
create table if not exists "public"."website_enquiries" (
  "id" uuid default gen_random_uuid() not null,
  "name" text not null,
  "contact" text not null,
  "program" text default 'General enquiry'::text not null,
  "message" text not null,
  "source" text default 'whatsapp'::text not null,
  "created_at" timestamp with time zone default now() not null,
  "replied" boolean default false not null
);
create table if not exists "public"."welcome_email_templates" (
  "audience" text not null,
  "subject" text default ''::text not null,
  "body" text default ''::text not null,
  "updated_at" timestamp with time zone default now() not null
);
create table if not exists "public"."yearbook_entries" (
  "id" uuid default gen_random_uuid() not null,
  "graduate_name" text not null,
  "cohort" text default 'Class of 2026'::text not null,
  "programme" text default ''::text not null,
  "note" text default ''::text not null,
  "photo_url" text,
  "is_approved" boolean default false not null,
  "created_at" timestamp with time zone default now() not null
);

-- ---------------------------------------------------------------------------
-- Constraints
-- ---------------------------------------------------------------------------
alter table only "public"."alumni_businesses" add constraint "alumni_businesses_pkey" PRIMARY KEY (id);
alter table only "public"."announcements" add constraint "announcements_pkey" PRIMARY KEY (id);
alter table only "public"."app_integration_events" add constraint "app_integration_events_pkey" PRIMARY KEY (id);
alter table only "public"."app_integration_usage" add constraint "app_integration_usage_pkey" PRIMARY KEY (day, manifest_id, person);
alter table only "public"."app_integration_watch" add constraint "app_integration_watch_pkey" PRIMARY KEY (day, manifest_id, op, rule);
alter table only "public"."app_integrations" add constraint "app_integrations_pkey" PRIMARY KEY (id);
alter table only "public"."application_drafts" add constraint "application_drafts_pkey" PRIMARY KEY (id);
alter table only "public"."approval_events" add constraint "approval_events_pkey" PRIMARY KEY (id);
alter table only "public"."aptitude_control_settings" add constraint "aptitude_control_settings_pkey" PRIMARY KEY (id);
alter table only "public"."aptitude_preparations" add constraint "aptitude_preparations_pkey" PRIMARY KEY (id);
alter table only "public"."assignments" add constraint "assignments_pkey" PRIMARY KEY (id);
alter table only "public"."assistant_research_resources" add constraint "assistant_research_resources_pkey" PRIMARY KEY (id);
alter table only "public"."assistant_usage" add constraint "assistant_usage_pkey" PRIMARY KEY (bucket, window_start);
alter table only "public"."attendance" add constraint "attendance_pkey" PRIMARY KEY (id);
alter table only "public"."blog_posts" add constraint "blog_posts_pkey" PRIMARY KEY (id);
alter table only "public"."certificate_audit" add constraint "certificate_audit_pkey" PRIMARY KEY (id);
alter table only "public"."certificates" add constraint "certificates_pkey" PRIMARY KEY (id);
alter table only "public"."chat_drafts" add constraint "chat_drafts_pkey" PRIMARY KEY (id);
alter table only "public"."chat_group_invites" add constraint "chat_group_invites_pkey" PRIMARY KEY (id);
alter table only "public"."chat_group_join_requests" add constraint "chat_group_join_requests_pkey" PRIMARY KEY (id);
alter table only "public"."chat_group_members" add constraint "chat_group_members_pkey" PRIMARY KEY (group_id, user_id);
alter table only "public"."chat_groups" add constraint "chat_groups_pkey" PRIMARY KEY (id);
alter table only "public"."chat_poll_votes" add constraint "chat_poll_votes_pkey" PRIMARY KEY (id);
alter table only "public"."chat_polls" add constraint "chat_polls_pkey" PRIMARY KEY (id);
alter table only "public"."class_sessions" add constraint "class_sessions_pkey" PRIMARY KEY (id);
alter table only "public"."cohort_students" add constraint "cohort_students_pkey" PRIMARY KEY (cohort_id, student_id);
alter table only "public"."cohort_timetable_slots" add constraint "cohort_timetable_slots_pkey" PRIMARY KEY (id);
alter table only "public"."cohorts" add constraint "cohorts_pkey" PRIMARY KEY (id);
alter table only "public"."course_completions" add constraint "course_completions_pkey" PRIMARY KEY (id);
alter table only "public"."course_enrollments" add constraint "course_enrollments_pkey" PRIMARY KEY (id);
alter table only "public"."crash_course_attempts" add constraint "crash_course_attempts_pkey" PRIMARY KEY (id);
alter table only "public"."crash_course_enrollments" add constraint "crash_course_enrollments_pkey" PRIMARY KEY (id);
alter table only "public"."crash_course_lessons" add constraint "crash_course_lessons_pkey" PRIMARY KEY (id);
alter table only "public"."crash_courses" add constraint "crash_courses_pkey" PRIMARY KEY (id);
alter table only "public"."crash_programs" add constraint "crash_programs_pkey" PRIMARY KEY (id);
alter table only "public"."data_migrations" add constraint "data_migrations_pkey" PRIMARY KEY (id);
alter table only "public"."direct_messages" add constraint "direct_messages_pkey" PRIMARY KEY (id);
alter table only "public"."discussion_replies" add constraint "discussion_replies_pkey" PRIMARY KEY (id);
alter table only "public"."discussion_threads" add constraint "discussion_threads_pkey" PRIMARY KEY (id);
alter table only "public"."email_outbox" add constraint "email_outbox_pkey" PRIMARY KEY (id);
alter table only "public"."email_templates" add constraint "email_templates_pkey" PRIMARY KEY (id);
alter table only "public"."enrollment_arrangement_history" add constraint "enrollment_arrangement_history_pkey" PRIMARY KEY (id);
alter table only "public"."entrance_settings" add constraint "entrance_settings_pkey" PRIMARY KEY (id);
alter table only "public"."entrance_test_results" add constraint "entrance_test_results_pkey" PRIMARY KEY (id);
alter table only "public"."fee_transactions" add constraint "fee_transactions_pkey" PRIMARY KEY (id);
alter table only "public"."file_submissions" add constraint "file_submissions_pkey" PRIMARY KEY (id);
alter table only "public"."grade_appeals" add constraint "grade_appeals_pkey" PRIMARY KEY (id);
alter table only "public"."grade_assessments" add constraint "grade_assessments_pkey" PRIMARY KEY (id);
alter table only "public"."grade_evaluation_settings" add constraint "grade_evaluation_settings_pkey" PRIMARY KEY (id);
alter table only "public"."group_messages" add constraint "group_messages_pkey" PRIMARY KEY (id);
alter table only "public"."helpdesk_messages" add constraint "helpdesk_messages_pkey" PRIMARY KEY (id);
alter table only "public"."helpdesk_tickets" add constraint "helpdesk_tickets_pkey" PRIMARY KEY (id);
alter table only "public"."knock_notification_events" add constraint "knock_notification_events_pkey" PRIMARY KEY (id);
alter table only "public"."learning_memory" add constraint "learning_memory_pkey" PRIMARY KEY (user_id, unit_id);
alter table only "public"."learning_units" add constraint "learning_units_pkey" PRIMARY KEY (id);
alter table only "public"."message_reactions" add constraint "message_reactions_pkey" PRIMARY KEY (id);
alter table only "public"."module_responsibilities" add constraint "module_responsibilities_pkey" PRIMARY KEY (id);
alter table only "public"."newsletter_campaigns" add constraint "newsletter_campaigns_pkey" PRIMARY KEY (id);
alter table only "public"."newsletter_signup_limits" add constraint "newsletter_signup_limits_pkey" PRIMARY KEY (bucket);
alter table only "public"."newsletter_subscribers" add constraint "newsletter_subscribers_pkey" PRIMARY KEY (id);
alter table only "public"."notification_outbox" add constraint "notification_outbox_pkey" PRIMARY KEY (id);
alter table only "public"."notifications" add constraint "notifications_pkey" PRIMARY KEY (id);
alter table only "public"."onesignal_devices" add constraint "onesignal_devices_pkey" PRIMARY KEY (id);
alter table only "public"."payment_channels" add constraint "payment_channels_pkey" PRIMARY KEY (id);
alter table only "public"."payment_submissions" add constraint "payment_submissions_pkey" PRIMARY KEY (id);
alter table only "public"."permissions" add constraint "permissions_pkey" PRIMARY KEY (key);
alter table only "public"."policy_acceptances" add constraint "policy_acceptances_pkey" PRIMARY KEY (id);
alter table only "public"."portal_kv" add constraint "portal_kv_pkey" PRIMARY KEY (key);
alter table only "public"."profiles" add constraint "profiles_pkey" PRIMARY KEY (id);
alter table only "public"."program_applications" add constraint "program_applications_pkey" PRIMARY KEY (id);
alter table only "public"."program_modules" add constraint "program_modules_pkey" PRIMARY KEY (id);
alter table only "public"."programs" add constraint "programs_pkey" PRIMARY KEY (id);
alter table only "public"."push_dispatch_token" add constraint "push_dispatch_token_pkey" PRIMARY KEY (id);
alter table only "public"."push_subscriptions" add constraint "push_subscriptions_pkey" PRIMARY KEY (id);
alter table only "public"."quiz_attempts" add constraint "quiz_attempts_pkey" PRIMARY KEY (id);
alter table only "public"."quiz_questions" add constraint "quiz_questions_pkey" PRIMARY KEY (id);
alter table only "public"."quizzes" add constraint "quizzes_pkey" PRIMARY KEY (id);
alter table only "public"."reminder_items" add constraint "reminder_items_pkey" PRIMARY KEY (id);
alter table only "public"."reminder_settings" add constraint "reminder_settings_pkey" PRIMARY KEY (user_id);
alter table only "public"."role_permissions" add constraint "role_permissions_pkey" PRIMARY KEY (role, permission);
alter table only "public"."roles" add constraint "roles_pkey" PRIMARY KEY (name);
alter table only "public"."school_policies" add constraint "school_policies_pkey" PRIMARY KEY (id);
alter table only "public"."self_paced_activities" add constraint "self_paced_activities_pkey" PRIMARY KEY (id);
alter table only "public"."self_paced_lessons" add constraint "self_paced_lessons_pkey" PRIMARY KEY (id);
alter table only "public"."self_paced_participations" add constraint "self_paced_participations_pkey" PRIMARY KEY (id);
alter table only "public"."self_paced_plans" add constraint "self_paced_plans_pkey" PRIMARY KEY (id);
alter table only "public"."self_paced_progress" add constraint "self_paced_progress_pkey" PRIMARY KEY (id);
alter table only "public"."self_paced_resources" add constraint "self_paced_resources_pkey" PRIMARY KEY (id);
alter table only "public"."self_paced_submissions" add constraint "self_paced_submissions_pkey" PRIMARY KEY (id);
alter table only "public"."self_paced_weeks" add constraint "self_paced_weeks_pkey" PRIMARY KEY (id);
alter table only "public"."staff_vacancies" add constraint "staff_vacancies_pkey" PRIMARY KEY (id);
alter table only "public"."student_learning_progress" add constraint "student_learning_progress_pkey" PRIMARY KEY (id);
alter table only "public"."study_materials" add constraint "study_materials_pkey" PRIMARY KEY (id);
alter table only "public"."study_plans" add constraint "study_plans_pkey" PRIMARY KEY (id);
alter table only "public"."submissions" add constraint "submissions_pkey" PRIMARY KEY (id);
alter table only "public"."support_pledges" add constraint "support_pledges_pkey" PRIMARY KEY (id);
alter table only "public"."system_settings" add constraint "system_settings_pkey" PRIMARY KEY (id);
alter table only "public"."teacher_course_plans" add constraint "teacher_course_plans_pkey" PRIMARY KEY (id);
alter table only "public"."term_report_comments" add constraint "term_report_comments_pkey" PRIMARY KEY (id);
alter table only "public"."training_materials" add constraint "training_materials_pkey" PRIMARY KEY (id);
alter table only "public"."transparency_reports" add constraint "transparency_reports_pkey" PRIMARY KEY (id);
alter table only "public"."vacancy_applications" add constraint "vacancy_applications_pkey" PRIMARY KEY (id);
alter table only "public"."website_enquiries" add constraint "website_enquiries_pkey" PRIMARY KEY (id);
alter table only "public"."welcome_email_templates" add constraint "welcome_email_templates_pkey" PRIMARY KEY (audience);
alter table only "public"."yearbook_entries" add constraint "yearbook_entries_pkey" PRIMARY KEY (id);
alter table only "public"."app_integrations" add constraint "app_integrations_unique" UNIQUE (app_slug, manifest_id);
alter table only "public"."attendance" add constraint "attendance_cohort_id_student_id_attendance_date_key" UNIQUE (cohort_id, student_id, attendance_date);
alter table only "public"."blog_posts" add constraint "blog_posts_slug_key" UNIQUE (slug);
alter table only "public"."certificates" add constraint "certificates_certificate_number_key" UNIQUE (certificate_number);
alter table only "public"."chat_drafts" add constraint "chat_drafts_user_id_thread_key_key" UNIQUE (user_id, thread_key);
alter table only "public"."chat_group_invites" add constraint "chat_group_invites_token_key" UNIQUE (token);
alter table only "public"."chat_group_join_requests" add constraint "chat_group_join_requests_group_id_user_id_key" UNIQUE (group_id, user_id);
alter table only "public"."chat_poll_votes" add constraint "chat_poll_votes_poll_id_user_id_option_index_key" UNIQUE (poll_id, user_id, option_index);
alter table only "public"."cohorts" add constraint "cohorts_code_key" UNIQUE (code);
alter table only "public"."course_completions" add constraint "course_completions_student_id_cohort_id_key" UNIQUE (student_id, cohort_id);
alter table only "public"."course_enrollments" add constraint "course_enrollments_cohort_id_student_id_key" UNIQUE (cohort_id, student_id);
alter table only "public"."crash_course_enrollments" add constraint "crash_course_enrollments_course_id_student_id_key" UNIQUE (course_id, student_id);
alter table only "public"."crash_programs" add constraint "crash_programs_slug_key" UNIQUE (slug);
alter table only "public"."email_outbox" add constraint "email_outbox_dedupe_key_key" UNIQUE (dedupe_key);
alter table only "public"."message_reactions" add constraint "message_reactions_message_id_message_kind_user_id_emoji_key" UNIQUE (message_id, message_kind, user_id, emoji);
alter table only "public"."module_responsibilities" add constraint "module_responsibilities_program_module_id_staff_id_responsi_key" UNIQUE (program_module_id, staff_id, responsibility);
alter table only "public"."newsletter_subscribers" add constraint "newsletter_subscribers_email_key" UNIQUE (email);
alter table only "public"."notification_outbox" add constraint "notification_outbox_idempotency_key_key" UNIQUE (idempotency_key);
alter table only "public"."onesignal_devices" add constraint "onesignal_devices_user_id_subscription_id_key" UNIQUE (user_id, subscription_id);
alter table only "public"."payment_submissions" add constraint "payment_submissions_receipt_number_key" UNIQUE (receipt_number);
alter table only "public"."policy_acceptances" add constraint "policy_acceptances_policy_id_user_id_key" UNIQUE (policy_id, user_id);
alter table only "public"."programs" add constraint "programs_code_key" UNIQUE (code);
alter table only "public"."push_subscriptions" add constraint "push_subscriptions_endpoint_key" UNIQUE (endpoint);
alter table only "public"."quiz_attempts" add constraint "quiz_attempts_quiz_id_student_id_attempt_no_key" UNIQUE (quiz_id, student_id, attempt_no);
alter table only "public"."reminder_items" add constraint "reminder_items_user_id_item_key_key" UNIQUE (user_id, item_key);
alter table only "public"."school_policies" add constraint "school_policies_slug_key" UNIQUE (slug);
alter table only "public"."self_paced_participations" add constraint "self_paced_participations_user_id_program_id_key" UNIQUE (user_id, program_id);
alter table only "public"."self_paced_plans" add constraint "self_paced_plans_user_id_program_id_key" UNIQUE (user_id, program_id);
alter table only "public"."self_paced_progress" add constraint "self_paced_progress_user_id_week_id_key" UNIQUE (user_id, week_id);
alter table only "public"."self_paced_submissions" add constraint "self_paced_submissions_activity_id_user_id_key" UNIQUE (activity_id, user_id);
alter table only "public"."self_paced_weeks" add constraint "self_paced_weeks_program_id_week_number_key" UNIQUE (program_id, week_number);
alter table only "public"."student_learning_progress" add constraint "student_learning_progress_student_id_cohort_id_learning_uni_key" UNIQUE (student_id, cohort_id, learning_unit_id);
alter table only "public"."submissions" add constraint "submissions_assignment_id_student_id_key" UNIQUE (assignment_id, student_id);
alter table only "public"."term_report_comments" add constraint "term_report_comments_cohort_id_student_id_term_key" UNIQUE (cohort_id, student_id, term);
alter table only "public"."transparency_reports" add constraint "transparency_reports_file_path_key" UNIQUE (file_path);
alter table only "public"."announcements" add constraint "announcements_audience_check" CHECK (audience = ANY (ARRAY['public'::text, 'all'::text, 'students'::text, 'teachers'::text]));
alter table only "public"."announcements" add constraint "announcements_schedule_window_check" CHECK (expires_at IS NULL OR scheduled_at IS NULL OR expires_at > scheduled_at);
alter table only "public"."announcements" add constraint "announcements_status_check" CHECK (status = ANY (ARRAY['draft'::text, 'scheduled'::text, 'published'::text, 'archived'::text]));
alter table only "public"."application_drafts" add constraint "application_drafts_email_check" CHECK (email <> ''::text);
alter table only "public"."approval_events" add constraint "approval_events_action_check" CHECK (action = ANY (ARRAY['draft'::text, 'submitted'::text, 'approved'::text, 'rejected'::text, 'revision_requested'::text, 'cancelled'::text, 'completed'::text, 'active'::text, 'withdrawn'::text]));
alter table only "public"."approval_events" add constraint "approval_events_entity_type_check" CHECK (entity_type = ANY (ARRAY['enrollment'::text, 'course_plan'::text, 'class_session'::text, 'learning_unit'::text, 'training_material'::text]));
alter table only "public"."aptitude_control_settings" add constraint "aptitude_control_settings_id_check" CHECK (id = 1);
alter table only "public"."aptitude_control_settings" add constraint "aptitude_control_settings_max_attempts_check" CHECK (max_attempts >= 1 AND max_attempts <= 20);
alter table only "public"."aptitude_control_settings" add constraint "aptitude_control_settings_pass_mark_check" CHECK (pass_mark >= 0::numeric AND pass_mark <= 100::numeric);
alter table only "public"."aptitude_control_settings" add constraint "aptitude_control_settings_time_minutes_check" CHECK (time_minutes >= 1 AND time_minutes <= 180);
alter table only "public"."aptitude_preparations" add constraint "aptitude_preparations_title_check" CHECK (char_length(title) >= 1 AND char_length(title) <= 200);
alter table only "public"."assignments" add constraint "assignments_grade_weight_check" CHECK (grade_weight >= 0::numeric AND grade_weight <= 100::numeric);
alter table only "public"."assignments" add constraint "assignments_time_limit_minutes_check" CHECK (time_limit_minutes IS NULL OR time_limit_minutes >= 1 AND time_limit_minutes <= 1440);
alter table only "public"."assistant_research_resources" add constraint "assistant_research_resources_content_check" CHECK (length(TRIM(BOTH FROM content)) >= 1 AND length(TRIM(BOTH FROM content)) <= 50000);
alter table only "public"."assistant_research_resources" add constraint "assistant_research_resources_title_check" CHECK (length(TRIM(BOTH FROM title)) >= 1 AND length(TRIM(BOTH FROM title)) <= 180);
alter table only "public"."assistant_research_resources" add constraint "assistant_research_resources_visibility_check" CHECK (visibility = ANY (ARRAY['private'::text, 'staff'::text]));
alter table only "public"."attendance" add constraint "attendance_status_check" CHECK (status = ANY (ARRAY['Present'::text, 'Absent'::text, 'Late'::text]));
alter table only "public"."blog_posts" add constraint "blog_posts_excerpt_check" CHECK (length(excerpt) <= 400);
alter table only "public"."blog_posts" add constraint "blog_posts_published_requires_date" CHECK ((status <> ALL (ARRAY['scheduled'::text, 'published'::text])) OR published_at IS NOT NULL);
alter table only "public"."blog_posts" add constraint "blog_posts_slug_check" CHECK (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'::text AND length(slug) <= 120);
alter table only "public"."blog_posts" add constraint "blog_posts_status_check" CHECK (status = ANY (ARRAY['draft'::text, 'scheduled'::text, 'published'::text, 'archived'::text]));
alter table only "public"."blog_posts" add constraint "blog_posts_title_check" CHECK (length(btrim(title)) >= 1 AND length(btrim(title)) <= 200);
alter table only "public"."certificate_audit" add constraint "certificate_audit_action_check" CHECK (action = ANY (ARRAY['issued'::text, 'revoked'::text]));
alter table only "public"."certificates" add constraint "certificates_status_check" CHECK (status = ANY (ARRAY['Valid'::text, 'Revoked'::text]));
alter table only "public"."certificates" add constraint "certificates_type_check" CHECK (certificate_type = ANY (ARRAY['Certificate of Completion'::text, 'Certificate of Achievement'::text, 'Certificate of Participation'::text, 'Professional Training Certificate'::text, 'Certificate of Excellence'::text, 'Diploma Certificate'::text]));
alter table only "public"."chat_group_members" add constraint "chat_group_members_member_role_check" CHECK (member_role = ANY (ARRAY['owner'::text, 'admin'::text, 'member'::text]));
alter table only "public"."chat_groups" add constraint "chat_groups_name_check" CHECK (char_length(btrim(name)) >= 1 AND char_length(btrim(name)) <= 80);
alter table only "public"."class_sessions" add constraint "class_sessions_status_check" CHECK (status = ANY (ARRAY['draft'::text, 'submitted'::text, 'approved'::text, 'rejected'::text, 'revision_requested'::text, 'cancelled'::text, 'completed'::text]));
alter table only "public"."class_sessions" add constraint "class_sessions_title_check" CHECK (length(btrim(title)) >= 1 AND length(btrim(title)) <= 250);
alter table only "public"."class_sessions" add constraint "class_sessions_window_check" CHECK (ends_at > starts_at);
alter table only "public"."cohort_timetable_slots" add constraint "cohort_timetable_slots_day_of_week_check" CHECK (day_of_week >= 0 AND day_of_week <= 6);
alter table only "public"."cohort_timetable_slots" add constraint "cohort_timetable_slots_title_check" CHECK (char_length(title) >= 1 AND char_length(title) <= 200);
alter table only "public"."cohorts" add constraint "cohorts_capacity_check" CHECK (capacity IS NULL OR capacity > 0);
alter table only "public"."cohorts" add constraint "cohorts_enrollment_status_check" CHECK (enrollment_status = ANY (ARRAY['draft'::text, 'open'::text, 'closed'::text, 'cancelled'::text]));
alter table only "public"."cohorts" add constraint "cohorts_enrollment_window_check" CHECK (enrollment_closes_at IS NULL OR enrollment_opens_at IS NULL OR enrollment_closes_at > enrollment_opens_at);
alter table only "public"."course_completions" add constraint "course_completions_attendance_percent_check" CHECK (attendance_percent IS NULL OR attendance_percent >= 0::numeric AND attendance_percent <= 100::numeric);
alter table only "public"."course_completions" add constraint "course_completions_course_grade_check" CHECK (course_grade IS NULL OR course_grade >= 0::numeric AND course_grade <= 100::numeric);
alter table only "public"."course_completions" add constraint "course_completions_status_check" CHECK (status = ANY (ARRAY['in_progress'::text, 'eligible'::text, 'completed'::text, 'not_completed'::text]));
alter table only "public"."course_enrollments" add constraint "course_enrollments_learning_arrangement_check" CHECK (learning_arrangement = ANY (ARRAY['self_paced'::text, 'blended'::text, 'full_onsite'::text]));
alter table only "public"."course_enrollments" add constraint "course_enrollments_progress_percent_check" CHECK (progress_percent >= 0::numeric AND progress_percent <= 100::numeric);
alter table only "public"."course_enrollments" add constraint "course_enrollments_status_check" CHECK (status = ANY (ARRAY['draft'::text, 'submitted'::text, 'approved'::text, 'rejected'::text, 'revision_requested'::text, 'cancelled'::text, 'active'::text, 'completed'::text, 'withdrawn'::text]));
alter table only "public"."crash_course_attempts" add constraint "crash_course_attempts_status_check" CHECK (status = ANY (ARRAY['in_progress'::text, 'submitted'::text, 'passed'::text, 'failed'::text]));
alter table only "public"."crash_course_enrollments" add constraint "crash_course_enrollments_progress_percent_check" CHECK (progress_percent >= 0 AND progress_percent <= 100);
alter table only "public"."crash_course_lessons" add constraint "crash_course_lessons_lesson_type_check" CHECK (lesson_type = ANY (ARRAY['video'::text, 'lesson'::text, 'live_class'::text, 'assessment'::text]));
alter table only "public"."crash_courses" add constraint "crash_courses_duration_days_check" CHECK (duration_days > 0);
alter table only "public"."crash_courses" add constraint "crash_courses_status_check" CHECK (status = ANY (ARRAY['draft'::text, 'live'::text, 'archived'::text]));
alter table only "public"."crash_programs" add constraint "crash_programs_duration_weeks_check" CHECK (duration_weeks > 0);
alter table only "public"."direct_messages" add constraint "direct_messages_attachment_type_check" CHECK (attachment_type IS NULL OR (attachment_type = ANY (ARRAY['image'::text, 'file'::text, 'voice'::text])));
alter table only "public"."direct_messages" add constraint "direct_messages_body_check" CHECK (char_length(body) <= 2000);
alter table only "public"."direct_messages" add constraint "direct_messages_no_self" CHECK (sender_id <> receiver_id);
alter table only "public"."discussion_replies" add constraint "discussion_replies_body_check" CHECK (length(btrim(body)) >= 1 AND length(btrim(body)) <= 10000);
alter table only "public"."discussion_threads" add constraint "discussion_threads_body_check" CHECK (length(btrim(body)) >= 1 AND length(btrim(body)) <= 10000);
alter table only "public"."discussion_threads" add constraint "discussion_threads_title_check" CHECK (length(btrim(title)) >= 1 AND length(btrim(title)) <= 240);
alter table only "public"."email_outbox" add constraint "email_outbox_status_check" CHECK (status = ANY (ARRAY['queued'::text, 'sending'::text, 'sent'::text, 'failed'::text, 'skipped'::text]));
alter table only "public"."email_templates" add constraint "email_templates_body_check" CHECK (length(body) >= 1 AND length(body) <= 20000);
alter table only "public"."email_templates" add constraint "email_templates_name_check" CHECK (length(name) >= 1 AND length(name) <= 120);
alter table only "public"."email_templates" add constraint "email_templates_subject_check" CHECK (length(subject) >= 1 AND length(subject) <= 200 AND subject !~ '[
]'::text);
alter table only "public"."enrollment_arrangement_history" add constraint "enrollment_arrangement_history_next_arrangement_check" CHECK (next_arrangement = ANY (ARRAY['self_paced'::text, 'blended'::text, 'full_onsite'::text]));
alter table only "public"."entrance_settings" add constraint "entrance_settings_id_check" CHECK (id = 1);
alter table only "public"."entrance_settings" add constraint "entrance_settings_pass_mark_check" CHECK (pass_mark >= 0::numeric AND pass_mark <= 100::numeric);
alter table only "public"."entrance_test_results" add constraint "entrance_test_results_name_check" CHECK (length(name) >= 1 AND length(name) <= 200);
alter table only "public"."entrance_test_results" add constraint "entrance_test_results_percent_check" CHECK (percent >= 0::numeric AND percent <= 100::numeric);
alter table only "public"."fee_transactions" add constraint "fee_transactions_amount_check" CHECK (amount > 0::numeric);
alter table only "public"."grade_appeals" add constraint "grade_appeals_adjusted_score_check" CHECK (adjusted_score IS NULL OR adjusted_score >= 0::numeric);
alter table only "public"."grade_appeals" add constraint "grade_appeals_decision_note_check" CHECK (decision_note IS NULL OR length(btrim(decision_note)) >= 1 AND length(btrim(decision_note)) <= 2000);
alter table only "public"."grade_appeals" add constraint "grade_appeals_max_score_check" CHECK (max_score > 0::numeric);
alter table only "public"."grade_appeals" add constraint "grade_appeals_one_work" CHECK (work_kind = 'assignment'::text AND assignment_id IS NOT NULL AND quiz_attempt_id IS NULL OR work_kind = 'quiz'::text AND quiz_attempt_id IS NOT NULL AND assignment_id IS NULL);
alter table only "public"."grade_appeals" add constraint "grade_appeals_original_score_check" CHECK (original_score >= 0::numeric);
alter table only "public"."grade_appeals" add constraint "grade_appeals_reason_check" CHECK (length(btrim(reason)) >= 1 AND length(btrim(reason)) <= 4000);
alter table only "public"."grade_appeals" add constraint "grade_appeals_status_check" CHECK (status = ANY (ARRAY['submitted'::text, 'adjusted'::text, 'upheld'::text]));
alter table only "public"."grade_appeals" add constraint "grade_appeals_work_kind_check" CHECK (work_kind = ANY (ARRAY['assignment'::text, 'quiz'::text]));
alter table only "public"."grade_assessments" add constraint "grade_assessments_kind_check" CHECK (kind = ANY (ARRAY['quiz'::text, 'assignment'::text, 'exam'::text]));
alter table only "public"."grade_assessments" add constraint "grade_assessments_max_marks_check" CHECK (max_marks > 0::numeric);
alter table only "public"."grade_assessments" add constraint "grade_assessments_title_check" CHECK (char_length(title) >= 1 AND char_length(title) <= 200);
alter table only "public"."grade_assessments" add constraint "grade_assessments_weight_check" CHECK (weight >= 0::numeric AND weight <= 100::numeric);
alter table only "public"."grade_evaluation_settings" add constraint "grade_evaluation_settings_assignments_weight_check" CHECK (assignments_weight >= 0::numeric AND assignments_weight <= 100::numeric);
alter table only "public"."grade_evaluation_settings" add constraint "grade_evaluation_settings_distinction_mark_check" CHECK (distinction_mark >= 0::numeric AND distinction_mark <= 100::numeric);
alter table only "public"."grade_evaluation_settings" add constraint "grade_evaluation_settings_exams_weight_check" CHECK (exams_weight >= 0::numeric AND exams_weight <= 100::numeric);
alter table only "public"."grade_evaluation_settings" add constraint "grade_evaluation_settings_id_check" CHECK (id = 1);
alter table only "public"."grade_evaluation_settings" add constraint "grade_evaluation_settings_pass_mark_check" CHECK (pass_mark >= 0::numeric AND pass_mark <= 100::numeric);
alter table only "public"."grade_evaluation_settings" add constraint "grade_evaluation_settings_quizzes_weight_check" CHECK (quizzes_weight >= 0::numeric AND quizzes_weight <= 100::numeric);
alter table only "public"."group_messages" add constraint "group_messages_attachment_type_check" CHECK (attachment_type IS NULL OR (attachment_type = ANY (ARRAY['image'::text, 'file'::text, 'voice'::text])));
alter table only "public"."group_messages" add constraint "group_messages_body_check" CHECK (char_length(body) <= 2000);
alter table only "public"."helpdesk_messages" add constraint "helpdesk_messages_body_check" CHECK (length(btrim(body)) >= 1 AND length(btrim(body)) <= 10000);
alter table only "public"."helpdesk_messages" add constraint "helpdesk_messages_kind_check" CHECK (kind = ANY (ARRAY['reply'::text, 'closed'::text, 'reopened'::text]));
alter table only "public"."helpdesk_tickets" add constraint "helpdesk_tickets_category_check" CHECK (category = ANY (ARRAY['Study'::text, 'Fees'::text, 'Technology'::text, 'Other'::text]));
alter table only "public"."helpdesk_tickets" add constraint "helpdesk_tickets_status_check" CHECK (status = ANY (ARRAY['open'::text, 'closed'::text]));
alter table only "public"."helpdesk_tickets" add constraint "helpdesk_tickets_subject_check" CHECK (length(btrim(subject)) >= 1 AND length(btrim(subject)) <= 200);
alter table only "public"."learning_memory" add constraint "learning_memory_lesson_title_check" CHECK (length(lesson_title) <= 250);
alter table only "public"."learning_memory" add constraint "learning_memory_position_seconds_check" CHECK (position_seconds >= 0::double precision AND position_seconds <= 864000::double precision);
alter table only "public"."learning_memory" add constraint "learning_memory_scroll_top_check" CHECK (scroll_top >= 0::double precision AND scroll_top <= 10000000::double precision);
alter table only "public"."learning_units" add constraint "learning_units_position_check" CHECK ("position" >= 0);
alter table only "public"."learning_units" add constraint "learning_units_status_check" CHECK (status = ANY (ARRAY['draft'::text, 'submitted'::text, 'approved'::text, 'rejected'::text, 'revision_requested'::text]));
alter table only "public"."learning_units" add constraint "learning_units_title_check" CHECK (length(btrim(title)) >= 1 AND length(btrim(title)) <= 250);
alter table only "public"."learning_units" add constraint "learning_units_unit_type_check" CHECK (unit_type = ANY (ARRAY['chapter'::text, 'module'::text, 'topic'::text]));
alter table only "public"."learning_units" add constraint "learning_units_window_check" CHECK (due_at IS NULL OR available_from IS NULL OR due_at > available_from);
alter table only "public"."message_reactions" add constraint "message_reactions_message_kind_check" CHECK (message_kind = ANY (ARRAY['dm'::text, 'group'::text]));
alter table only "public"."module_responsibilities" add constraint "module_responsibilities_responsibility_check" CHECK (responsibility = ANY (ARRAY['owner'::text, 'teacher'::text, 'reviewer'::text, 'assistant'::text]));
alter table only "public"."newsletter_subscribers" add constraint "newsletter_subscribers_email_check" CHECK (length(email) <= 254);
alter table only "public"."newsletter_subscribers" add constraint "newsletter_subscribers_name_check" CHECK (length(name) <= 120);
alter table only "public"."newsletter_subscribers" add constraint "newsletter_subscribers_status_check" CHECK (status = ANY (ARRAY['pending'::text, 'active'::text, 'unsubscribed'::text]));
alter table only "public"."notification_outbox" add constraint "notification_outbox_status_check" CHECK (status = ANY (ARRAY['queued'::text, 'sending'::text, 'sent'::text, 'failed'::text, 'skipped'::text]));
alter table only "public"."notifications" add constraint "notifications_title_check" CHECK (length(btrim(title)) >= 1 AND length(btrim(title)) <= 250);
alter table only "public"."payment_channels" add constraint "payment_channels_provider_check" CHECK (provider = ANY (ARRAY['mtn_momo'::text, 'orange_money'::text]));
alter table only "public"."payment_submissions" add constraint "payment_submissions_amount_check" CHECK (amount > 0::numeric);
alter table only "public"."payment_submissions" add constraint "payment_submissions_currency_check" CHECK (currency = ANY (ARRAY['USD'::text, 'LRD'::text]));
alter table only "public"."payment_submissions" add constraint "payment_submissions_ledger_amount_positive" CHECK (ledger_amount_usd IS NULL OR ledger_amount_usd > 0::numeric);
alter table only "public"."payment_submissions" add constraint "payment_submissions_provider_check" CHECK (provider = ANY (ARRAY['mtn_momo'::text, 'orange_money'::text]));
alter table only "public"."payment_submissions" add constraint "payment_submissions_status_check" CHECK (status = ANY (ARRAY['pending'::text, 'confirmed'::text, 'rejected'::text]));
alter table only "public"."payment_submissions" add constraint "payment_submissions_transaction_reference_check" CHECK (transaction_reference = upper(btrim(transaction_reference)) AND length(transaction_reference) >= 4 AND length(transaction_reference) <= 64);
alter table only "public"."profiles" add constraint "profiles_applicant_type_check" CHECK (applicant_type = ANY (ARRAY['Volunteer'::text, 'Staff'::text, 'Student'::text]));
alter table only "public"."program_applications" add constraint "program_applications_applicant_type_check" CHECK (applicant_type = ANY (ARRAY['Volunteer'::text, 'Staff'::text, 'Student'::text]));
alter table only "public"."program_applications" add constraint "program_applications_status_check" CHECK (status = ANY (ARRAY['pending'::text, 'approved'::text, 'rejected'::text]));
alter table only "public"."programs" add constraint "programs_completion_pass_mark_check" CHECK (completion_pass_mark >= 0::numeric AND completion_pass_mark <= 100::numeric);
alter table only "public"."programs" add constraint "programs_required_attendance_check" CHECK (required_attendance_percent >= 0::numeric AND required_attendance_percent <= 100::numeric);
alter table only "public"."push_dispatch_token" add constraint "push_dispatch_token_id_check" CHECK (id);
alter table only "public"."quiz_attempts" add constraint "quiz_attempts_status_check" CHECK (status = ANY (ARRAY['in_progress'::text, 'submitted'::text, 'auto_submitted'::text]));
alter table only "public"."quiz_questions" add constraint "quiz_questions_points_check" CHECK (points > 0::numeric AND points <= 100::numeric);
alter table only "public"."quiz_questions" add constraint "quiz_questions_prompt_check" CHECK (length(prompt) >= 1 AND length(prompt) <= 4000);
alter table only "public"."quiz_questions" add constraint "quiz_questions_type_check" CHECK (type = ANY (ARRAY['single'::text, 'multi'::text, 'true_false'::text, 'short'::text]));
alter table only "public"."quizzes" add constraint "quizzes_grade_weight_check" CHECK (grade_weight >= 0::numeric AND grade_weight <= 100::numeric);
alter table only "public"."quizzes" add constraint "quizzes_max_attempts_check" CHECK (max_attempts >= 1 AND max_attempts <= 20);
alter table only "public"."quizzes" add constraint "quizzes_pass_mark_check" CHECK (pass_mark >= 0::numeric AND pass_mark <= 100::numeric);
alter table only "public"."quizzes" add constraint "quizzes_scope" CHECK (program_id IS NOT NULL OR cohort_id IS NOT NULL);
alter table only "public"."quizzes" add constraint "quizzes_show_answers_check" CHECK (show_answers = ANY (ARRAY['after_submit'::text, 'after_close'::text, 'never'::text]));
alter table only "public"."quizzes" add constraint "quizzes_status_check" CHECK (status = ANY (ARRAY['draft'::text, 'published'::text, 'archived'::text]));
alter table only "public"."quizzes" add constraint "quizzes_time_limit_minutes_check" CHECK (time_limit_minutes >= 1 AND time_limit_minutes <= 600);
alter table only "public"."quizzes" add constraint "quizzes_title_check" CHECK (length(title) >= 1 AND length(title) <= 200);
alter table only "public"."quizzes" add constraint "quizzes_window" CHECK (closes_at IS NULL OR opens_at IS NULL OR closes_at > opens_at);
alter table only "public"."reminder_items" add constraint "reminder_items_kind_check" CHECK (kind = ANY (ARRAY['lesson'::text, 'assignment'::text, 'fee'::text, 'announcement'::text]));
alter table only "public"."reminder_settings" add constraint "reminder_settings_window_hours_check" CHECK (window_hours >= 1 AND window_hours <= 168);
alter table only "public"."student_learning_progress" add constraint "student_learning_progress_progress_percent_check" CHECK (progress_percent >= 0::numeric AND progress_percent <= 100::numeric);
alter table only "public"."student_learning_progress" add constraint "student_learning_progress_status_check" CHECK (status = ANY (ARRAY['not_started'::text, 'in_progress'::text, 'completed'::text]));
alter table only "public"."study_plans" add constraint "study_plans_mode_check" CHECK (mode = ANY (ARRAY['online'::text, 'blended'::text, 'onsite'::text]));
alter table only "public"."study_plans" add constraint "study_plans_status_check" CHECK (status = ANY (ARRAY['new'::text, 'contacted'::text, 'closed'::text, 'archived'::text]));
alter table only "public"."submissions" add constraint "submissions_response_text_check" CHECK (length(response_text) <= 20000);
alter table only "public"."submissions" add constraint "submissions_status_check" CHECK (status = ANY (ARRAY['In Progress'::text, 'Submitted'::text, 'Graded'::text, 'Missing'::text]));
alter table only "public"."submissions" add constraint "submissions_time_spent_seconds_check" CHECK (time_spent_seconds IS NULL OR time_spent_seconds >= 0);
alter table only "public"."support_pledges" add constraint "support_pledges_kind_check" CHECK (kind = ANY (ARRAY['donation'::text, 'volunteer'::text, 'partner'::text, 'staff'::text]));
alter table only "public"."support_pledges" add constraint "support_pledges_status_check" CHECK (status = ANY (ARRAY['new'::text, 'contacted'::text, 'closed'::text, 'archived'::text]));
alter table only "public"."teacher_course_plans" add constraint "teacher_course_plans_status_check" CHECK (status = ANY (ARRAY['draft'::text, 'submitted'::text, 'approved'::text, 'rejected'::text, 'revision_requested'::text]));
alter table only "public"."teacher_course_plans" add constraint "teacher_course_plans_title_check" CHECK (length(btrim(title)) >= 1 AND length(btrim(title)) <= 250);
alter table only "public"."training_materials" add constraint "training_materials_location_check" CHECK (file_path IS NOT NULL OR external_url IS NOT NULL);
alter table only "public"."training_materials" add constraint "training_materials_status_check" CHECK (status = ANY (ARRAY['draft'::text, 'submitted'::text, 'approved'::text, 'rejected'::text, 'revision_requested'::text]));
alter table only "public"."training_materials" add constraint "training_materials_title_check" CHECK (length(btrim(title)) >= 1 AND length(btrim(title)) <= 250);
alter table only "public"."training_materials" add constraint "training_materials_url_check" CHECK (external_url IS NULL OR external_url ~* '^https://'::text);
alter table only "public"."transparency_reports" add constraint "transparency_reports_category_check" CHECK (category = ANY (ARRAY['Registration papers'::text, 'Audited accounts'::text, 'Annual reports'::text]));
alter table only "public"."transparency_reports" add constraint "transparency_reports_check" CHECK (file_path = (id::text || '.pdf'::text));
alter table only "public"."transparency_reports" add constraint "transparency_reports_reporting_year_check" CHECK (reporting_year >= 1900 AND reporting_year <= 2200);
alter table only "public"."transparency_reports" add constraint "transparency_reports_summary_check" CHECK (length(summary) <= 2000);
alter table only "public"."transparency_reports" add constraint "transparency_reports_title_check" CHECK (length(btrim(title)) >= 1 AND length(btrim(title)) <= 200);
alter table only "public"."vacancy_applications" add constraint "vacancy_applications_status_check" CHECK (status = ANY (ARRAY['new'::text, 'shortlisted'::text, 'rejected'::text, 'hired'::text]));
alter table only "public"."website_enquiries" add constraint "website_enquiries_contact_check" CHECK (length(btrim(contact)) >= 5 AND length(btrim(contact)) <= 120);
alter table only "public"."website_enquiries" add constraint "website_enquiries_message_check" CHECK (length(btrim(message)) >= 1 AND length(btrim(message)) <= 2000);
alter table only "public"."website_enquiries" add constraint "website_enquiries_name_check" CHECK (length(btrim(name)) >= 2 AND length(btrim(name)) <= 100);
alter table only "public"."website_enquiries" add constraint "website_enquiries_program_check" CHECK (length(program) <= 120);
alter table only "public"."website_enquiries" add constraint "website_enquiries_source_check" CHECK (source = ANY (ARRAY['contact'::text, 'faq'::text, 'whatsapp'::text]));
alter table only "public"."welcome_email_templates" add constraint "welcome_email_templates_audience_check" CHECK (audience = ANY (ARRAY['staff'::text, 'student'::text]));
alter table only "public"."alumni_businesses" add constraint "alumni_businesses_created_by_fkey" FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE SET NULL;
alter table only "public"."announcements" add constraint "announcements_author_id_fkey" FOREIGN KEY (author_id) REFERENCES profiles(id) ON DELETE SET NULL;
alter table only "public"."approval_events" add constraint "approval_events_actor_id_fkey" FOREIGN KEY (actor_id) REFERENCES profiles(id) ON DELETE SET NULL;
alter table only "public"."assignments" add constraint "assignments_cohort_id_fkey" FOREIGN KEY (cohort_id) REFERENCES cohorts(id) ON DELETE CASCADE;
alter table only "public"."assignments" add constraint "assignments_created_by_fkey" FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE SET NULL;
alter table only "public"."assignments" add constraint "assignments_learning_unit_fkey" FOREIGN KEY (learning_unit_id) REFERENCES learning_units(id) ON DELETE SET NULL;
alter table only "public"."assistant_research_resources" add constraint "assistant_research_resources_owner_id_fkey" FOREIGN KEY (owner_id) REFERENCES profiles(id) ON DELETE CASCADE;
alter table only "public"."attendance" add constraint "attendance_class_session_fkey" FOREIGN KEY (class_session_id) REFERENCES class_sessions(id) ON DELETE SET NULL;
alter table only "public"."attendance" add constraint "attendance_cohort_id_fkey" FOREIGN KEY (cohort_id) REFERENCES cohorts(id) ON DELETE CASCADE;
alter table only "public"."attendance" add constraint "attendance_recorded_by_fkey" FOREIGN KEY (recorded_by) REFERENCES profiles(id) ON DELETE SET NULL;
alter table only "public"."attendance" add constraint "attendance_student_id_fkey" FOREIGN KEY (student_id) REFERENCES profiles(id) ON DELETE CASCADE;
alter table only "public"."blog_posts" add constraint "blog_posts_author_id_fkey" FOREIGN KEY (author_id) REFERENCES profiles(id) ON DELETE SET NULL;
alter table only "public"."blog_posts" add constraint "blog_posts_program_id_fkey" FOREIGN KEY (program_id) REFERENCES crash_programs(id) ON DELETE SET NULL;
alter table only "public"."certificate_audit" add constraint "certificate_audit_actor_id_fkey" FOREIGN KEY (actor_id) REFERENCES profiles(id);
alter table only "public"."certificate_audit" add constraint "certificate_audit_certificate_id_fkey" FOREIGN KEY (certificate_id) REFERENCES certificates(id) ON DELETE SET NULL;
alter table only "public"."certificates" add constraint "certificates_cohort_id_fkey" FOREIGN KEY (cohort_id) REFERENCES cohorts(id) ON DELETE SET NULL;
alter table only "public"."certificates" add constraint "certificates_issued_by_fkey" FOREIGN KEY (issued_by) REFERENCES profiles(id) ON DELETE SET NULL;
alter table only "public"."certificates" add constraint "certificates_program_id_fkey" FOREIGN KEY (program_id) REFERENCES programs(id) ON DELETE SET NULL;
alter table only "public"."certificates" add constraint "certificates_revoked_by_fkey" FOREIGN KEY (revoked_by) REFERENCES profiles(id);
alter table only "public"."certificates" add constraint "certificates_student_id_fkey" FOREIGN KEY (student_id) REFERENCES profiles(id) ON DELETE CASCADE;
alter table only "public"."chat_drafts" add constraint "chat_drafts_user_id_fkey" FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE;
alter table only "public"."chat_group_invites" add constraint "chat_group_invites_group_id_fkey" FOREIGN KEY (group_id) REFERENCES chat_groups(id) ON DELETE CASCADE;
alter table only "public"."chat_group_invites" add constraint "chat_group_invites_invitee_id_fkey" FOREIGN KEY (invitee_id) REFERENCES profiles(id) ON DELETE CASCADE;
alter table only "public"."chat_group_invites" add constraint "chat_group_invites_inviter_id_fkey" FOREIGN KEY (inviter_id) REFERENCES profiles(id) ON DELETE SET NULL;
alter table only "public"."chat_group_join_requests" add constraint "chat_group_join_requests_group_id_fkey" FOREIGN KEY (group_id) REFERENCES chat_groups(id) ON DELETE CASCADE;
alter table only "public"."chat_group_join_requests" add constraint "chat_group_join_requests_user_id_fkey" FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE;
alter table only "public"."chat_group_members" add constraint "chat_group_members_group_id_fkey" FOREIGN KEY (group_id) REFERENCES chat_groups(id) ON DELETE CASCADE;
alter table only "public"."chat_group_members" add constraint "chat_group_members_user_id_fkey" FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE;
alter table only "public"."chat_groups" add constraint "chat_groups_created_by_fkey" FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE CASCADE;
alter table only "public"."chat_poll_votes" add constraint "chat_poll_votes_poll_id_fkey" FOREIGN KEY (poll_id) REFERENCES chat_polls(id) ON DELETE CASCADE;
alter table only "public"."chat_poll_votes" add constraint "chat_poll_votes_user_id_fkey" FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE;
alter table only "public"."chat_polls" add constraint "chat_polls_creator_id_fkey" FOREIGN KEY (creator_id) REFERENCES profiles(id) ON DELETE SET NULL;
alter table only "public"."chat_polls" add constraint "chat_polls_group_id_fkey" FOREIGN KEY (group_id) REFERENCES chat_groups(id) ON DELETE CASCADE;
alter table only "public"."class_sessions" add constraint "class_sessions_cohort_id_fkey" FOREIGN KEY (cohort_id) REFERENCES cohorts(id) ON DELETE CASCADE;
alter table only "public"."class_sessions" add constraint "class_sessions_course_plan_id_fkey" FOREIGN KEY (course_plan_id) REFERENCES teacher_course_plans(id) ON DELETE SET NULL;
alter table only "public"."class_sessions" add constraint "class_sessions_learning_unit_id_fkey" FOREIGN KEY (learning_unit_id) REFERENCES learning_units(id) ON DELETE SET NULL;
alter table only "public"."class_sessions" add constraint "class_sessions_reviewed_by_fkey" FOREIGN KEY (reviewed_by) REFERENCES profiles(id) ON DELETE SET NULL;
alter table only "public"."class_sessions" add constraint "class_sessions_teacher_id_fkey" FOREIGN KEY (teacher_id) REFERENCES profiles(id) ON DELETE RESTRICT;
alter table only "public"."cohort_students" add constraint "cohort_students_cohort_id_fkey" FOREIGN KEY (cohort_id) REFERENCES cohorts(id) ON DELETE CASCADE;
alter table only "public"."cohort_students" add constraint "cohort_students_student_id_fkey" FOREIGN KEY (student_id) REFERENCES profiles(id) ON DELETE CASCADE;
alter table only "public"."cohorts" add constraint "cohorts_program_id_fkey" FOREIGN KEY (program_id) REFERENCES programs(id) ON DELETE RESTRICT;
alter table only "public"."cohorts" add constraint "cohorts_teacher_id_fkey" FOREIGN KEY (teacher_id) REFERENCES profiles(id) ON DELETE SET NULL;
alter table only "public"."course_completions" add constraint "course_completions_cohort_id_fkey" FOREIGN KEY (cohort_id) REFERENCES cohorts(id) ON DELETE CASCADE;
alter table only "public"."course_completions" add constraint "course_completions_issued_by_fkey" FOREIGN KEY (issued_by) REFERENCES profiles(id) ON DELETE SET NULL;
alter table only "public"."course_completions" add constraint "course_completions_program_id_fkey" FOREIGN KEY (program_id) REFERENCES programs(id) ON DELETE RESTRICT;
alter table only "public"."course_completions" add constraint "course_completions_student_id_fkey" FOREIGN KEY (student_id) REFERENCES profiles(id) ON DELETE CASCADE;
alter table only "public"."course_enrollments" add constraint "course_enrollments_cohort_id_fkey" FOREIGN KEY (cohort_id) REFERENCES cohorts(id) ON DELETE CASCADE;
alter table only "public"."course_enrollments" add constraint "course_enrollments_reviewed_by_fkey" FOREIGN KEY (reviewed_by) REFERENCES profiles(id) ON DELETE SET NULL;
alter table only "public"."course_enrollments" add constraint "course_enrollments_student_id_fkey" FOREIGN KEY (student_id) REFERENCES profiles(id) ON DELETE CASCADE;
alter table only "public"."crash_course_attempts" add constraint "crash_course_attempts_course_id_fkey" FOREIGN KEY (course_id) REFERENCES crash_courses(id) ON DELETE CASCADE;
alter table only "public"."crash_course_attempts" add constraint "crash_course_attempts_student_id_fkey" FOREIGN KEY (student_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table only "public"."crash_course_enrollments" add constraint "crash_course_enrollments_course_id_fkey" FOREIGN KEY (course_id) REFERENCES crash_courses(id) ON DELETE CASCADE;
alter table only "public"."crash_course_enrollments" add constraint "crash_course_enrollments_student_id_fkey" FOREIGN KEY (student_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table only "public"."crash_course_lessons" add constraint "crash_course_lessons_course_id_fkey" FOREIGN KEY (course_id) REFERENCES crash_courses(id) ON DELETE CASCADE;
alter table only "public"."crash_courses" add constraint "crash_courses_created_by_fkey" FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;
alter table only "public"."crash_programs" add constraint "crash_programs_created_by_fkey" FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;
alter table only "public"."direct_messages" add constraint "direct_messages_pinned_by_fkey" FOREIGN KEY (pinned_by) REFERENCES profiles(id) ON DELETE SET NULL;
alter table only "public"."direct_messages" add constraint "direct_messages_receiver_id_fkey" FOREIGN KEY (receiver_id) REFERENCES profiles(id) ON DELETE CASCADE;
alter table only "public"."direct_messages" add constraint "direct_messages_reply_to_fkey" FOREIGN KEY (reply_to) REFERENCES direct_messages(id) ON DELETE SET NULL;
alter table only "public"."direct_messages" add constraint "direct_messages_sender_id_fkey" FOREIGN KEY (sender_id) REFERENCES profiles(id) ON DELETE CASCADE;
alter table only "public"."discussion_replies" add constraint "discussion_replies_author_id_fkey" FOREIGN KEY (author_id) REFERENCES profiles(id);
alter table only "public"."discussion_replies" add constraint "discussion_replies_thread_id_fkey" FOREIGN KEY (thread_id) REFERENCES discussion_threads(id) ON DELETE CASCADE;
alter table only "public"."discussion_threads" add constraint "discussion_threads_author_id_fkey" FOREIGN KEY (author_id) REFERENCES profiles(id);
alter table only "public"."discussion_threads" add constraint "discussion_threads_cohort_id_fkey" FOREIGN KEY (cohort_id) REFERENCES cohorts(id) ON DELETE CASCADE;
alter table only "public"."discussion_threads" add constraint "discussion_threads_unit_id_fkey" FOREIGN KEY (unit_id) REFERENCES learning_units(id) ON DELETE SET NULL;
alter table only "public"."email_outbox" add constraint "email_outbox_related_user_id_fkey" FOREIGN KEY (related_user_id) REFERENCES profiles(id) ON DELETE SET NULL;
alter table only "public"."enrollment_arrangement_history" add constraint "enrollment_arrangement_history_changed_by_fkey" FOREIGN KEY (changed_by) REFERENCES profiles(id) ON DELETE SET NULL;
alter table only "public"."enrollment_arrangement_history" add constraint "enrollment_arrangement_history_enrollment_id_fkey" FOREIGN KEY (enrollment_id) REFERENCES course_enrollments(id) ON DELETE CASCADE;
alter table only "public"."entrance_test_results" add constraint "entrance_test_results_applicant_id_fkey" FOREIGN KEY (applicant_id) REFERENCES profiles(id) ON DELETE SET NULL;
alter table only "public"."entrance_test_results" add constraint "entrance_test_results_quiz_id_fkey" FOREIGN KEY (quiz_id) REFERENCES quizzes(id) ON DELETE SET NULL;
alter table only "public"."fee_transactions" add constraint "fee_transactions_created_by_fkey" FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE SET NULL;
alter table only "public"."fee_transactions" add constraint "fee_transactions_student_id_fkey" FOREIGN KEY (student_id) REFERENCES profiles(id) ON DELETE CASCADE;
alter table only "public"."file_submissions" add constraint "file_submissions_reviewer_id_fkey" FOREIGN KEY (reviewer_id) REFERENCES profiles(id) ON DELETE SET NULL;
alter table only "public"."file_submissions" add constraint "file_submissions_submitter_id_fkey" FOREIGN KEY (submitter_id) REFERENCES profiles(id) ON DELETE CASCADE;
alter table only "public"."grade_appeals" add constraint "grade_appeals_assignment_id_fkey" FOREIGN KEY (assignment_id) REFERENCES assignments(id);
alter table only "public"."grade_appeals" add constraint "grade_appeals_decided_by_fkey" FOREIGN KEY (decided_by) REFERENCES profiles(id);
alter table only "public"."grade_appeals" add constraint "grade_appeals_quiz_attempt_id_fkey" FOREIGN KEY (quiz_attempt_id) REFERENCES quiz_attempts(id);
alter table only "public"."grade_appeals" add constraint "grade_appeals_student_id_fkey" FOREIGN KEY (student_id) REFERENCES profiles(id);
alter table only "public"."grade_assessments" add constraint "grade_assessments_created_by_fkey" FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE SET NULL;
alter table only "public"."group_messages" add constraint "group_messages_group_id_fkey" FOREIGN KEY (group_id) REFERENCES chat_groups(id) ON DELETE CASCADE;
alter table only "public"."group_messages" add constraint "group_messages_pinned_by_fkey" FOREIGN KEY (pinned_by) REFERENCES profiles(id) ON DELETE SET NULL;
alter table only "public"."group_messages" add constraint "group_messages_reply_to_fkey" FOREIGN KEY (reply_to) REFERENCES group_messages(id) ON DELETE SET NULL;
alter table only "public"."group_messages" add constraint "group_messages_sender_id_fkey" FOREIGN KEY (sender_id) REFERENCES profiles(id) ON DELETE CASCADE;
alter table only "public"."helpdesk_messages" add constraint "helpdesk_messages_author_id_fkey" FOREIGN KEY (author_id) REFERENCES profiles(id);
alter table only "public"."helpdesk_messages" add constraint "helpdesk_messages_ticket_id_fkey" FOREIGN KEY (ticket_id) REFERENCES helpdesk_tickets(id);
alter table only "public"."helpdesk_tickets" add constraint "helpdesk_tickets_student_id_fkey" FOREIGN KEY (student_id) REFERENCES profiles(id);
alter table only "public"."learning_memory" add constraint "learning_memory_program_id_fkey" FOREIGN KEY (program_id) REFERENCES programs(id) ON DELETE CASCADE;
alter table only "public"."learning_memory" add constraint "learning_memory_resource_id_fkey" FOREIGN KEY (resource_id) REFERENCES training_materials(id) ON DELETE SET NULL;
alter table only "public"."learning_memory" add constraint "learning_memory_unit_id_fkey" FOREIGN KEY (unit_id) REFERENCES learning_units(id) ON DELETE CASCADE;
alter table only "public"."learning_memory" add constraint "learning_memory_user_id_fkey" FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE;
alter table only "public"."learning_units" add constraint "learning_units_classwork_assignment_fkey" FOREIGN KEY (classwork_assignment_id) REFERENCES assignments(id) ON DELETE SET NULL;
alter table only "public"."learning_units" add constraint "learning_units_cohort_id_fkey" FOREIGN KEY (cohort_id) REFERENCES cohorts(id) ON DELETE CASCADE;
alter table only "public"."learning_units" add constraint "learning_units_course_plan_fkey" FOREIGN KEY (course_plan_id) REFERENCES teacher_course_plans(id) ON DELETE SET NULL;
alter table only "public"."learning_units" add constraint "learning_units_created_by_fkey" FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE SET NULL;
alter table only "public"."learning_units" add constraint "learning_units_program_id_fkey" FOREIGN KEY (program_id) REFERENCES programs(id) ON DELETE CASCADE;
alter table only "public"."learning_units" add constraint "learning_units_quiz_fkey" FOREIGN KEY (quiz_id) REFERENCES quizzes(id) ON DELETE SET NULL;
alter table only "public"."learning_units" add constraint "learning_units_reviewed_by_fkey" FOREIGN KEY (reviewed_by) REFERENCES profiles(id) ON DELETE SET NULL;
alter table only "public"."message_reactions" add constraint "message_reactions_user_id_fkey" FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE;
alter table only "public"."module_responsibilities" add constraint "module_responsibilities_assigned_by_fkey" FOREIGN KEY (assigned_by) REFERENCES profiles(id);
alter table only "public"."module_responsibilities" add constraint "module_responsibilities_program_module_id_fkey" FOREIGN KEY (program_module_id) REFERENCES program_modules(id) ON DELETE CASCADE;
alter table only "public"."module_responsibilities" add constraint "module_responsibilities_staff_id_fkey" FOREIGN KEY (staff_id) REFERENCES profiles(id) ON DELETE CASCADE;
alter table only "public"."newsletter_campaigns" add constraint "newsletter_campaigns_created_by_fkey" FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;
alter table only "public"."newsletter_campaigns" add constraint "newsletter_campaigns_template_id_fkey" FOREIGN KEY (template_id) REFERENCES email_templates(id) ON DELETE SET NULL;
alter table only "public"."notification_outbox" add constraint "notification_outbox_created_by_fkey" FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;
alter table only "public"."notifications" add constraint "notifications_recipient_id_fkey" FOREIGN KEY (recipient_id) REFERENCES profiles(id) ON DELETE CASCADE;
alter table only "public"."notifications" add constraint "notifications_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table only "public"."onesignal_devices" add constraint "onesignal_devices_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table only "public"."payment_submissions" add constraint "payment_submissions_channel_id_fkey" FOREIGN KEY (channel_id) REFERENCES payment_channels(id) ON DELETE SET NULL;
alter table only "public"."payment_submissions" add constraint "payment_submissions_fee_transaction_id_fkey" FOREIGN KEY (fee_transaction_id) REFERENCES fee_transactions(id) ON DELETE SET NULL;
alter table only "public"."payment_submissions" add constraint "payment_submissions_reviewed_by_fkey" FOREIGN KEY (reviewed_by) REFERENCES profiles(id) ON DELETE SET NULL;
alter table only "public"."payment_submissions" add constraint "payment_submissions_student_id_fkey" FOREIGN KEY (student_id) REFERENCES profiles(id) ON DELETE CASCADE;
alter table only "public"."policy_acceptances" add constraint "policy_acceptances_policy_id_fkey" FOREIGN KEY (policy_id) REFERENCES school_policies(id) ON DELETE CASCADE;
alter table only "public"."policy_acceptances" add constraint "policy_acceptances_user_id_fkey" FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE;
alter table only "public"."portal_kv" add constraint "portal_kv_updated_by_fkey" FOREIGN KEY (updated_by) REFERENCES auth.users(id) ON DELETE SET NULL;
alter table only "public"."profiles" add constraint "profiles_id_fkey" FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table only "public"."profiles" add constraint "profiles_role_fkey" FOREIGN KEY (role) REFERENCES roles(name) ON UPDATE CASCADE;
alter table only "public"."program_applications" add constraint "program_applications_applicant_id_fkey" FOREIGN KEY (applicant_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table only "public"."program_applications" add constraint "program_applications_blog_post_id_fkey" FOREIGN KEY (blog_post_id) REFERENCES blog_posts(id) ON DELETE SET NULL;
alter table only "public"."program_applications" add constraint "program_applications_program_id_fkey" FOREIGN KEY (program_id) REFERENCES crash_programs(id) ON DELETE SET NULL;
alter table only "public"."program_modules" add constraint "program_modules_program_id_fkey" FOREIGN KEY (program_id) REFERENCES programs(id) ON DELETE CASCADE;
alter table only "public"."push_subscriptions" add constraint "push_subscriptions_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table only "public"."quiz_attempts" add constraint "quiz_attempts_quiz_id_fkey" FOREIGN KEY (quiz_id) REFERENCES quizzes(id) ON DELETE CASCADE;
alter table only "public"."quiz_attempts" add constraint "quiz_attempts_student_id_fkey" FOREIGN KEY (student_id) REFERENCES profiles(id) ON DELETE CASCADE;
alter table only "public"."quiz_questions" add constraint "quiz_questions_quiz_id_fkey" FOREIGN KEY (quiz_id) REFERENCES quizzes(id) ON DELETE CASCADE;
alter table only "public"."quizzes" add constraint "quizzes_cohort_id_fkey" FOREIGN KEY (cohort_id) REFERENCES cohorts(id) ON DELETE CASCADE;
alter table only "public"."quizzes" add constraint "quizzes_created_by_fkey" FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE SET NULL;
alter table only "public"."quizzes" add constraint "quizzes_learning_unit_fkey" FOREIGN KEY (learning_unit_id) REFERENCES learning_units(id) ON DELETE SET NULL;
alter table only "public"."quizzes" add constraint "quizzes_program_id_fkey" FOREIGN KEY (program_id) REFERENCES programs(id) ON DELETE CASCADE;
alter table only "public"."reminder_items" add constraint "reminder_items_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table only "public"."reminder_settings" add constraint "reminder_settings_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table only "public"."role_permissions" add constraint "role_permissions_permission_fkey" FOREIGN KEY (permission) REFERENCES permissions(key) ON DELETE CASCADE;
alter table only "public"."role_permissions" add constraint "role_permissions_role_fkey" FOREIGN KEY (role) REFERENCES roles(name) ON DELETE CASCADE;
alter table only "public"."self_paced_activities" add constraint "self_paced_activities_lesson_id_fkey" FOREIGN KEY (lesson_id) REFERENCES self_paced_lessons(id) ON DELETE SET NULL;
alter table only "public"."self_paced_activities" add constraint "self_paced_activities_week_id_fkey" FOREIGN KEY (week_id) REFERENCES self_paced_weeks(id) ON DELETE CASCADE;
alter table only "public"."self_paced_lessons" add constraint "self_paced_lessons_week_id_fkey" FOREIGN KEY (week_id) REFERENCES self_paced_weeks(id) ON DELETE CASCADE;
alter table only "public"."self_paced_participations" add constraint "self_paced_participations_approved_by_fkey" FOREIGN KEY (approved_by) REFERENCES auth.users(id) ON DELETE SET NULL;
alter table only "public"."self_paced_participations" add constraint "self_paced_participations_cohort_id_fkey" FOREIGN KEY (cohort_id) REFERENCES cohorts(id) ON DELETE SET NULL;
alter table only "public"."self_paced_participations" add constraint "self_paced_participations_program_id_fkey" FOREIGN KEY (program_id) REFERENCES programs(id) ON DELETE CASCADE;
alter table only "public"."self_paced_participations" add constraint "self_paced_participations_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table only "public"."self_paced_plans" add constraint "self_paced_plans_program_id_fkey" FOREIGN KEY (program_id) REFERENCES programs(id) ON DELETE CASCADE;
alter table only "public"."self_paced_plans" add constraint "self_paced_plans_user_id_fkey" FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE;
alter table only "public"."self_paced_progress" add constraint "self_paced_progress_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table only "public"."self_paced_progress" add constraint "self_paced_progress_week_id_fkey" FOREIGN KEY (week_id) REFERENCES self_paced_weeks(id) ON DELETE CASCADE;
alter table only "public"."self_paced_resources" add constraint "self_paced_resources_created_by_fkey" FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;
alter table only "public"."self_paced_resources" add constraint "self_paced_resources_week_id_fkey" FOREIGN KEY (week_id) REFERENCES self_paced_weeks(id) ON DELETE CASCADE;
alter table only "public"."self_paced_submissions" add constraint "self_paced_submissions_activity_id_fkey" FOREIGN KEY (activity_id) REFERENCES self_paced_activities(id) ON DELETE CASCADE;
alter table only "public"."self_paced_submissions" add constraint "self_paced_submissions_graded_by_fkey" FOREIGN KEY (graded_by) REFERENCES auth.users(id) ON DELETE SET NULL;
alter table only "public"."self_paced_submissions" add constraint "self_paced_submissions_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table only "public"."self_paced_weeks" add constraint "self_paced_weeks_created_by_fkey" FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;
alter table only "public"."self_paced_weeks" add constraint "self_paced_weeks_program_id_fkey" FOREIGN KEY (program_id) REFERENCES programs(id) ON DELETE CASCADE;
alter table only "public"."staff_vacancies" add constraint "staff_vacancies_created_by_fkey" FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE SET NULL;
alter table only "public"."student_learning_progress" add constraint "student_learning_progress_cohort_id_fkey" FOREIGN KEY (cohort_id) REFERENCES cohorts(id) ON DELETE CASCADE;
alter table only "public"."student_learning_progress" add constraint "student_learning_progress_learning_unit_id_fkey" FOREIGN KEY (learning_unit_id) REFERENCES learning_units(id) ON DELETE CASCADE;
alter table only "public"."student_learning_progress" add constraint "student_learning_progress_student_id_fkey" FOREIGN KEY (student_id) REFERENCES profiles(id) ON DELETE CASCADE;
alter table only "public"."study_materials" add constraint "study_materials_cohort_id_fkey" FOREIGN KEY (cohort_id) REFERENCES cohorts(id) ON DELETE SET NULL;
alter table only "public"."study_materials" add constraint "study_materials_created_by_fkey" FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE SET NULL;
alter table only "public"."study_materials" add constraint "study_materials_program_id_fkey" FOREIGN KEY (program_id) REFERENCES programs(id) ON DELETE SET NULL;
alter table only "public"."study_materials" add constraint "study_materials_submission_id_fkey" FOREIGN KEY (submission_id) REFERENCES file_submissions(id) ON DELETE SET NULL;
alter table only "public"."submissions" add constraint "submissions_assignment_id_fkey" FOREIGN KEY (assignment_id) REFERENCES assignments(id) ON DELETE CASCADE;
alter table only "public"."submissions" add constraint "submissions_student_id_fkey" FOREIGN KEY (student_id) REFERENCES profiles(id) ON DELETE CASCADE;
alter table only "public"."teacher_course_plans" add constraint "teacher_course_plans_cohort_id_fkey" FOREIGN KEY (cohort_id) REFERENCES cohorts(id) ON DELETE CASCADE;
alter table only "public"."teacher_course_plans" add constraint "teacher_course_plans_reviewed_by_fkey" FOREIGN KEY (reviewed_by) REFERENCES profiles(id) ON DELETE SET NULL;
alter table only "public"."teacher_course_plans" add constraint "teacher_course_plans_teacher_id_fkey" FOREIGN KEY (teacher_id) REFERENCES profiles(id) ON DELETE RESTRICT;
alter table only "public"."training_materials" add constraint "training_materials_cohort_id_fkey" FOREIGN KEY (cohort_id) REFERENCES cohorts(id) ON DELETE CASCADE;
alter table only "public"."training_materials" add constraint "training_materials_created_by_fkey" FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE SET NULL;
alter table only "public"."training_materials" add constraint "training_materials_learning_unit_id_fkey" FOREIGN KEY (learning_unit_id) REFERENCES learning_units(id) ON DELETE SET NULL;
alter table only "public"."training_materials" add constraint "training_materials_program_id_fkey" FOREIGN KEY (program_id) REFERENCES programs(id) ON DELETE CASCADE;
alter table only "public"."training_materials" add constraint "training_materials_reviewed_by_fkey" FOREIGN KEY (reviewed_by) REFERENCES profiles(id) ON DELETE SET NULL;
alter table only "public"."vacancy_applications" add constraint "vacancy_applications_vacancy_id_fkey" FOREIGN KEY (vacancy_id) REFERENCES staff_vacancies(id) ON DELETE SET NULL;

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------
CREATE INDEX announcements_author_id_fk_idx ON public.announcements USING btree (author_id);
CREATE INDEX announcements_published_date_idx ON public.announcements USING btree (published_date);
CREATE INDEX announcements_status_idx ON public.announcements USING btree (status);
CREATE INDEX announcements_visibility_idx ON public.announcements USING btree (status, scheduled_at, expires_at);
CREATE UNIQUE INDEX app_integration_events_dedup ON public.app_integration_events USING btree (manifest_id, external_id) WHERE (external_id IS NOT NULL);
CREATE INDEX app_integration_events_user ON public.app_integration_events USING btree (user_id, received_at DESC);
CREATE UNIQUE INDEX application_drafts_email_idx ON public.application_drafts USING btree (lower(btrim(email)));
CREATE INDEX approval_events_actor_id_fk_idx ON public.approval_events USING btree (actor_id);
CREATE INDEX approval_events_entity_idx ON public.approval_events USING btree (entity_type, entity_id, created_at DESC);
CREATE INDEX assignments_cohort_id_fk_idx ON public.assignments USING btree (cohort_id);
CREATE INDEX assignments_cohort_id_idx ON public.assignments USING btree (cohort_id);
CREATE INDEX assignments_cohort_idx ON public.assignments USING btree (cohort_id);
CREATE INDEX assignments_learning_unit_id_fk_idx ON public.assignments USING btree (learning_unit_id);
CREATE INDEX idx_assignments_created_by ON public.assignments USING btree (created_by);
CREATE INDEX attendance_class_session_id_fk_idx ON public.attendance USING btree (class_session_id);
CREATE INDEX attendance_cohort_date_idx ON public.attendance USING btree (cohort_id, attendance_date);
CREATE INDEX attendance_student_date_idx ON public.attendance USING btree (student_id, attendance_date DESC);
CREATE INDEX idx_attendance_cohort_id ON public.attendance USING btree (cohort_id);
CREATE INDEX idx_attendance_recorded_by ON public.attendance USING btree (recorded_by);
CREATE INDEX idx_attendance_student_id ON public.attendance USING btree (student_id);
CREATE INDEX blog_posts_author_id_fk_idx ON public.blog_posts USING btree (author_id);
CREATE INDEX blog_posts_program_id_idx ON public.blog_posts USING btree (program_id);
CREATE INDEX blog_posts_status_published_idx ON public.blog_posts USING btree (status, published_at DESC);
CREATE INDEX certificate_audit_serial_idx ON public.certificate_audit USING btree (lower(btrim(serial)));
CREATE INDEX certificates_holder_program_idx ON public.certificates USING btree (student_id, program_id);
CREATE INDEX certificates_program_id_fk_idx ON public.certificates USING btree (program_id);
CREATE INDEX certificates_serial_idx ON public.certificates USING btree (serial);
CREATE UNIQUE INDEX certificates_serial_unique ON public.certificates USING btree (lower(btrim(serial)));
CREATE INDEX certificates_student_id_fk_idx ON public.certificates USING btree (student_id);
CREATE INDEX certificates_student_id_idx ON public.certificates USING btree (student_id);
CREATE INDEX certificates_student_idx ON public.certificates USING btree (student_id);
CREATE INDEX idx_certificates_cohort_id ON public.certificates USING btree (cohort_id);
CREATE INDEX idx_certificates_issued_by ON public.certificates USING btree (issued_by);
CREATE INDEX chat_group_members_user_idx ON public.chat_group_members USING btree (user_id);
CREATE INDEX class_sessions_cohort_starts_at_idx ON public.class_sessions USING btree (cohort_id, starts_at);
CREATE INDEX class_sessions_course_plan_id_fk_idx ON public.class_sessions USING btree (course_plan_id);
CREATE INDEX class_sessions_learning_unit_id_fk_idx ON public.class_sessions USING btree (learning_unit_id);
CREATE INDEX class_sessions_reviewed_by_fk_idx ON public.class_sessions USING btree (reviewed_by);
CREATE INDEX class_sessions_teacher_starts_at_idx ON public.class_sessions USING btree (teacher_id, starts_at);
CREATE INDEX idx_class_sessions_cohort_id ON public.class_sessions USING btree (cohort_id);
CREATE INDEX idx_class_sessions_teacher_id ON public.class_sessions USING btree (teacher_id);
CREATE INDEX cohort_students_cohort_idx ON public.cohort_students USING btree (cohort_id);
CREATE INDEX cohort_students_student_id_fk_idx ON public.cohort_students USING btree (student_id);
CREATE INDEX cohort_students_student_id_idx ON public.cohort_students USING btree (student_id);
CREATE INDEX cohort_students_student_idx ON public.cohort_students USING btree (student_id);
CREATE INDEX idx_cohort_students_cohort_id ON public.cohort_students USING btree (cohort_id);
CREATE INDEX cohort_timetable_cohort_day_idx ON public.cohort_timetable_slots USING btree (cohort_id, day_of_week, starts_at);
CREATE INDEX cohorts_program_id_idx ON public.cohorts USING btree (program_id);
CREATE INDEX cohorts_program_idx ON public.cohorts USING btree (program_id);
CREATE INDEX cohorts_teacher_id_fk_idx ON public.cohorts USING btree (teacher_id);
CREATE INDEX cohorts_teacher_idx ON public.cohorts USING btree (teacher_id);
CREATE INDEX course_completions_cohort_id_fk_idx ON public.course_completions USING btree (cohort_id);
CREATE INDEX course_completions_issued_by_fk_idx ON public.course_completions USING btree (issued_by);
CREATE INDEX course_completions_program_id_fk_idx ON public.course_completions USING btree (program_id);
CREATE INDEX course_completions_student_idx ON public.course_completions USING btree (student_id, status);
CREATE INDEX idx_course_completions_student_id ON public.course_completions USING btree (student_id);
CREATE INDEX course_enrollments_cohort_status_idx ON public.course_enrollments USING btree (cohort_id, status);
CREATE INDEX course_enrollments_reviewed_by_fk_idx ON public.course_enrollments USING btree (reviewed_by);
CREATE INDEX course_enrollments_student_status_idx ON public.course_enrollments USING btree (student_id, status);
CREATE INDEX idx_course_enrollments_cohort_id ON public.course_enrollments USING btree (cohort_id);
CREATE INDEX idx_course_enrollments_student_id ON public.course_enrollments USING btree (student_id);
CREATE INDEX idx_crash_course_attempts_student_id ON public.crash_course_attempts USING btree (student_id);
CREATE INDEX idx_crash_course_enrollments_student_id ON public.crash_course_enrollments USING btree (student_id);
CREATE INDEX idx_crash_course_lessons_course_id ON public.crash_course_lessons USING btree (course_id);
CREATE INDEX crash_programs_published_idx ON public.crash_programs USING btree (published, created_at DESC);
CREATE INDEX direct_messages_pair_idx ON public.direct_messages USING btree (sender_id, receiver_id, created_at DESC);
CREATE INDEX direct_messages_pinned_idx ON public.direct_messages USING btree (pinned_at) WHERE (pinned_at IS NOT NULL);
CREATE INDEX direct_messages_reply_idx ON public.direct_messages USING btree (reply_to);
CREATE INDEX discussion_replies_thread_idx ON public.discussion_replies USING btree (thread_id, created_at);
CREATE INDEX discussion_threads_cohort_idx ON public.discussion_threads USING btree (cohort_id, created_at DESC);
CREATE INDEX email_outbox_related_user_id_fk_idx ON public.email_outbox USING btree (related_user_id);
CREATE INDEX email_outbox_status_send_after_idx ON public.email_outbox USING btree (status, send_after);
CREATE INDEX enrollment_arrangement_history_enrollment_idx ON public.enrollment_arrangement_history USING btree (enrollment_id, created_at DESC);
CREATE INDEX entrance_results_contact_idx ON public.entrance_test_results USING btree (contact);
CREATE INDEX entrance_results_created_idx ON public.entrance_test_results USING btree (created_at DESC);
CREATE INDEX entrance_results_ref_idx ON public.entrance_test_results USING btree (ref);
CREATE INDEX fee_transactions_student_date_idx ON public.fee_transactions USING btree (student_id, transaction_date DESC);
CREATE INDEX fee_transactions_student_idx ON public.fee_transactions USING btree (student_id);
CREATE INDEX idx_fee_transactions_created_by ON public.fee_transactions USING btree (created_by);
CREATE INDEX idx_fee_transactions_student_id ON public.fee_transactions USING btree (student_id);
CREATE UNIQUE INDEX grade_appeals_open_assignment ON public.grade_appeals USING btree (student_id, assignment_id) WHERE ((work_kind = 'assignment'::text) AND (status = 'submitted'::text));
CREATE UNIQUE INDEX grade_appeals_open_quiz ON public.grade_appeals USING btree (student_id, quiz_attempt_id) WHERE ((work_kind = 'quiz'::text) AND (status = 'submitted'::text));
CREATE INDEX grade_appeals_owner_created ON public.grade_appeals USING btree (student_id, created_at DESC);
CREATE INDEX grade_appeals_status_created ON public.grade_appeals USING btree (status, created_at DESC);
CREATE INDEX grade_assessments_kind_idx ON public.grade_assessments USING btree (kind, published);
CREATE INDEX group_messages_group_idx ON public.group_messages USING btree (group_id, created_at DESC);
CREATE INDEX group_messages_pinned_idx ON public.group_messages USING btree (pinned_at) WHERE (pinned_at IS NOT NULL);
CREATE INDEX group_messages_reply_idx ON public.group_messages USING btree (reply_to);
CREATE INDEX helpdesk_thread ON public.helpdesk_messages USING btree (ticket_id, created_at);
CREATE INDEX helpdesk_owner_updated ON public.helpdesk_tickets USING btree (student_id, updated_at DESC);
CREATE INDEX helpdesk_status_updated ON public.helpdesk_tickets USING btree (status, updated_at DESC);
CREATE INDEX knock_events_recipient_idx ON public.knock_notification_events USING btree (recipient_uuid, created_at DESC);
CREATE INDEX idx_learning_units_cohort_id ON public.learning_units USING btree (cohort_id);
CREATE INDEX idx_learning_units_program_id ON public.learning_units USING btree (program_id);
CREATE INDEX learning_units_classwork_assignment_id_fk_idx ON public.learning_units USING btree (classwork_assignment_id);
CREATE INDEX learning_units_cohort_position_idx ON public.learning_units USING btree (cohort_id, "position");
CREATE INDEX learning_units_course_plan_id_fk_idx ON public.learning_units USING btree (course_plan_id);
CREATE INDEX learning_units_created_by_fk_idx ON public.learning_units USING btree (created_by);
CREATE INDEX learning_units_program_position_idx ON public.learning_units USING btree (program_id, "position");
CREATE INDEX learning_units_quiz_id_fk_idx ON public.learning_units USING btree (quiz_id);
CREATE INDEX learning_units_reviewed_by_fk_idx ON public.learning_units USING btree (reviewed_by);
CREATE INDEX message_reactions_message_idx ON public.message_reactions USING btree (message_id, message_kind);
CREATE INDEX module_responsibilities_module_idx ON public.module_responsibilities USING btree (program_module_id, active);
CREATE INDEX module_responsibilities_staff_idx ON public.module_responsibilities USING btree (staff_id, active);
CREATE INDEX idx_outbox_created ON public.notification_outbox USING btree (created_at DESC);
CREATE UNIQUE INDEX notification_outbox_notification_id_key ON public.notification_outbox USING btree (notification_id);
CREATE INDEX notification_outbox_queued_idx ON public.notification_outbox USING btree (created_at) WHERE (status = 'queued'::text);
CREATE INDEX notification_outbox_retry_idx ON public.notification_outbox USING btree (COALESCE(next_attempt_at, created_at)) WHERE (status = ANY (ARRAY['queued'::text, 'failed'::text, 'sending'::text]));
CREATE INDEX idx_notifications_recipient_id ON public.notifications USING btree (recipient_id);
CREATE INDEX idx_notifications_user ON public.notifications USING btree (user_id, created_at DESC);
CREATE UNIQUE INDEX notifications_one_welcome_per_user ON public.notifications USING btree (recipient_id) WHERE (kind = 'welcome'::text);
CREATE INDEX notifications_recipient_kind_entity_idx ON public.notifications USING btree (recipient_id, kind, entity_id);
CREATE INDEX notifications_recipient_unread_idx ON public.notifications USING btree (recipient_id, created_at DESC) WHERE (read_at IS NULL);
CREATE INDEX idx_devices_user ON public.onesignal_devices USING btree (user_id);
CREATE INDEX payment_channels_active_sort_idx ON public.payment_channels USING btree (active, sort);
CREATE INDEX idx_payment_submissions_student_id ON public.payment_submissions USING btree (student_id);
CREATE INDEX payment_submissions_channel_id_fk_idx ON public.payment_submissions USING btree (channel_id);
CREATE INDEX payment_submissions_fee_transaction_id_fk_idx ON public.payment_submissions USING btree (fee_transaction_id);
CREATE UNIQUE INDEX payment_submissions_provider_reference_active_key ON public.payment_submissions USING btree (provider, transaction_reference) WHERE (status <> 'rejected'::text);
CREATE INDEX payment_submissions_reviewed_by_fk_idx ON public.payment_submissions USING btree (reviewed_by);
CREATE INDEX payment_submissions_status_idx ON public.payment_submissions USING btree (status, created_at DESC);
CREATE INDEX payment_submissions_student_idx ON public.payment_submissions USING btree (student_id, created_at DESC);
CREATE UNIQUE INDEX profiles_account_number_unique ON public.profiles USING btree (account_number);
CREATE INDEX profiles_email_idx ON public.profiles USING btree (lower(email));
CREATE INDEX profiles_role_fk_idx ON public.profiles USING btree (role);
CREATE INDEX profiles_role_idx ON public.profiles USING btree (role);
CREATE INDEX profiles_status_idx ON public.profiles USING btree (status);
CREATE INDEX program_applications_applicant_idx ON public.program_applications USING btree (applicant_id, created_at DESC);
CREATE INDEX idx_program_modules_program_id ON public.program_modules USING btree (program_id);
CREATE INDEX program_modules_program_idx ON public.program_modules USING btree (program_id);
CREATE INDEX programs_category_idx ON public.programs USING btree (category);
CREATE UNIQUE INDEX programs_course_number_unique ON public.programs USING btree (course_number);
CREATE INDEX push_subscriptions_user_idx ON public.push_subscriptions USING btree (user_id) WHERE enabled;
CREATE INDEX idx_quiz_attempts_quiz_id ON public.quiz_attempts USING btree (quiz_id);
CREATE INDEX idx_quiz_attempts_student_id ON public.quiz_attempts USING btree (student_id);
CREATE INDEX quiz_attempts_student_idx ON public.quiz_attempts USING btree (student_id, quiz_id);
CREATE INDEX idx_quiz_questions_quiz_id ON public.quiz_questions USING btree (quiz_id);
CREATE INDEX quiz_questions_quiz_idx ON public.quiz_questions USING btree (quiz_id, "position");
CREATE INDEX quizzes_cohort_idx ON public.quizzes USING btree (cohort_id);
CREATE INDEX quizzes_created_by_fk_idx ON public.quizzes USING btree (created_by);
CREATE INDEX quizzes_entrance_idx ON public.quizzes USING btree (is_entrance, status);
CREATE INDEX quizzes_learning_unit_id_fk_idx ON public.quizzes USING btree (learning_unit_id);
CREATE INDEX quizzes_program_idx ON public.quizzes USING btree (program_id);
CREATE INDEX reminder_items_due_idx ON public.reminder_items USING btree (due_at) WHERE (sent_at IS NULL);
CREATE INDEX idx_role_permissions_role ON public.role_permissions USING btree (role);
CREATE INDEX role_permissions_permission_fk_idx ON public.role_permissions USING btree (permission);
CREATE INDEX idx_student_learning_progress_student_id ON public.student_learning_progress USING btree (student_id);
CREATE INDEX student_learning_progress_cohort_id_fk_idx ON public.student_learning_progress USING btree (cohort_id);
CREATE INDEX student_learning_progress_learning_unit_id_fk_idx ON public.student_learning_progress USING btree (learning_unit_id);
CREATE INDEX student_learning_progress_student_cohort_idx ON public.student_learning_progress USING btree (student_id, cohort_id);
CREATE INDEX study_plans_created_idx ON public.study_plans USING btree (created_at DESC);
CREATE INDEX idx_submissions_assignment_id ON public.submissions USING btree (assignment_id);
CREATE INDEX submissions_assignment_idx ON public.submissions USING btree (assignment_id);
CREATE INDEX submissions_student_id_idx ON public.submissions USING btree (student_id);
CREATE INDEX submissions_student_idx ON public.submissions USING btree (student_id);
CREATE INDEX support_pledges_created_idx ON public.support_pledges USING btree (created_at DESC);
CREATE INDEX idx_teacher_course_plans_cohort_id ON public.teacher_course_plans USING btree (cohort_id);
CREATE INDEX teacher_course_plans_cohort_status_idx ON public.teacher_course_plans USING btree (cohort_id, status);
CREATE INDEX teacher_course_plans_reviewed_by_fk_idx ON public.teacher_course_plans USING btree (reviewed_by);
CREATE INDEX teacher_course_plans_teacher_id_fk_idx ON public.teacher_course_plans USING btree (teacher_id);
CREATE INDEX idx_training_materials_cohort_id ON public.training_materials USING btree (cohort_id);
CREATE INDEX training_materials_cohort_status_idx ON public.training_materials USING btree (cohort_id, status);
CREATE INDEX training_materials_created_by_fk_idx ON public.training_materials USING btree (created_by);
CREATE UNIQUE INDEX training_materials_file_path_key ON public.training_materials USING btree (file_path) WHERE (file_path IS NOT NULL);
CREATE INDEX training_materials_learning_unit_id_fk_idx ON public.training_materials USING btree (learning_unit_id);
CREATE INDEX training_materials_program_id_fk_idx ON public.training_materials USING btree (program_id);
CREATE INDEX training_materials_reviewed_by_fk_idx ON public.training_materials USING btree (reviewed_by);
CREATE INDEX transparency_file_path_idx ON public.transparency_reports USING btree (file_path);
CREATE INDEX transparency_published_year_idx ON public.transparency_reports USING btree (published, reporting_year DESC);
CREATE INDEX website_enquiries_created_idx ON public.website_enquiries USING btree (created_at DESC);

-- ---------------------------------------------------------------------------
-- Row level security
-- ---------------------------------------------------------------------------
alter table "public"."alumni_businesses" enable row level security;
alter table "public"."announcements" enable row level security;
alter table "public"."app_integration_events" enable row level security;
alter table "public"."app_integration_usage" enable row level security;
alter table "public"."app_integration_watch" enable row level security;
alter table "public"."app_integrations" enable row level security;
alter table "public"."application_drafts" enable row level security;
alter table "public"."approval_events" enable row level security;
alter table "public"."aptitude_control_settings" enable row level security;
alter table "public"."aptitude_preparations" enable row level security;
alter table "public"."assignments" enable row level security;
alter table "public"."assistant_research_resources" enable row level security;
alter table "public"."assistant_usage" enable row level security;
alter table "public"."attendance" enable row level security;
alter table "public"."blog_posts" enable row level security;
alter table "public"."certificate_audit" enable row level security;
alter table "public"."certificates" enable row level security;
alter table "public"."chat_drafts" enable row level security;
alter table "public"."chat_group_invites" enable row level security;
alter table "public"."chat_group_join_requests" enable row level security;
alter table "public"."chat_group_members" enable row level security;
alter table "public"."chat_groups" enable row level security;
alter table "public"."chat_poll_votes" enable row level security;
alter table "public"."chat_polls" enable row level security;
alter table "public"."class_sessions" enable row level security;
alter table "public"."cohort_students" enable row level security;
alter table "public"."cohort_timetable_slots" enable row level security;
alter table "public"."cohorts" enable row level security;
alter table "public"."course_completions" enable row level security;
alter table "public"."course_enrollments" enable row level security;
alter table "public"."crash_course_attempts" enable row level security;
alter table "public"."crash_course_enrollments" enable row level security;
alter table "public"."crash_course_lessons" enable row level security;
alter table "public"."crash_courses" enable row level security;
alter table "public"."crash_programs" enable row level security;
alter table "public"."data_migrations" enable row level security;
alter table "public"."direct_messages" enable row level security;
alter table "public"."discussion_replies" enable row level security;
alter table "public"."discussion_threads" enable row level security;
alter table "public"."email_outbox" enable row level security;
alter table "public"."email_templates" enable row level security;
alter table "public"."enrollment_arrangement_history" enable row level security;
alter table "public"."entrance_settings" enable row level security;
alter table "public"."entrance_test_results" enable row level security;
alter table "public"."fee_transactions" enable row level security;
alter table "public"."file_submissions" enable row level security;
alter table "public"."grade_appeals" enable row level security;
alter table "public"."grade_assessments" enable row level security;
alter table "public"."grade_evaluation_settings" enable row level security;
alter table "public"."group_messages" enable row level security;
alter table "public"."helpdesk_messages" enable row level security;
alter table "public"."helpdesk_tickets" enable row level security;
alter table "public"."knock_notification_events" enable row level security;
alter table "public"."learning_memory" enable row level security;
alter table "public"."learning_units" enable row level security;
alter table "public"."message_reactions" enable row level security;
alter table "public"."module_responsibilities" enable row level security;
alter table "public"."newsletter_campaigns" enable row level security;
alter table "public"."newsletter_signup_limits" enable row level security;
alter table "public"."newsletter_subscribers" enable row level security;
alter table "public"."notification_outbox" enable row level security;
alter table "public"."notifications" enable row level security;
alter table "public"."onesignal_devices" enable row level security;
alter table "public"."payment_channels" enable row level security;
alter table "public"."payment_submissions" enable row level security;
alter table "public"."permissions" enable row level security;
alter table "public"."policy_acceptances" enable row level security;
alter table "public"."portal_kv" enable row level security;
alter table "public"."profiles" enable row level security;
alter table "public"."program_applications" enable row level security;
alter table "public"."program_modules" enable row level security;
alter table "public"."programs" enable row level security;
alter table "public"."push_dispatch_token" enable row level security;
alter table "public"."push_subscriptions" enable row level security;
alter table "public"."quiz_attempts" enable row level security;
alter table "public"."quiz_questions" enable row level security;
alter table "public"."quizzes" enable row level security;
alter table "public"."reminder_items" enable row level security;
alter table "public"."reminder_settings" enable row level security;
alter table "public"."role_permissions" enable row level security;
alter table "public"."roles" enable row level security;
alter table "public"."school_policies" enable row level security;
alter table "public"."self_paced_activities" enable row level security;
alter table "public"."self_paced_lessons" enable row level security;
alter table "public"."self_paced_participations" enable row level security;
alter table "public"."self_paced_plans" enable row level security;
alter table "public"."self_paced_progress" enable row level security;
alter table "public"."self_paced_resources" enable row level security;
alter table "public"."self_paced_submissions" enable row level security;
alter table "public"."self_paced_weeks" enable row level security;
alter table "public"."staff_vacancies" enable row level security;
alter table "public"."student_learning_progress" enable row level security;
alter table "public"."study_materials" enable row level security;
alter table "public"."study_plans" enable row level security;
alter table "public"."submissions" enable row level security;
alter table "public"."support_pledges" enable row level security;
alter table "public"."system_settings" enable row level security;
alter table "public"."teacher_course_plans" enable row level security;
alter table "public"."term_report_comments" enable row level security;
alter table "public"."training_materials" enable row level security;
alter table "public"."transparency_reports" enable row level security;
alter table "public"."vacancy_applications" enable row level security;
alter table "public"."website_enquiries" enable row level security;
alter table "public"."welcome_email_templates" enable row level security;
alter table "public"."yearbook_entries" enable row level security;

-- ---------------------------------------------------------------------------
-- Functions
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public._approved_enrollment_to_roster()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if new.status = 'approved' and (tg_op = 'INSERT' or old.status is distinct from 'approved') then
    insert into public.cohort_students (cohort_id, student_id, enrolled_at, enrollment_source, active)
    values (new.cohort_id, new.student_id, now(), 'course_enrollment', true)
    on conflict (cohort_id, student_id) do update
      set active = true, enrolled_at = excluded.enrolled_at,
          enrollment_source = excluded.enrollment_source, completed_at = null;
  end if;
  return new;
end;
$function$;
CREATE OR REPLACE FUNCTION public._attempt_payload(p_attempt_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  att record;
  qz record;
  questions jsonb := '[]'::jsonb;
  qid uuid;
  q record;
  opts jsonb;
  order_ids jsonb;
begin
  select * into att from public.quiz_attempts where id = p_attempt_id;
  if att.id is null then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  select * into qz from public.quizzes where id = att.quiz_id;

  foreach qid in array att.question_order loop
    select * into q from public.quiz_questions where id = qid;
    order_ids := att.option_order -> qid::text;
    if order_ids is not null then
      select jsonb_agg(jsonb_build_object('id', o ->> 'id', 'text', o ->> 'text'))
        into opts
        from jsonb_array_elements(order_ids) oid
        join jsonb_array_elements(q.options) o on (o ->> 'id') = (oid ->> 'id');
    else
      opts := '[]'::jsonb;
    end if;
    questions := questions || jsonb_build_array(jsonb_build_object(
      'id', q.id, 'type', q.type, 'prompt', q.prompt, 'points', q.points,
      'options', coalesce(opts, '[]'::jsonb)
    ));
  end loop;

  return jsonb_build_object(
    'attempt_id', att.id,
    'attempt_no', att.attempt_no,
    'status', att.status,
    'deadline_at', att.deadline_at,
    'server_now', now(),
    'quiz', jsonb_build_object(
      'id', qz.id, 'title', qz.title, 'description', qz.description,
      'time_limit_minutes', qz.time_limit_minutes, 'total_points', qz.total_points,
      'max_attempts', qz.max_attempts, 'pass_mark', qz.pass_mark
    ),
    'questions', questions,
    'answers', att.answers
  );
end;
$function$;
CREATE OR REPLACE FUNCTION public._attendance_standing(p_student_id uuid, p_cohort_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_join_date date;
  v_held integer;
  v_attended integer;
  v_missed jsonb;
  v_arrangement text;
begin
  select learning_arrangement into v_arrangement
  from public.course_enrollments
  where cohort_id = p_cohort_id and student_id = p_student_id
  order by requested_at desc limit 1;

  if v_arrangement = 'self_paced' then
    return jsonb_build_object('sessions_held', 0, 'sessions_attended', 0, 'sessions_missed', 0, 'attendance_percent', null, 'missed', '[]'::jsonb);
  end if;

  select enrolled_at::date into v_join_date
  from public.cohort_students where cohort_id = p_cohort_id and student_id = p_student_id;

  select count(*) into v_held from public.class_sessions s
  where s.cohort_id = p_cohort_id and s.status = 'approved' and s.attendance_required
    and s.session_date >= coalesce(v_join_date, '-infinity'::date)
    and (s.session_date < current_date or (s.session_date = current_date and (s.session_date + s.ends_at) <= now()));

  select count(*) into v_attended from public.class_sessions s
  where s.cohort_id = p_cohort_id and s.status = 'approved' and s.attendance_required
    and s.session_date >= coalesce(v_join_date, '-infinity'::date)
    and (s.session_date < current_date or (s.session_date = current_date and (s.session_date + s.ends_at) <= now()))
    and exists (select 1 from public.attendance a where a.student_id = p_student_id and a.status in ('Present', 'Late')
      and (a.class_session_id = s.id or (a.class_session_id is null and a.cohort_id = s.cohort_id and a.attendance_date = s.session_date)));

  select coalesce(jsonb_agg(jsonb_build_object('session_id', m.id, 'title', m.title, 'session_date', m.session_date) order by m.session_date desc), '[]'::jsonb)
  into v_missed from (
    select s.id, s.title, s.session_date from public.class_sessions s
    where s.cohort_id = p_cohort_id and s.status = 'approved' and s.attendance_required
      and s.session_date >= coalesce(v_join_date, '-infinity'::date)
      and (s.session_date < current_date or (s.session_date = current_date and (s.session_date + s.ends_at) <= now()))
      and not exists (select 1 from public.attendance a where a.student_id = p_student_id and a.status in ('Present', 'Late')
        and (a.class_session_id = s.id or (a.class_session_id is null and a.cohort_id = s.cohort_id and a.attendance_date = s.session_date)))
    order by s.session_date desc limit 10
  ) m;

  return jsonb_build_object('sessions_held', v_held, 'sessions_attended', v_attended, 'sessions_missed', v_held - v_attended,
    'attendance_percent', case when v_held = 0 then null else round(v_attended::numeric / v_held * 100, 2) end, 'missed', v_missed);
end;
$function$;
CREATE OR REPLACE FUNCTION public._blog_payments_touch()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog', 'public'
AS $function$
begin
  new.updated_at := now();
  return new;
end;
$function$;
CREATE OR REPLACE FUNCTION public._claim_push_rows(p_limit integer DEFAULT 25)
 RETURNS TABLE(id uuid, title text, body text, url text, recipient_id uuid, attempts integer)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with candidate as (
    select o.id
    from public.notification_outbox o
    where o.recipient_id is not null
      and (
        o.status = 'queued'
        or (o.status = 'failed' and o.attempts < 5
            and coalesce(o.next_attempt_at, o.created_at) <= now())
        or (o.status = 'sending'
            and coalesce(o.last_attempt_at, o.created_at) < now() - interval '10 minutes')
      )
    order by o.created_at
    limit greatest(1, least(coalesce(p_limit, 25), 50))
    for update skip locked
  )
  update public.notification_outbox o
     set status = 'sending',
         attempts = o.attempts + 1,
         last_attempt_at = now(),
         next_attempt_at = null
    from candidate c
   where o.id = c.id
  returning o.id, o.title, o.body, o.url, o.recipient_id, o.attempts;
$function$;
CREATE OR REPLACE FUNCTION public._confirmed_account_congratulations_trigger()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if old.email_confirmed_at is null and new.email_confirmed_at is not null then
    perform public._queue_account_congratulations(new.id);
  end if;
  return new;
end;
$function$;
CREATE OR REPLACE FUNCTION public._course_enrollment_preview(p_student_id uuid, p_cohort_id uuid, p_check_window boolean DEFAULT true)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  c record;
  roster_count integer := 0;
  active_count integer := 0;
  weekly_hours numeric := 0;
  warnings jsonb := '[]'::jsonb;
  schedule_conflicts jsonb := '[]'::jsonb;
begin
  select c0.*, p.title as program_title into c
  from public.cohorts c0
  join public.programs p on p.id = c0.program_id
  where c0.id = p_cohort_id;

  if c.id is null then
    raise exception 'cohort_not_found' using errcode = 'P0002';
  end if;

  select count(*) into roster_count
  from public.cohort_students cs
  where cs.cohort_id = p_cohort_id and cs.active;

  select count(*) into active_count
  from public.cohort_students cs
  where cs.student_id = p_student_id and cs.active;

  if c.enrollment_status = 'cancelled' then
    warnings := warnings || jsonb_build_array(jsonb_build_object('code', 'course_cancelled', 'blocking', true, 'message', 'This course offering was cancelled.'));
  elsif p_check_window and c.enrollment_status <> 'open' then
    warnings := warnings || jsonb_build_array(jsonb_build_object('code', 'enrollment_closed', 'blocking', true, 'message', 'This course offering is not open for enrolment.'));
  end if;
  if p_check_window and c.enrollment_opens_at is not null and c.enrollment_opens_at > now() then
    warnings := warnings || jsonb_build_array(jsonb_build_object('code', 'enrollment_not_open', 'blocking', true, 'message', 'Enrolment has not opened yet.'));
  end if;
  if p_check_window and c.enrollment_closes_at is not null and c.enrollment_closes_at <= now() then
    warnings := warnings || jsonb_build_array(jsonb_build_object('code', 'enrollment_closed', 'blocking', true, 'message', 'The enrolment deadline has passed.'));
  end if;
  if c.capacity is not null and roster_count >= c.capacity then
    warnings := warnings || jsonb_build_array(jsonb_build_object('code', 'capacity_reached', 'blocking', true, 'message', 'This course offering has reached its capacity.'));
  end if;
  if exists (select 1 from public.cohort_students cs where cs.cohort_id = p_cohort_id and cs.student_id = p_student_id and cs.active) then
    warnings := warnings || jsonb_build_array(jsonb_build_object('code', 'already_enrolled', 'blocking', true, 'message', 'You are already on the approved roster for this course offering.'));
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'code', 'schedule_conflict', 'blocking', true,
    'message', 'An official class session overlaps with an approved course offering.',
    'target_session_id', target_session.id, 'existing_session_id', existing_session.id
  )), '[]'::jsonb) into schedule_conflicts
  from public.class_sessions target_session
  join public.class_sessions existing_session
    on existing_session.id <> target_session.id
   and existing_session.status = 'approved'
   and existing_session.session_date = target_session.session_date
   and target_session.starts_at < existing_session.ends_at
   and target_session.ends_at > existing_session.starts_at
  join public.cohort_students cs on cs.cohort_id = existing_session.cohort_id
    and cs.student_id = p_student_id and cs.active
  where target_session.cohort_id = p_cohort_id
    and target_session.status = 'approved';
  warnings := warnings || schedule_conflicts;

  if active_count >= 3 then
    warnings := warnings || jsonb_build_array(jsonb_build_object(
      'code', 'high_workload', 'blocking', false,
      'message', format('You are already enrolled in %s active course offerings.', active_count),
      'active_course_count', active_count
    ));
  end if;

  select coalesce(round(sum(extract(epoch from (s.ends_at - s.starts_at)) / 3600.0), 2), 0)
    into weekly_hours
  from public.class_sessions s
  where s.cohort_id = p_cohort_id
    and s.status = 'approved'
    and s.session_date >= current_date
    and s.session_date < current_date + 7;

  return jsonb_build_object(
    'cohort_id', c.id,
    'program_id', c.program_id,
    'program_title', c.program_title,
    'capacity', c.capacity,
    'approved_roster_count', roster_count,
    'active_course_count', active_count,
    'allowed', not exists (select 1 from jsonb_array_elements(warnings) w where coalesce((w ->> 'blocking')::boolean, false)),
    'conflicts', coalesce((select jsonb_agg(w ->> 'message') from jsonb_array_elements(warnings) w where coalesce((w ->> 'blocking')::boolean, false)), '[]'::jsonb),
    'warnings', coalesce((select jsonb_agg(w ->> 'message') from jsonb_array_elements(warnings) w where not coalesce((w ->> 'blocking')::boolean, false)), '[]'::jsonb),
    'weekly_hours', weekly_hours
  );
end;
$function$;
CREATE OR REPLACE FUNCTION public._cron_dispatch_push()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_url text := 'https://gatnzfjpuokopqyksqoy.supabase.co/functions/v1/push-send';
  v_token text;
begin
  if not exists (
    select 1 from public.notification_outbox o
    where o.recipient_id is not null
      and (
        o.status = 'queued'
        or (o.status = 'failed' and o.attempts < 5
            and coalesce(o.next_attempt_at, o.created_at) <= now())
        or (o.status = 'sending'
            and coalesce(o.last_attempt_at, o.created_at) < now() - interval '10 minutes')
      )
  ) then
    return;
  end if;

  select token into v_token from public.push_dispatch_token limit 1;
  if v_token is null then
    return;
  end if;

  perform net.http_post(
    url := v_url,
    headers := jsonb_build_object('Content-Type', 'application/json', 'x-push-dispatch', v_token),
    body := jsonb_build_object('action', 'dispatch', 'limit', 25)
  );
end;
$function$;
CREATE OR REPLACE FUNCTION public._cron_dispatch_send_email()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_url text;
  v_secret text;
begin
  -- No-op until both Vault secrets exist (never set from this file).
  if to_regclass('vault.decrypted_secrets') is null then
    return;
  end if;

  select decrypted_secret into v_url from vault.decrypted_secrets where name = 'send_email_dispatch_url' limit 1;
  select decrypted_secret into v_secret from vault.decrypted_secrets where name = 'email_cron_secret' limit 1;

  if v_url is null or v_secret is null then
    return;
  end if;

  if to_regprocedure('net.http_post(text, jsonb, jsonb, jsonb, integer)') is null
     and to_regprocedure('net.http_post(text, jsonb, jsonb, jsonb)') is null then
    return;
  end if;

  perform net.http_post(
    url := v_url,
    headers := jsonb_build_object('Content-Type', 'application/json', 'x-cron-secret', v_secret),
    body := jsonb_build_object('action', 'send')
  );
end;
$function$;
CREATE OR REPLACE FUNCTION public._dispatch_knock_for_notification()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_token text;
begin
  select token into v_token from public.push_dispatch_token limit 1;
  if v_token is null then
    return new;
  end if;
  begin
    perform net.http_post(
      url := 'https://gatnzfjpuokopqyksqoy.supabase.co/functions/v1/knock-dispatch',
      headers := jsonb_build_object('Content-Type', 'application/json', 'x-push-dispatch', v_token),
      body := jsonb_build_object('notification_id', new.id)
    );
  exception when others then
    null;
  end;
  return new;
end;
$function$;
CREATE OR REPLACE FUNCTION public._enqueue_notification_email()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_email text;
  v_name text;
begin
  -- payment_confirmed / payment_rejected already get a dedicated, richer
  -- email (payment_receipt / payment_rejected templates) from
  -- review_payment() below. Enqueueing the generic 'notification' email too
  -- would send the student two emails for one decision.
  if new.kind in ('payment_confirmed', 'payment_rejected') then
    return new;
  end if;

  -- The verified login identity's email, not the self-editable
  -- public.profiles.email column.
  select u.email, coalesce(p.full_name, p.name, '')
    into v_email, v_name
  from auth.users u
  left join public.profiles p on p.id = u.id
  where u.id = new.recipient_id;

  if v_email is not null and length(btrim(v_email)) > 0 then
    perform public.enqueue_email(
      v_email, v_name, 'notification', new.title,
      jsonb_build_object('title', new.title, 'body', new.body, 'entity_type', new.entity_type, 'entity_id', new.entity_id),
      new.recipient_id,
      'notification:' || new.id::text
    );
  end if;

  return new;
end;
$function$;
CREATE OR REPLACE FUNCTION public._grade_quiz_attempt(p_attempt_id uuid, p_new_status text DEFAULT NULL::text, p_force boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  att record;
  qz record;
  q record;
  total numeric := 0;
  earned numeric := 0;
  v_results jsonb := '{}'::jsonb;
  ans jsonb;
  right_picked int;
  wrong_picked int;
  num_right int;
  pts numeric;
  is_correct boolean;
  override_pts numeric;
  had_override boolean;
  norm_ans text;
  matched boolean;
  accepted text;
  pct numeric;
begin
  select * into att from public.quiz_attempts where id = p_attempt_id for update;
  if att.id is null then
    raise exception 'not_found' using errcode = 'P0002';
  end if;

  if p_new_status is not null then
    if att.status <> 'in_progress' then
      return jsonb_build_object(
        'score', att.score, 'max_score', att.max_score, 'percent', att.percent,
        'passed', att.passed, 'status', att.status, 'submitted_at', att.submitted_at
      );
    end if;
  else
    if not p_force or att.status = 'in_progress' then
      raise exception 'not_submitted' using errcode = 'P0001';
    end if;
  end if;

  select * into qz from public.quizzes where id = att.quiz_id;

  for q in select * from public.quiz_questions where id = any(att.question_order) loop
    total := total + q.points;
    ans := att.answers -> q.id::text;
    had_override := p_force and att.results is not null
      and (att.results -> q.id::text ->> 'override') = 'true';
    if had_override then
      override_pts := (att.results -> q.id::text ->> 'points')::numeric;
    else
      override_pts := null;
    end if;

    if override_pts is not null then
      pts := override_pts;
      is_correct := pts >= q.points;
    elsif ans is null then
      pts := 0;
      is_correct := false;
    elsif q.type = 'single' then
      is_correct := jsonb_typeof(ans) = 'string' and (q.correct ->> 0) = (ans #>> '{}');
      pts := case when is_correct then q.points else 0 end;
    elsif q.type = 'true_false' then
      is_correct := jsonb_typeof(ans) = 'boolean' and (q.correct -> 0) = ans;
      pts := case when is_correct then q.points else 0 end;
    elsif q.type = 'multi' then
      num_right := jsonb_array_length(q.correct);
      if jsonb_typeof(ans) = 'array' then
        select count(*) into right_picked from jsonb_array_elements_text(ans) a
          where a.value in (select jsonb_array_elements_text(q.correct));
        select count(*) into wrong_picked from jsonb_array_elements_text(ans) a
          where a.value not in (select jsonb_array_elements_text(q.correct));
      else
        right_picked := 0;
        wrong_picked := 0;
      end if;
      pts := round(q.points * greatest(0, (right_picked - wrong_picked))::numeric / greatest(num_right, 1), 4);
      is_correct := pts >= q.points;
    elsif q.type = 'short' then
      norm_ans := lower(btrim(regexp_replace(coalesce(ans #>> '{}', ''), '\s+', ' ', 'g')));
      matched := false;
      for accepted in select jsonb_array_elements_text(q.correct) loop
        if norm_ans <> '' and lower(btrim(regexp_replace(accepted, '\s+', ' ', 'g'))) = norm_ans then
          matched := true;
        end if;
      end loop;
      is_correct := matched;
      pts := case when matched then q.points else 0 end;
    else
      pts := 0;
      is_correct := false;
    end if;

    pts := round(pts, 2);
    v_results := v_results || jsonb_build_object(
      q.id::text, jsonb_build_object('correct', is_correct, 'points', pts, 'override', override_pts is not null)
    );
    earned := earned + pts;
  end loop;

  pct := case when total > 0 then round(earned / total * 100, 2) else 0 end;

  update public.quiz_attempts set
    results = v_results,
    score = round(earned, 2),
    max_score = total,
    percent = pct,
    passed = pct >= qz.pass_mark,
    status = coalesce(p_new_status, status),
    submitted_at = case when p_new_status is not null then coalesce(submitted_at, now()) else submitted_at end
  where id = p_attempt_id;

  return jsonb_build_object(
    'score', round(earned, 2), 'max_score', total, 'percent', pct,
    'passed', pct >= qz.pass_mark, 'status', coalesce(p_new_status, att.status),
    'submitted_at', coalesce(att.submitted_at, now())
  );
end;
$function$;
CREATE OR REPLACE FUNCTION public._normalize_training_material_status()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog', 'public'
AS $function$
begin
  if new.status = 'pending' then new.status := 'submitted'; end if;
  return new;
end;
$function$;
CREATE OR REPLACE FUNCTION public._notify_academic_status()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  entity_kind text := tg_argv[0];
  recipient uuid;
begin
  if not (tg_op = 'INSERT' or new.status is distinct from old.status) then
    return new;
  end if;
  if new.status = 'submitted' then
    insert into public.notifications (recipient_id, kind, title, body, entity_type, entity_id)
    select p.id, 'approval_submission', 'Academic item submitted for review',
      'A ' || replace(entity_kind, '_', ' ') || ' is ready for review.', entity_kind, new.id
    from public.profiles p
    where p.status = 'Active'
      and (p.role = 'Super Admin' or exists (
        select 1 from public.role_permissions rp
        where rp.role = p.role
          and rp.permission = case when entity_kind = 'training_material' then 'materials.approve' else 'academic_plans.approve' end
      ));
  elsif new.status in ('approved', 'rejected', 'revision_requested') then
    recipient := case entity_kind
      when 'enrollment' then nullif(to_jsonb(new) ->> 'student_id', '')::uuid
      when 'course_plan' then nullif(to_jsonb(new) ->> 'teacher_id', '')::uuid
      when 'class_session' then nullif(to_jsonb(new) ->> 'teacher_id', '')::uuid
      else nullif(to_jsonb(new) ->> 'created_by', '')::uuid
    end;
    if recipient is not null then
      insert into public.notifications (recipient_id, kind, title, body, entity_type, entity_id)
      values (
        recipient, 'approval_decision', 'Academic item ' || replace(new.status, '_', ' '),
        coalesce(nullif(new.revision_note, ''), 'Your ' || replace(entity_kind, '_', ' ') || ' was ' || replace(new.status, '_', ' ') || '.'),
        entity_kind, new.id
      );
    end if;
  end if;
  return new;
end;
$function$;
CREATE OR REPLACE FUNCTION public._notify_attendance()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_session_title text;
  v_cohort_teacher uuid;
  v_required numeric;
  v_student_name text;
  v_standing jsonb;
  v_held integer;
  v_attended integer;
  v_pct numeric;
  v_student_last_warning timestamptz;
begin
  if new.status = 'Absent' and (tg_op = 'INSERT' or old.status is distinct from 'Absent') then
    -- Keep the original dedupe key: entity_type='attendance', entity_id =
    -- the attendance row's own id. Now that attendance is written via
    -- upsert on (cohort_id, student_id, attendance_date) instead of
    -- delete+reinsert, the row id is stable across repeated writes for the
    -- same date, so this key alone already prevents double notification on
    -- a re-save. Only the session-title lookup needs widening: resolve the
    -- class to name in the message by cohort+date when class_session_id is
    -- null (matching the resolution already used by my_course_status),
    -- instead of relying on new.class_session_id being set directly.
    if new.class_session_id is not null then
      select title into v_session_title from public.class_sessions where id = new.class_session_id;
    else
      select title into v_session_title
      from public.class_sessions
      where cohort_id = new.cohort_id and session_date = new.attendance_date and status = 'approved'
      order by starts_at
      limit 1;
    end if;

    if not exists (
      select 1 from public.notifications
      where recipient_id = new.student_id and kind = 'attendance_missed'
        and entity_type = 'attendance' and entity_id = new.id
    ) then
      insert into public.notifications (recipient_id, kind, title, body, entity_type, entity_id)
      values (
        new.student_id, 'attendance_missed', 'Missed class',
        'You were marked absent for ' || coalesce(v_session_title, 'a class') || ' on ' || new.attendance_date::text || '.',
        'attendance', new.id
      );
    end if;
  end if;

  select c.teacher_id, p.required_attendance_percent into v_cohort_teacher, v_required
  from public.cohorts c join public.programs p on p.id = c.program_id
  where c.id = new.cohort_id;

  v_standing := public._attendance_standing(new.student_id, new.cohort_id);
  v_held := (v_standing ->> 'sessions_held')::integer;
  v_attended := (v_standing ->> 'sessions_attended')::integer;

  if v_held >= 3 then
    v_pct := round(v_attended::numeric / v_held * 100, 2);
    if v_pct < v_required then
      select max(created_at) into v_student_last_warning
      from public.notifications
      where recipient_id = new.student_id and kind = 'attendance_warning' and entity_type = 'cohort' and entity_id = new.cohort_id;

      -- Unchanged from the applied migration: both the student's own copy
      -- and the teacher's copy share this single 7-day cooldown keyed on
      -- (student, cohort), matching the already-passing contract assertion
      -- for this behavior. The only change here is naming the student in
      -- the teacher-facing body.
      if v_student_last_warning is null or v_student_last_warning < now() - interval '7 days' then
        insert into public.notifications (recipient_id, kind, title, body, entity_type, entity_id)
        values (
          new.student_id, 'attendance_warning', 'Attendance below requirement',
          'Your attendance is ' || v_pct::text || '%, below the required ' || v_required::text || '% for this course.',
          'cohort', new.cohort_id
        );
        if v_cohort_teacher is not null then
          select full_name into v_student_name from public.profiles where id = new.student_id;
          insert into public.notifications (recipient_id, kind, title, body, entity_type, entity_id)
          values (
            v_cohort_teacher, 'attendance_warning', 'Student attendance below requirement',
            coalesce(v_student_name, 'A student') || '''s attendance is ' || v_pct::text || '%, below the required ' || v_required::text || '% for this course.',
            'cohort', new.cohort_id
          );
        end if;
      end if;
    end if;
  end if;

  return new;
end;
$function$;
CREATE OR REPLACE FUNCTION public._notify_direct_message()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_name text;
begin
  select coalesce(nullif(btrim(p.full_name),''), nullif(btrim(p.name),''), 'A portal user') into v_name from public.profiles p where p.id = new.sender_id;
  insert into public.notifications (recipient_id, user_id, kind, title, body, entity_type, entity_id, url, read)
  values (new.receiver_id, new.receiver_id, 'direct_message', 'New message from ' || coalesce(v_name,'a portal user'), left(new.body,200), 'direct_message', new.id, '#messages', false);
  return new;
exception when others then
  return new;
end $function$;
CREATE OR REPLACE FUNCTION public._notify_group_message()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_group text;
  v_name text;
begin
  select coalesce(nullif(btrim(g.name), ''), 'group chat') into v_group
  from public.chat_groups g where g.id = new.group_id;
  select coalesce(nullif(btrim(p.full_name), ''), nullif(btrim(p.name), ''), 'A member') into v_name
  from public.profiles p where p.id = new.sender_id;

  insert into public.notifications (recipient_id, user_id, kind, title, body, entity_type, entity_id, url, read)
  select m.user_id, m.user_id, 'group_message',
         coalesce(v_name, 'A member') || ' in ' || coalesce(v_group, 'group chat'),
         left(coalesce(nullif(new.body, ''), '[voice note]'), 200),
         'chat_group', new.group_id, '#messages', false
  from public.chat_group_members m
  where m.group_id = new.group_id and m.user_id <> new.sender_id;
  return new;
exception when others then
  return new;
end
$function$;
CREATE OR REPLACE FUNCTION public._notify_schedule_updated()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if new.status = 'approved' and old.status = 'approved' and new.session_date >= current_date and (
    new.session_date is distinct from old.session_date
    or new.starts_at is distinct from old.starts_at
    or new.ends_at is distinct from old.ends_at
    or new.room is distinct from old.room
  ) then
    insert into public.notifications (recipient_id, kind, title, body, entity_type, entity_id)
    select cs.student_id, 'schedule_updated', 'Class schedule updated',
      'The schedule for "' || new.title || '" changed to ' || new.session_date::text || ' ' || new.starts_at::text || '-' || new.ends_at::text
        || case when coalesce(new.room, '') <> '' then ' in ' || new.room else '' end || '.',
      'class_session', new.id
    from public.cohort_students cs
    where cs.cohort_id = new.cohort_id and cs.active;
  end if;
  return new;
end;
$function$;
CREATE OR REPLACE FUNCTION public._profile_congratulations_trigger()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if TG_OP = 'UPDATE' then
    if new.status is not distinct from old.status then return new; end if;
    if new.status <> 'Active' then return new; end if;
  end if;
  perform public._queue_account_congratulations(new.id);
  return new;
end;
$function$;
CREATE OR REPLACE FUNCTION public._queue_account_congratulations(p_user_id uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_profile public.profiles%rowtype;
  v_email text; v_event text; v_audience text; v_subject text; v_body text;
  v_template_subject text; v_template_body text; v_event_line text; v_name text; v_key text; v_id uuid;
begin
  select * into v_profile from public.profiles where id = p_user_id;
  if not found or v_profile.status not in ('Pending Approval','Active') then return null; end if;
  select email into v_email from auth.users where id = p_user_id and email_confirmed_at is not null;
  if v_email is null then return null; end if;
  v_event := case when v_profile.status = 'Active' then 'approved' else 'registered' end;
  v_key := 'account-congratulations:' || v_event || ':' || p_user_id::text;
  v_name := coalesce(nullif(btrim(v_profile.full_name),''), nullif(btrim(v_profile.name),''), 'there');
  v_audience := case when v_profile.role = 'Student' then 'student' else 'staff' end;
  v_event_line := case when v_event = 'approved' then 'Your AFRICA OF HOPE account has been approved and is ready to use.' else 'Your account has been created and is waiting for review.' end;
  select t.subject, t.body into v_template_subject, v_template_body from public.welcome_email_templates t where t.audience = v_audience;
  if v_template_body is not null and btrim(v_template_body) <> '' then
    v_subject := replace(replace(v_template_subject,'{{name}}',v_name),'{{event_line}}',v_event_line);
    v_body := replace(replace(v_template_body,'{{name}}',v_name),'{{event_line}}',v_event_line);
  elsif v_event = 'approved' then
    v_subject := 'Congratulations — your AFRICA OF HOPE account is approved';
    v_body := 'Congratulations, ' || v_name || E'!\n\nYour AFRICA OF HOPE account has been approved. Sign in with your registered email to view the services and next steps available to your account.\n\nIf you are a learner, please review your programme and payment information in the portal or contact admissions for guidance. Account approval does not by itself confirm payment, course completion or certification.\n\nWe look forward to supporting your journey.\nAFRICA OF HOPE — Empowering People. Transforming Communities. Inspiring Hope.';
  else
    v_subject := 'Welcome to AFRICA OF HOPE — registration received';
    v_body := 'Congratulations on taking the first step, ' || v_name || E'!\n\nYour AFRICA OF HOPE registration has been received. Your application is pending review; this message is not an admission or account approval. Our team will notify you when a decision is made.\n\nPlease keep your registered email available and contact admissions if you need help.\n\nThank you for choosing to grow with us.\nAFRICA OF HOPE — Empowering People. Transforming Communities. Inspiring Hope.';
  end if;
  v_id := public.enqueue_email(v_email, coalesce(v_profile.full_name, v_profile.name, ''), case when v_event = 'approved' then 'account_approved' else 'account_registration' end, v_subject, jsonb_build_object('body', v_body, 'event', v_event, 'audience', v_audience), p_user_id, v_key);
  if v_id is null then select id into v_id from public.email_outbox where dedupe_key = v_key; end if;
  return v_id;
end $function$;
CREATE OR REPLACE FUNCTION public._queue_push_for_notification()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_recipient uuid := coalesce(new.recipient_id, new.user_id);
  v_queued boolean := false;
begin
  if coalesce(new.push_suppressed, false) then
    return new;
  end if;

  if v_recipient is null then
    return new;
  end if;

  insert into public.notification_outbox
    (idempotency_key, title, body, url, audience, recipient_id, notification_id, status)
  values (
    'notif:' || new.id::text,
    coalesce(nullif(btrim(coalesce(new.title, '')), ''), 'AFRICA OF HOPE'),
    coalesce(nullif(btrim(coalesce(new.body, '')), ''), 'You have a new update in the portal.'),
    coalesce(nullif(btrim(coalesce(new.url, '')), ''), '#notifications'),
    'user',
    v_recipient,
    new.id,
    'queued'
  )
  on conflict (notification_id) do nothing;
  v_queued := found;

  if v_queued then
    perform public._cron_dispatch_push();
  end if;

  return new;
exception when others then
  return new;
end;
$function$;
CREATE OR REPLACE FUNCTION public._quiz_questions_totals()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  qid uuid;
begin
  qid := coalesce(new.quiz_id, old.quiz_id);
  update public.quizzes set
    question_count = (select count(*) from public.quiz_questions where quiz_id = qid),
    total_points = (select coalesce(sum(points), 0) from public.quiz_questions where quiz_id = qid),
    updated_at = now()
  where id = qid;
  return null;
end;
$function$;
CREATE OR REPLACE FUNCTION public._quiz_questions_validate()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  opt_count int;
  ids text[];
begin
  if new.type not in ('single', 'multi', 'true_false', 'short') then
    raise exception 'invalid_type' using errcode = 'P0001';
  end if;

  if new.type in ('single', 'multi') then
    opt_count := jsonb_array_length(new.options);
    if opt_count < 2 or opt_count > 10 then
      raise exception 'options_count' using errcode = 'P0001';
    end if;
    if exists (
      select 1 from jsonb_array_elements(new.options) o
      where (o ->> 'id') is null or length(o ->> 'id') = 0
        or (o ->> 'text') is null or length(o ->> 'text') = 0 or length(o ->> 'text') > 500
    ) then
      raise exception 'invalid_option' using errcode = 'P0001';
    end if;
    select array_agg(o ->> 'id') into ids from jsonb_array_elements(new.options) o;
    if array_length(ids, 1) <> (select count(distinct x) from unnest(ids) x) then
      raise exception 'duplicate_option_id' using errcode = 'P0001';
    end if;
  elsif new.options is distinct from '[]'::jsonb then
    raise exception 'options_not_allowed' using errcode = 'P0001';
  end if;

  if new.type = 'single' then
    if jsonb_array_length(new.correct) <> 1
      or not exists (select 1 from jsonb_array_elements(new.options) o where (o ->> 'id') = (new.correct ->> 0))
    then
      raise exception 'invalid_correct' using errcode = 'P0001';
    end if;
  elsif new.type = 'multi' then
    if jsonb_array_length(new.correct) < 1 then
      raise exception 'invalid_correct' using errcode = 'P0001';
    end if;
    if exists (
      select 1 from jsonb_array_elements_text(new.correct) c
      where not exists (select 1 from jsonb_array_elements(new.options) o where (o ->> 'id') = c.value)
    ) then
      raise exception 'invalid_correct' using errcode = 'P0001';
    end if;
  elsif new.type = 'true_false' then
    if jsonb_array_length(new.correct) <> 1 or jsonb_typeof(new.correct -> 0) <> 'boolean' then
      raise exception 'invalid_correct' using errcode = 'P0001';
    end if;
  elsif new.type = 'short' then
    if jsonb_array_length(new.correct) < 1 or jsonb_array_length(new.correct) > 20 then
      raise exception 'invalid_correct' using errcode = 'P0001';
    end if;
    if exists (
      select 1 from jsonb_array_elements_text(new.correct) c
      where length(btrim(c.value)) = 0 or length(c.value) > 500
    ) then
      raise exception 'invalid_correct' using errcode = 'P0001';
    end if;
  end if;

  if new.points <= 0 or new.points > 100 then
    raise exception 'invalid_points' using errcode = 'P0001';
  end if;

  return new;
end;
$function$;
CREATE OR REPLACE FUNCTION public._quizzes_touch()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog', 'public'
AS $function$
begin
  new.updated_at := now();
  return new;
end;
$function$;
CREATE OR REPLACE FUNCTION public._recompute_cohort_progress(p_cohort_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  r record;
begin
  if p_cohort_id is null then
    return;
  end if;
  -- Stable order keeps lock acquisition consistent across sessions.
  for r in select id from public.course_enrollments where cohort_id = p_cohort_id order by id loop
    perform public._recompute_enrollment_progress(r.id);
  end loop;
end;
$function$;
CREATE OR REPLACE FUNCTION public._recompute_course_progress()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_enrollment uuid;
begin
  select id into v_enrollment from public.course_enrollments
  where cohort_id = coalesce(new.cohort_id, old.cohort_id)
    and student_id = coalesce(new.student_id, old.student_id);
  if v_enrollment is not null then
    perform public._recompute_enrollment_progress(v_enrollment);
  end if;
  -- A row moved to another student or cohort also refreshes the old pair.
  if tg_op = 'UPDATE' and (old.cohort_id, old.student_id) is distinct from (new.cohort_id, new.student_id) then
    select id into v_enrollment from public.course_enrollments
    where cohort_id = old.cohort_id and student_id = old.student_id;
    if v_enrollment is not null then
      perform public._recompute_enrollment_progress(v_enrollment);
    end if;
  end if;
  return coalesce(new, old);
end;
$function$;
CREATE OR REPLACE FUNCTION public._recompute_enrollment_progress(p_enrollment_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_enrollment public.course_enrollments%rowtype;
  v_total integer;
  v_completed integer;
  v_pct numeric;
  v_status text;
  v_closed boolean;
begin
  -- Lock first. Under READ COMMITTED the counts below take a new snapshot
  -- after the lock is granted, so they see every committed progress row.
  select * into v_enrollment from public.course_enrollments where id = p_enrollment_id for update;
  if v_enrollment.id is null then
    return;
  end if;

  select count(*) into v_total
  from public.learning_units u where u.cohort_id = v_enrollment.cohort_id and u.status = 'approved';

  select count(*) into v_completed
  from public.student_learning_progress p
  join public.learning_units u on u.id = p.learning_unit_id
  where p.student_id = v_enrollment.student_id and p.cohort_id = v_enrollment.cohort_id
    and p.status = 'completed' and u.status = 'approved';

  v_pct := case when v_total = 0 then 0 else round(v_completed::numeric / v_total * 100, 2) end;
  v_status := case
    when v_total > 0 and v_completed >= v_total then 'completed_pending_review'
    when v_completed > 0 then 'in_progress'
    else 'not_started'
  end;

  v_closed := exists (
    select 1 from public.notifications n
    where n.recipient_id = v_enrollment.student_id and n.kind = 'course_window_closed'
      and n.entity_type = 'enrollment' and n.entity_id = v_enrollment.id
  );

  if v_closed or v_enrollment.completion_status in ('completed', 'incomplete', 'withdrawn', 'cancelled') then
    v_status := v_enrollment.completion_status;
  end if;

  if v_enrollment.progress_percent is distinct from v_pct
     or v_enrollment.completion_status is distinct from v_status then
    update public.course_enrollments
    set progress_percent = v_pct, completion_status = v_status
    where id = v_enrollment.id;
  end if;
end;
$function$;
CREATE OR REPLACE FUNCTION public._recompute_progress_on_unit_change()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_cohort uuid := coalesce(new.cohort_id, old.cohort_id);
begin
  perform public._recompute_cohort_progress(v_cohort);
  return coalesce(new, old);
end;
$function$;
CREATE OR REPLACE FUNCTION public._record_approval_event()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  entity_kind text := tg_argv[0];
begin
  if tg_op = 'INSERT' or new.status is distinct from old.status then
    insert into public.approval_events (entity_type, entity_id, action, actor_id, note, snapshot)
    values (entity_kind, new.id, new.status, auth.uid(), coalesce(new.revision_note, ''), to_jsonb(new));
  end if;
  return new;
end;
$function$;
CREATE OR REPLACE FUNCTION public._touch_academic_row()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog', 'public'
AS $function$
begin
  new.updated_at := now();
  return new;
end;
$function$;
CREATE OR REPLACE FUNCTION public._touch_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
begin
  new.updated_at = now();
  return new;
end;
$function$;
CREATE OR REPLACE FUNCTION public._validate_class_session()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not exists (
    select 1 from public.profiles p where p.id = new.teacher_id and p.role = 'Teacher' and p.status = 'Active'
  ) then
    raise exception 'active_teacher_required' using errcode = 'P0001';
  end if;
  if new.status in ('cancelled', 'rejected') then
    return new;
  end if;
  if exists (
    select 1 from public.class_sessions s
    where s.id <> coalesce(new.id, gen_random_uuid())
      and s.status = 'approved'
      and s.session_date = new.session_date
      and new.starts_at < s.ends_at and new.ends_at > s.starts_at
      and (s.teacher_id = new.teacher_id or s.cohort_id = new.cohort_id)
  ) then
    raise exception 'class_session_schedule_conflict' using errcode = 'P0001';
  end if;
  if new.learning_unit_id is not null and not exists (
    select 1 from public.learning_units u
    where u.id = new.learning_unit_id and (u.cohort_id is null or u.cohort_id = new.cohort_id)
  ) then
    raise exception 'class_session_learning_unit_mismatch' using errcode = 'P0001';
  end if;
  return new;
end;
$function$;
CREATE OR REPLACE FUNCTION public._validate_learning_unit_approval()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  assignment_cohort uuid;
  assignment_weight numeric;
  quiz_found uuid;
  quiz_cohort uuid;
  quiz_program uuid;
  quiz_weight numeric;
  quiz_status text;
begin
  if new.status <> 'approved' then
    return new;
  end if;

  if new.cohort_id is null then
    raise exception 'approved_learning_unit_requires_cohort' using errcode = 'P0001';
  end if;
  if not exists (
    select 1 from public.cohorts c where c.id = new.cohort_id and c.program_id = new.program_id
  ) then
    raise exception 'learning_unit_cohort_program_mismatch' using errcode = 'P0001';
  end if;
  if new.quiz_id is null or new.classwork_assignment_id is null then
    raise exception 'approved_learning_unit_requires_quiz_and_classwork' using errcode = 'P0001';
  end if;

  select cohort_id, grade_weight into assignment_cohort, assignment_weight
  from public.assignments where id = new.classwork_assignment_id;
  select id, cohort_id, program_id, grade_weight, status into quiz_found, quiz_cohort, quiz_program, quiz_weight, quiz_status
  from public.quizzes where id = new.quiz_id;

  if assignment_cohort is null or quiz_found is null then
    raise exception 'approved_learning_unit_components_not_found' using errcode = 'P0002';
  end if;
  if assignment_weight <= 0 or quiz_weight <= 0 then
    raise exception 'approved_learning_unit_components_require_grade_weight' using errcode = 'P0001';
  end if;
  if quiz_status <> 'published' then
    raise exception 'approved_learning_unit_requires_published_quiz' using errcode = 'P0001';
  end if;
  if assignment_cohort <> new.cohort_id then
    raise exception 'learning_unit_assignment_cohort_mismatch' using errcode = 'P0001';
  end if;
  if quiz_cohort is not null and quiz_cohort <> new.cohort_id then
    raise exception 'learning_unit_quiz_cohort_mismatch' using errcode = 'P0001';
  end if;
  if quiz_cohort is null and quiz_program <> new.program_id then
    raise exception 'learning_unit_quiz_program_mismatch' using errcode = 'P0001';
  end if;

  return new;
end;
$function$;
CREATE OR REPLACE FUNCTION public._validate_learning_unit_component()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  u record;
begin
  if tg_table_name = 'assignments' and new.learning_unit_id is not null then
    select * into u from public.learning_units where id = new.learning_unit_id;
    if u.id is null then raise exception 'learning_unit_not_found' using errcode = 'P0002'; end if;
    if u.cohort_id is not null and new.cohort_id <> u.cohort_id then
      raise exception 'learning_unit_assignment_cohort_mismatch' using errcode = 'P0001';
    end if;
    if u.status = 'approved' and new.grade_weight <= 0 then
      raise exception 'approved_learning_unit_components_require_grade_weight' using errcode = 'P0001';
    end if;
  elsif tg_table_name = 'quizzes' and new.learning_unit_id is not null then
    select * into u from public.learning_units where id = new.learning_unit_id;
    if u.id is null then raise exception 'learning_unit_not_found' using errcode = 'P0002'; end if;
    if u.cohort_id is not null and new.cohort_id is not null and new.cohort_id <> u.cohort_id then
      raise exception 'learning_unit_quiz_cohort_mismatch' using errcode = 'P0001';
    end if;
    if new.cohort_id is null and new.program_id <> u.program_id then
      raise exception 'learning_unit_quiz_program_mismatch' using errcode = 'P0001';
    end if;
    if u.status = 'approved' and new.grade_weight <= 0 then
      raise exception 'approved_learning_unit_components_require_grade_weight' using errcode = 'P0001';
    end if;
  end if;
  return new;
end;
$function$;
CREATE OR REPLACE FUNCTION public._validate_student_learning_progress()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_unit_status text;
  v_unit_available timestamptz;
  v_cohort_end date;
begin
  if auth.uid() is null then
    -- Service-role/maintenance writes (admin tooling, backfills, scripted
    -- fixes) are not subject to the student-facing availability/window gate.
    return new;
  end if;

  if public.has_permission('academic_plans.approve') or public.is_cohort_teacher(new.cohort_id) then
    return new;
  end if;

  select status, available_from into v_unit_status, v_unit_available
  from public.learning_units where id = new.learning_unit_id;
  if v_unit_status is distinct from 'approved' or (v_unit_available is not null and v_unit_available > now()) then
    raise exception 'unit_not_available' using errcode = 'P0001';
  end if;

  select end_date into v_cohort_end from public.cohorts where id = new.cohort_id;
  if v_cohort_end is not null and now()::date > v_cohort_end then
    raise exception 'course_window_closed' using errcode = 'P0001';
  end if;

  return new;
end;
$function$;
CREATE OR REPLACE FUNCTION public.adjust_quiz_answer_points(p_attempt_id uuid, p_question_id uuid, p_points numeric)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  att record;
  q record;
  qz record;
  clamped numeric;
  new_results jsonb;
  earned numeric := 0;
  pct numeric;
  key text;
  val jsonb;
begin
  select * into att from public.quiz_attempts where id = p_attempt_id for update;
  if att.id is null then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  if not public.can_manage_quiz(att.quiz_id) then
    raise exception 'forbidden' using errcode = 'P0001';
  end if;
  if att.status = 'in_progress' then
    raise exception 'not_submitted' using errcode = 'P0001';
  end if;
  if not (p_question_id = any(att.question_order)) then
    raise exception 'invalid_question' using errcode = 'P0001';
  end if;

  select * into q from public.quiz_questions where id = p_question_id;
  clamped := greatest(0, least(p_points, q.points));

  new_results := coalesce(att.results, '{}'::jsonb) || jsonb_build_object(
    p_question_id::text, jsonb_build_object('correct', clamped >= q.points, 'points', round(clamped, 2), 'override', true)
  );

  for key, val in select * from jsonb_each(new_results) loop
    earned := earned + coalesce((val ->> 'points')::numeric, 0);
  end loop;

  select * into qz from public.quizzes where id = att.quiz_id;
  pct := case when att.max_score > 0 then round(earned / att.max_score * 100, 2) else 0 end;

  update public.quiz_attempts set
    results = new_results, score = round(earned, 2), percent = pct, passed = pct >= qz.pass_mark
  where id = p_attempt_id;

  return jsonb_build_object('score', round(earned, 2), 'percent', pct, 'passed', pct >= qz.pass_mark);
end;
$function$;
CREATE OR REPLACE FUNCTION public.announcement_visible_to_me(p_announcement_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (
    select 1
    from public.announcements a
    left join public.profiles p on p.id = auth.uid()
    where a.id = p_announcement_id
      and a.status in ('published', 'scheduled')
      and coalesce(a.scheduled_at, a.published_date::timestamptz, now()) <= now()
      and (a.expires_at is null or a.expires_at > now())
      and (
        a.audience = 'public'
        or (a.audience = 'all' and p.id is not null)
        or (a.audience = 'students' and p.id is not null and p.role = 'Student')
        or (a.audience = 'teachers' and p.id is not null and p.role = 'Teacher')
      )
  );
$function$;
CREATE OR REPLACE FUNCTION public.app_integration_resolve(p_app_slug text, p_manifest_id text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'vault'
AS $function$
      DECLARE
        r       record;
        result  jsonb := '{}'::jsonb;
        kv      record;
        decrypted text;
      BEGIN
        SELECT public_values, secret_refs
          INTO r
          FROM public.app_integrations
          WHERE app_slug = p_app_slug AND manifest_id = p_manifest_id;

        IF NOT FOUND THEN
          RETURN NULL;
        END IF;

        result := COALESCE(r.public_values, '{}'::jsonb);

        FOR kv IN SELECT key, value FROM jsonb_each_text(COALESCE(r.secret_refs, '{}'::jsonb))
        LOOP
          SELECT decrypted_secret INTO decrypted
            FROM vault.decrypted_secrets
            WHERE id = kv.value::uuid;
          IF decrypted IS NOT NULL THEN
            result := result || jsonb_build_object(kv.key, decrypted);
          END IF;
        END LOOP;

        RETURN result;
      END;
      $function$;
CREATE OR REPLACE FUNCTION public.app_integration_take(p_manifest_id text, p_person text, p_anon boolean DEFAULT false, p_app_slug text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
      DECLARE
        v_day          date := (now() AT TIME ZONE 'utc')::date;
        v_limits       jsonb;
        v_on           boolean := false;
        v_person_limit int := 0;
        v_app_limit    int := 0;
        v_person_count int := 0;
        v_app_count    int := 0;
        v_app_refused  int := 0;
        v_person_full  boolean := false;
        v_app_full     boolean := false;
        v_ok           boolean := true;
        v_crossed      text := NULL;
        v_share        int;
      BEGIN
        SELECT i.policy -> 'limits' INTO v_limits
          FROM public.app_integrations i
         WHERE i.manifest_id = p_manifest_id
           AND (p_app_slug IS NULL OR i.app_slug = p_app_slug)
           AND jsonb_typeof(i.policy) = 'object'
         ORDER BY i.updated_at DESC
         LIMIT 1;

        IF jsonb_typeof(v_limits) = 'object' THEN
          v_on := CASE WHEN jsonb_typeof(v_limits -> 'on') = 'boolean' THEN (v_limits ->> 'on')::boolean ELSE true END;
          v_app_limit := CASE WHEN jsonb_typeof(v_limits -> 'app') = 'number'
            THEN greatest(0, least(1000000, floor((v_limits ->> 'app')::numeric)))::int ELSE 0 END;
          v_person_limit := CASE WHEN jsonb_typeof(v_limits -> 'perPerson') = 'number'
            THEN greatest(0, least(1000000, floor((v_limits ->> 'perPerson')::numeric)))::int ELSE 0 END;
          IF p_anon AND jsonb_typeof(v_limits -> 'perAnonPerson') = 'number' THEN
            v_person_limit := greatest(0, least(1000000, floor((v_limits ->> 'perAnonPerson')::numeric)))::int;
          END IF;
        END IF;

        INSERT INTO public.app_integration_usage (day, manifest_id, person)
        VALUES (v_day, p_manifest_id, '*')
        ON CONFLICT (day, manifest_id, person) DO NOTHING;
        IF p_person IS NOT NULL THEN
          INSERT INTO public.app_integration_usage (day, manifest_id, person, anon)
          VALUES (v_day, p_manifest_id, p_person, coalesce(p_anon, false))
          ON CONFLICT (day, manifest_id, person) DO NOTHING;
        END IF;

        -- Lock both rows in one fixed order: two calls at once can never both pass a limit.
        PERFORM 1 FROM public.app_integration_usage u
         WHERE u.day = v_day AND u.manifest_id = p_manifest_id
           AND u.person IN ('*', coalesce(p_person, '*'))
         ORDER BY u.person
         FOR UPDATE;

        SELECT u.count, u.refused INTO v_app_count, v_app_refused
          FROM public.app_integration_usage u
         WHERE u.day = v_day AND u.manifest_id = p_manifest_id AND u.person = '*';
        IF p_person IS NOT NULL THEN
          SELECT u.count INTO v_person_count
            FROM public.app_integration_usage u
           WHERE u.day = v_day AND u.manifest_id = p_manifest_id AND u.person = p_person;
        END IF;

        IF v_on THEN
          v_person_full := p_person IS NOT NULL AND v_person_limit > 0 AND v_person_count >= v_person_limit;
          v_app_full := v_app_limit > 0 AND v_app_count >= v_app_limit;
          v_ok := NOT (v_person_full OR v_app_full);
        END IF;

        IF v_ok THEN
          UPDATE public.app_integration_usage SET count = count + 1
           WHERE day = v_day AND manifest_id = p_manifest_id AND person = '*';
          v_app_count := v_app_count + 1;
          IF p_person IS NOT NULL THEN
            UPDATE public.app_integration_usage SET count = count + 1, anon = coalesce(p_anon, false)
             WHERE day = v_day AND manifest_id = p_manifest_id AND person = p_person;
            v_person_count := v_person_count + 1;
          END IF;
          IF v_on AND v_app_limit > 0 THEN
            v_share := ceil(v_app_limit * 0.8)::int;
            IF v_app_count >= v_app_limit AND v_app_count - 1 < v_app_limit THEN
              v_crossed := '100';
            ELSIF v_app_count >= v_share AND v_app_count - 1 < v_share THEN
              v_crossed := '80';
            END IF;
          END IF;
        ELSE
          IF p_person IS NOT NULL THEN
            UPDATE public.app_integration_usage SET refused = refused + 1, anon = coalesce(p_anon, false)
             WHERE day = v_day AND manifest_id = p_manifest_id AND person = p_person;
          END IF;
          -- '*'.refused counts every refusal today, a person's limit or the whole app's.
          UPDATE public.app_integration_usage SET refused = refused + 1
           WHERE day = v_day AND manifest_id = p_manifest_id AND person = '*';
          IF v_app_refused = 0 THEN
            -- The day's first refusal tells the owner once ('refused'). When it is the whole app that is
            -- full, the 100% notice already told them as the count reached the limit (100% wins), unless
            -- the limit was lowered below today's count: counting stops AT the limit, so a count above it
            -- means the limit moved and never crossed on the way up, and this refusal is its 100%.
            IF v_app_full THEN
              IF v_app_count > v_app_limit THEN v_crossed := '100'; END IF;
            ELSE
              v_crossed := 'refused';
            END IF;
          END IF;
        END IF;

        RETURN jsonb_build_object(
          'ok', v_ok,
          'personCount', v_person_count,
          'appCount', v_app_count,
          'personLimit', CASE WHEN v_on AND v_person_limit > 0 AND p_person IS NOT NULL THEN v_person_limit END,
          'appLimit', CASE WHEN v_on AND v_app_limit > 0 THEN v_app_limit END,
          'crossed', v_crossed
        );
      END;
      $function$;
CREATE OR REPLACE FUNCTION public.app_integration_watch_add(p_manifest_id text, p_op text, p_rule text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
      BEGIN
        INSERT INTO public.app_integration_watch (day, manifest_id, op, rule, count)
        VALUES ((now() AT TIME ZONE 'utc')::date, p_manifest_id, left(p_op, 120), left(p_rule, 200), 1)
        ON CONFLICT (day, manifest_id, op, rule)
        DO UPDATE SET count = public.app_integration_watch.count + 1;
      END;
      $function$;
CREATE OR REPLACE FUNCTION public.assistant_add_tokens(p_bucket text, p_window_seconds integer, p_tokens integer)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  w timestamptz := to_timestamp(floor(extract(epoch from now()) / p_window_seconds) * p_window_seconds);
begin
  insert into public.assistant_usage (bucket, window_start, requests, tokens)
  values (p_bucket, w, 0, p_tokens)
  on conflict (bucket, window_start) do update set tokens = assistant_usage.tokens + p_tokens;
end;
$function$;
CREATE OR REPLACE FUNCTION public.assistant_admin_stats()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  is_scoped boolean;
  result jsonb;
  students_active int;
  students_pending int;
  staff_by_role jsonb;
  programmes_count int;
  cohorts_count int;
  quizzes_published int;
  quiz_avg numeric;
  certs_this_year int;
  fees_month numeric;
  teacher_cohorts uuid[];
begin
  if not public.has_permission('assistant.admin_help') then
    raise exception 'forbidden' using errcode = 'P0001';
  end if;

  is_scoped := not public.has_permission('quizzes.manage_all')
    and exists (select 1 from public.profiles where id = auth.uid() and role = 'Teacher');

  if is_scoped then
    select coalesce(array_agg(id), array[]::uuid[]) into teacher_cohorts
      from public.cohorts where teacher_id = auth.uid();
  end if;

  select count(*) filter (where status = 'Active' and role = 'Student') into students_active from public.profiles;
  select count(*) filter (where status = 'Pending Approval' and role = 'Student') into students_pending from public.profiles;
  select jsonb_object_agg(role, c) into staff_by_role from (
    select role, count(*) c from public.profiles where role <> 'Student' group by role
  ) s;

  select count(*) into programmes_count from public.programs;
  select count(*) into cohorts_count from public.cohorts where not is_scoped or teacher_id = auth.uid();

  select count(*) into quizzes_published from public.quizzes qz
    where qz.status = 'published'
      and (not is_scoped or qz.cohort_id = any(teacher_cohorts) or qz.created_by = auth.uid());

  select round(avg(a.percent), 1) into quiz_avg from public.quiz_attempts a
    join public.quizzes qz on qz.id = a.quiz_id
    where a.status in ('submitted', 'auto_submitted') and a.submitted_at > now() - interval '30 days'
      and (not is_scoped or qz.cohort_id = any(teacher_cohorts) or qz.created_by = auth.uid());

  select count(*) into certs_this_year from public.certificates
    where extract(year from issue_date) = extract(year from now());

  result := jsonb_build_object(
    'students', jsonb_build_object('active', coalesce(students_active, 0), 'pending', coalesce(students_pending, 0)),
    'staff_by_role', coalesce(staff_by_role, '{}'::jsonb),
    'programmes', coalesce(programmes_count, 0),
    'cohorts', coalesce(cohorts_count, 0),
    'quizzes_published', coalesce(quizzes_published, 0),
    'quiz_avg_percent_30d', quiz_avg,
    'certificates_this_year', coalesce(certs_this_year, 0)
  );

  if public.has_permission('fees.view') then
    select coalesce(sum(amount), 0) into fees_month from public.fee_transactions
      where date_trunc('month', transaction_date) = date_trunc('month', now());
    result := result || jsonb_build_object('fees_this_month', fees_month);
  end if;

  return result;
end;
$function$;
CREATE OR REPLACE FUNCTION public.assistant_consume(p_bucket text, p_window_seconds integer, p_max_requests integer)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  w timestamptz := to_timestamp(floor(extract(epoch from now()) / p_window_seconds) * p_window_seconds);
  current_count int;
begin
  delete from public.assistant_usage where window_start < now() - interval '2 days';

  insert into public.assistant_usage (bucket, window_start, requests, tokens)
  values (p_bucket, w, 1, 0)
  on conflict (bucket, window_start) do update set requests = assistant_usage.requests + 1
  returning requests into current_count;

  return current_count <= p_max_requests;
end;
$function$;
CREATE OR REPLACE FUNCTION public.blob_authorize(p_action text, p_bucket text, p_key text)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  rest text;
  uid text := auth.uid()::text;
  owner text;
begin
  if uid is null then return false; end if;
  if p_key is null or p_action is null or p_bucket is null then return false; end if;
  if split_part(p_key, '/', 1) <> 'aoh' or split_part(p_key, '/', 2) <> p_bucket then return false; end if;
  rest := substr(p_key, length('aoh/' || p_bucket || '/') + 1);
  if rest is null or rest = '' then return false; end if;

  if p_bucket = 'documents' then
    if split_part(rest, '/', 1) = 'profiles' and split_part(rest, '/', 2) = uid then
      return true;
    end if;
    if p_action in ('read', 'download', 'list') then
      return has_permission('people.view') or has_permission('students.manage') or has_permission('staff.manage');
    end if;
    return has_permission('students.manage') or has_permission('staff.manage');
  end if;

  if p_bucket = 'training-materials' then
    if p_action = 'upload' then
      return can_manage_training_material_folder(split_part(rest, '/', 1));
    end if;
    if p_action in ('delete', 'move') then
      return can_manage_training_material_folder(split_part(rest, '/', 1))
        and (has_permission('materials.approve') or not exists (
          select 1 from training_materials m
          where m.file_path in (rest, 'b2:' || p_bucket || '/' || rest) and m.status = 'approved'
        ));
    end if;
    return exists (
      select 1 from training_materials m
      where m.file_path in (rest, 'b2:' || p_bucket || '/' || rest)
        and (
          (m.status = 'approved' and is_cohort_member(m.cohort_id))
          or (has_permission('materials.manage') and m.cohort_id is not null and is_cohort_teacher(m.cohort_id))
          or has_permission('materials.approve')
        )
    );
  end if;

  if p_bucket = 'classwork-submissions' then
    owner := split_part(rest, '/', 2);
    if p_action = 'upload' then
      return owner = uid and exists (
        select 1 from assignments a
        where a.id::text = split_part(rest, '/', 1) and is_cohort_member(a.cohort_id)
      );
    end if;
    if owner = uid then return true; end if;
    return exists (
      select 1 from assignments a
      where a.id::text = split_part(rest, '/', 1)
        and (is_cohort_teacher(a.cohort_id) or has_permission('assignments.manage'))
    );
  end if;

  if p_bucket = 'chat-attachments' then
    if split_part(rest, '/', 1) = 'dm' then
      if p_action = 'upload' then return split_part(rest, '/', 2) = uid; end if;
      return split_part(rest, '/', 2) = uid or split_part(rest, '/', 3) = uid;
    end if;
    if split_part(rest, '/', 1) = 'group' and split_part(rest, '/', 2) ~ '^[0-9a-fA-F-]{36}$' then
      return is_chat_group_member(split_part(rest, '/', 2)::uuid);
    end if;
    return false;
  end if;

  if p_bucket = 'transparency-reports' then
    if p_action = 'upload' then return has_permission('cms.manage'); end if;
    if p_action in ('delete', 'move') then
      return has_permission('cms.manage') and not exists (
        select 1 from transparency_reports r
        where r.file_path in (rest, 'b2:' || p_bucket || '/' || rest)
      );
    end if;
    return has_permission('cms.manage') or exists (
      select 1 from transparency_reports r
      where r.file_path in (rest, 'b2:' || p_bucket || '/' || rest) and r.published
    );
  end if;

  return false;
end;
$function$;
CREATE OR REPLACE FUNCTION public.can_manage_cohort_plan(p_cohort_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select public.has_permission('academic_plans.approve')
    or (public.has_permission('academic_plans.manage') and public.is_cohort_teacher(p_cohort_id));
$function$;
CREATE OR REPLACE FUNCTION public.can_manage_helpdesk()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ select public.has_permission('helpdesk.manage') and exists (select 1 from public.profiles where id = auth.uid() and status = 'Active' and role <> 'Student'); $function$;
CREATE OR REPLACE FUNCTION public.can_manage_learning_unit(p_unit_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (
    select 1 from public.learning_units u
    where u.id = p_unit_id
      and (
        public.has_permission('academic_plans.approve')
        or (public.has_permission('lessons.manage') and u.cohort_id is not null and public.is_cohort_teacher(u.cohort_id))
        or u.created_by = auth.uid()
      )
  );
$function$;
CREATE OR REPLACE FUNCTION public.can_manage_quiz(q uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (
    select 1 from public.quizzes qz
    where qz.id = q
      and (
        public.has_permission('quizzes.manage_all')
        or (
          public.has_permission('quizzes.manage')
          and (
            qz.created_by = auth.uid()
            or (qz.cohort_id is not null and public.is_cohort_teacher(qz.cohort_id))
            or (qz.program_id is not null and exists (
              select 1 from public.cohorts c where c.program_id = qz.program_id and c.teacher_id = auth.uid()
            ))
          )
        )
      )
  );
$function$;
CREATE OR REPLACE FUNCTION public.can_manage_quiz_scope(p_program uuid, p_cohort uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select
    public.has_permission('quizzes.manage_all')
    or (
      public.has_permission('quizzes.manage')
      and (
        (p_cohort is not null and public.is_cohort_teacher(p_cohort))
        or (p_program is not null and exists (
          select 1 from public.cohorts c where c.program_id = p_program and c.teacher_id = auth.uid()
        ))
      )
    );
$function$;
CREATE OR REPLACE FUNCTION public.can_manage_training_material_folder(p_folder text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (
    select 1 from public.cohorts c
    where c.id::text = p_folder
      and ((public.has_permission('materials.manage') and public.is_cohort_teacher(c.id)) or public.has_permission('materials.approve'))
  );
$function$;
CREATE OR REPLACE FUNCTION public.can_read_discussion(c uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (select 1 from public.profiles where id = auth.uid() and status = 'Active')
    and (public.is_cohort_member(c) or public.is_cohort_teacher(c) or public.has_permission('academic_plans.approve'));
$function$;
CREATE OR REPLACE FUNCTION public.can_read_profile(p uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select
    p = auth.uid()
    or public.has_permission('people.view')
    or public.teaches_student(p)
    or exists (
      select 1 from public.profiles target
      where target.id = p and target.status = 'Active' and target.role <> 'Student'
    );
$function$;
CREATE OR REPLACE FUNCTION public.can_review_grade_appeals()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ select public.has_permission('grades.review_appeals') and exists (select 1 from public.profiles where id = auth.uid() and status = 'Active' and role <> 'Student'); $function$;
CREATE OR REPLACE FUNCTION public.can_view_quiz_results(q uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (
    select 1 from public.quizzes qz
    where qz.id = q
      and public.has_permission('quizzes.view_results')
      and (
        public.has_permission('quizzes.manage_all')
        or qz.created_by = auth.uid()
        or (qz.cohort_id is not null and public.is_cohort_teacher(qz.cohort_id))
        or (qz.program_id is not null and exists (
          select 1 from public.cohorts c where c.program_id = qz.program_id and c.teacher_id = auth.uid()
        ))
      )
  );
$function$;
CREATE OR REPLACE FUNCTION public.close_expired_course_windows()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_count integer := 0;
  r record;
  v_standing jsonb;
  v_pct numeric;
  v_attendance_ok boolean;
  v_new_status text;
begin
  for r in
    select ce.id, ce.student_id, ce.cohort_id, ce.progress_percent, ce.completion_status, p.required_attendance_percent
    from public.course_enrollments ce
    join public.cohorts c on c.id = ce.cohort_id
    join public.programs p on p.id = c.program_id
    where c.end_date < current_date
      and ce.status in ('approved', 'active')
      -- 'completed' and 'incomplete' are terminal outcomes of this function;
      -- 'completed_pending_review' is deliberately NOT excluded here so an
      -- enrollment that hit 100% progress before the window closed still
      -- gets its attendance re-checked once the window actually ends.
      and ce.completion_status not in ('completed', 'incomplete')
      -- Idempotency: once this enrollment has been notified that its window
      -- closed, never re-evaluate or re-notify it again, regardless of its
      -- completion_status.
      and not exists (
        select 1 from public.notifications n
        where n.recipient_id = ce.student_id and n.kind = 'course_window_closed'
          and n.entity_type = 'enrollment' and n.entity_id = ce.id
      )
  loop
    v_standing := public._attendance_standing(r.student_id, r.cohort_id);
    v_pct := (v_standing ->> 'attendance_percent')::numeric;
    v_attendance_ok := v_pct is null or v_pct >= r.required_attendance_percent;
    v_new_status := case
      when (r.completion_status = 'completed_pending_review' or r.progress_percent >= 100) and v_attendance_ok
        then 'completed_pending_review'
      else 'incomplete'
    end;

    update public.course_enrollments set completion_status = v_new_status where id = r.id;

    insert into public.notifications (recipient_id, kind, title, body, entity_type, entity_id)
    values (
      r.student_id, 'course_window_closed',
      case when v_new_status = 'completed_pending_review' then 'Course completed - pending review' else 'Course window closed' end,
      case when v_new_status = 'completed_pending_review'
        then 'Your course finished and is pending final review.'
        else 'Your course window ended before all requirements were met.' end,
      'enrollment', r.id
    );

    v_count := v_count + 1;
  end loop;

  return v_count;
end;
$function$;
CREATE OR REPLACE FUNCTION public.course_grade_summary(p_student_id uuid, p_cohort_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  can_view boolean;
  result jsonb;
begin
  can_view := p_student_id = auth.uid()
    or (public.is_cohort_teacher(p_cohort_id) and exists (
      select 1 from public.cohort_students
      where cohort_id = p_cohort_id and student_id = p_student_id and active
    ))
    or public.has_permission('academic_plans.approve')
    or public.has_permission('assignments.manage');
  if not can_view then
    raise exception 'forbidden' using errcode = 'P0001';
  end if;

  with components as (
    select
      'assignment'::text as component_type,
      a.id as component_id,
      a.title,
      a.grade_weight,
      case when s.marks is null or a.max_marks <= 0 then null else round(s.marks / a.max_marks * 100, 2) end as percent
    from public.learning_units u
    join public.assignments a on a.id = u.classwork_assignment_id
    left join public.submissions s on s.assignment_id = a.id and s.student_id = p_student_id
    where u.status = 'approved'
      and (u.cohort_id = p_cohort_id or (u.cohort_id is null and exists (
        select 1 from public.cohorts c where c.id = p_cohort_id and c.program_id = u.program_id
      )))
      and a.cohort_id = p_cohort_id
      and a.grade_weight > 0

    union all

    select
      'quiz'::text as component_type,
      q.id as component_id,
      q.title,
      q.grade_weight,
      max(qa.percent) filter (where qa.status in ('submitted', 'auto_submitted')) as percent
    from public.learning_units u
    join public.quizzes q on q.id = u.quiz_id
    left join public.quiz_attempts qa on qa.quiz_id = q.id and qa.student_id = p_student_id
    where u.status = 'approved'
      and (u.cohort_id = p_cohort_id or (u.cohort_id is null and exists (
        select 1 from public.cohorts c where c.id = p_cohort_id and c.program_id = u.program_id
      )))
      and (q.cohort_id = p_cohort_id or (q.cohort_id is null and q.program_id = (select program_id from public.cohorts where id = p_cohort_id)))
      and q.grade_weight > 0
    group by q.id, q.title, q.grade_weight
  ), summary as (
    select
      coalesce(sum(grade_weight), 0) as total_weight,
      coalesce(sum(grade_weight) filter (where percent is not null), 0) as assessed_weight,
      case when coalesce(sum(grade_weight), 0) = 0 then null
        else round(sum(grade_weight * coalesce(percent, 0)) / sum(grade_weight), 2)
      end as course_grade,
      coalesce(jsonb_agg(jsonb_build_object(
        'type', component_type, 'id', component_id, 'title', title,
        'grade_weight', grade_weight, 'percent', percent
      ) order by component_type, title), '[]'::jsonb) as components
    from components
  )
  select jsonb_build_object(
    'student_id', p_student_id,
    'cohort_id', p_cohort_id,
    'course_grade', course_grade,
    'total_weight', total_weight,
    'assessed_weight', assessed_weight,
    'components', components
  ) into result from summary;

  return result;
end;
$function$;
CREATE OR REPLACE FUNCTION public.create_academic_lesson_bundle(p_program_id uuid, p_cohort_id uuid, p_course_plan_id uuid, p_title text, p_summary text, p_unit_type text, p_position integer, p_due_at timestamp with time zone, p_classwork_minutes integer, p_classwork_weight numeric, p_quiz_minutes integer, p_quiz_weight numeric, p_available_from timestamp with time zone DEFAULT NULL::timestamp with time zone)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  unit public.learning_units%rowtype;
  v_assignment_id uuid;
  v_quiz_id uuid;
begin
  if auth.uid() is null
     or not public.has_permission('lessons.manage')
     or not public.is_cohort_teacher(p_cohort_id) then
    raise exception 'forbidden' using errcode = 'P0001';
  end if;
  if not exists (select 1 from public.cohorts where id = p_cohort_id and program_id = p_program_id) then
    raise exception 'cohort_program_mismatch' using errcode = 'P0001';
  end if;
  if p_course_plan_id is not null and not exists (
    select 1 from public.teacher_course_plans
    where id = p_course_plan_id and cohort_id = p_cohort_id and teacher_id = auth.uid()
  ) then
    raise exception 'course_plan_scope_mismatch' using errcode = 'P0001';
  end if;
  if p_unit_type not in ('chapter', 'module', 'topic')
     or p_position < 1
     or p_classwork_minutes not between 1 and 1440
     or p_quiz_minutes not between 1 and 600
     or p_classwork_weight <= 0 or p_classwork_weight > 100
     or p_quiz_weight <= 0 or p_quiz_weight > 100 then
    raise exception 'invalid_lesson_assessment_settings' using errcode = 'P0001';
  end if;
  if p_available_from is not null and p_due_at is not null and p_available_from >= p_due_at then
    raise exception 'available_after_due' using errcode = 'P0001';
  end if;

  insert into public.learning_units (
    program_id, cohort_id, course_plan_id, title, summary, unit_type,
    position, available_from, due_at, status, created_by
  ) values (
    p_program_id, p_cohort_id, p_course_plan_id, btrim(p_title), coalesce(p_summary, ''), p_unit_type,
    p_position, p_available_from, p_due_at, 'draft', auth.uid()
  ) returning * into unit;

  insert into public.assignments (
    cohort_id, title, description, due_date, max_marks, learning_unit_id,
    time_limit_minutes, grade_weight
  ) values (
    p_cohort_id, btrim(p_title) || ' classwork', 'Classwork for ' || btrim(p_title),
    p_due_at::date, 100, unit.id, p_classwork_minutes, p_classwork_weight
  ) returning id into v_assignment_id;

  insert into public.quizzes (
    program_id, cohort_id, created_by, title, description, status,
    time_limit_minutes, max_attempts, pass_mark, learning_unit_id, grade_weight
  ) values (
    p_program_id, p_cohort_id, auth.uid(), btrim(p_title) || ' quiz',
    'Timed quiz for ' || btrim(p_title) || '. Add questions in Quiz Builder before publication.',
    'draft', p_quiz_minutes, 1, 50, unit.id, p_quiz_weight
  ) returning id into v_quiz_id;

  update public.learning_units
  set quiz_id = v_quiz_id, classwork_assignment_id = v_assignment_id
  where id = unit.id
  returning * into unit;

  return to_jsonb(unit);
end;
$function$;
CREATE OR REPLACE FUNCTION public.create_grade_appeal(p_id uuid, p_kind text, p_ref uuid, p_reason text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ declare actor public.profiles%rowtype; existing public.grade_appeals%rowtype; v_title text; v_score numeric; v_max numeric; begin select * into actor from public.profiles where id=auth.uid() and status='Active' and role='Student'; if not found then raise exception 'An active student account is required'; end if; perform pg_advisory_xact_lock(hashtextextended(actor.id::text,0)); select * into existing from public.grade_appeals where id=p_id; if found then if existing.student_id<>actor.id then raise exception 'Appeal ID unavailable'; end if; return existing.id; end if; if p_reason is null or length(btrim(p_reason)) not between 1 and 4000 then raise exception 'Explain your reason in 1–4000 characters'; end if; if p_kind is null or p_kind not in ('assignment','quiz') then raise exception 'Choose the marked work you want reviewed'; end if; if (select count(*) from public.grade_appeals where student_id=actor.id and created_at>now()-interval '1 day')>=5 then raise exception 'You have reached the daily limit of 5 appeals. Please wait before submitting more'; end if; if p_kind='assignment' then select a.title,s.score,a.max_score into v_title,v_score,v_max from public.submissions s join public.assignments a on a.id=s.assignment_id where s.assignment_id=p_ref and s.student_id=actor.id; if v_title is null then raise exception 'That marked assignment was not found on your record'; end if; if v_score is null then raise exception 'This assignment has not been marked yet'; end if; if exists(select 1 from public.grade_appeals where student_id=actor.id and assignment_id=p_ref and status='submitted') then raise exception 'You already have an open appeal for this assignment'; end if; insert into public.grade_appeals(id,student_id,student_name,work_kind,assignment_id,work_title,original_score,max_score,reason) values(p_id,actor.id,coalesce(nullif(btrim(to_jsonb(actor)->>'name'),''),nullif(btrim(actor.full_name),''),'Account holder'),'assignment',p_ref,v_title,v_score,v_max,btrim(p_reason)); else select q.title,at.score,at.max_score into v_title,v_score,v_max from public.quiz_attempts at join public.quizzes q on q.id=at.quiz_id where at.id=p_ref and at.student_id=actor.id and at.status<>'in_progress'; if v_title is null then raise exception 'That marked quiz attempt was not found on your record'; end if; if v_score is null then raise exception 'This quiz has not been marked yet'; end if; if v_max is null or v_max<=0 then raise exception 'This quiz has no markable score'; end if; if exists(select 1 from public.grade_appeals where student_id=actor.id and quiz_attempt_id=p_ref and status='submitted') then raise exception 'You already have an open appeal for this quiz attempt'; end if; insert into public.grade_appeals(id,student_id,student_name,work_kind,quiz_attempt_id,work_title,original_score,max_score,reason) values(p_id,actor.id,coalesce(nullif(btrim(to_jsonb(actor)->>'name'),''),nullif(btrim(actor.full_name),''),'Account holder'),'quiz',p_ref,v_title,v_score,v_max,btrim(p_reason)); end if; return p_id; end; $function$;
CREATE OR REPLACE FUNCTION public.create_helpdesk_ticket(p_id uuid, p_subject text, p_category text, p_body text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ declare actor public.profiles%rowtype; existing public.helpdesk_tickets%rowtype; begin select * into actor from public.profiles where id = auth.uid() and status = 'Active' and role = 'Student'; if not found then raise exception 'An active student account is required'; end if; perform pg_advisory_xact_lock(hashtextextended(actor.id::text, 0)); select * into existing from public.helpdesk_tickets where id = p_id; if found then if existing.student_id <> actor.id then raise exception 'Ticket ID unavailable'; end if; return existing.id; end if; if p_body is null or length(btrim(p_body)) not between 1 and 10000 then raise exception 'Message must be 1–10000 characters'; end if; if (select count(*) from public.helpdesk_tickets where student_id = actor.id and created_at > now() - interval '1 hour') >= 10 then raise exception 'Please wait before creating more tickets (maximum 10 per hour)'; end if; insert into public.helpdesk_tickets(id, student_id, student_name, subject, category) values(p_id, actor.id, coalesce(nullif(btrim(to_jsonb(actor)->>'name'), ''), nullif(btrim(actor.full_name), ''), 'Account holder'), btrim(p_subject), p_category); insert into public.helpdesk_messages(ticket_id, author_id, author_name, author_role, body) values(p_id, actor.id, coalesce(nullif(btrim(to_jsonb(actor)->>'name'), ''), nullif(btrim(actor.full_name), ''), 'Account holder'), actor.role, btrim(p_body)); return p_id; end; $function$;
CREATE OR REPLACE FUNCTION public.decide_grade_appeal(p_appeal uuid, p_decision text, p_score numeric, p_note text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ declare appeal public.grade_appeals%rowtype; reviewer public.profiles%rowtype; v_quiz_id uuid; v_pass_mark numeric; v_cohort uuid; v_max numeric; v_percent numeric; v_feedback text; begin if not public.can_review_grade_appeals() then raise exception 'Grade appeal review permission required'; end if; select * into reviewer from public.profiles where id=auth.uid() and status='Active' and role<>'Student'; if not found then raise exception 'An active staff account is required'; end if; select * into appeal from public.grade_appeals where id=p_appeal for update; if not found then raise exception 'Appeal not found'; end if; if appeal.status<>'submitted' then raise exception 'This appeal has already been decided'; end if; if p_decision is null or p_decision not in ('adjusted','upheld') then raise exception 'Choose adjust or uphold'; end if; if p_note is null or length(btrim(p_note)) not between 3 and 2000 then raise exception 'Write a decision note of 3–2000 characters; the student sees it'; end if; if p_decision='adjusted' then if p_score is null or p_score<0 or p_score>appeal.max_score then raise exception 'The adjusted mark must be between 0 and %',appeal.max_score; end if; v_max:=appeal.max_score; if appeal.work_kind='assignment' then select a.cohort_id into v_cohort from public.assignments a where a.id=appeal.assignment_id; if not ((select public.has_permission('assignments.manage')) or ((select public.has_permission('assignments.own')) and (select public.is_cohort_teacher(v_cohort)))) then raise exception 'You are not authorized to change this assignment mark'; end if; select feedback into v_feedback from public.submissions where assignment_id=appeal.assignment_id and student_id=appeal.student_id; update public.submissions set score=round(p_score,2),status='Graded',feedback=left(concat_ws(E'\n\n',nullif(btrim(coalesce(v_feedback,'')),''),'Appeal decision: '||btrim(p_note)),4000) where assignment_id=appeal.assignment_id and student_id=appeal.student_id; if not found then raise exception 'The student submission for this assignment no longer exists'; end if; else select at.quiz_id into v_quiz_id from public.quiz_attempts at where at.id=appeal.quiz_attempt_id; if v_quiz_id is null then raise exception 'That quiz attempt no longer exists'; end if; if not ((select public.can_manage_quiz(v_quiz_id)) or (select public.has_permission('quizzes.manage_all'))) then raise exception 'You are not authorized to change this quiz mark'; end if; select pass_mark into v_pass_mark from public.quizzes where id=v_quiz_id; v_percent:=case when v_max>0 then round(p_score/v_max*100,2) else 0 end; update public.quiz_attempts set score=round(p_score,2),percent=v_percent,passed=v_percent>=coalesce(v_pass_mark,50) where id=appeal.quiz_attempt_id; end if; end if; update public.grade_appeals set status=p_decision,adjusted_score=case when p_decision='adjusted' then round(p_score,2) else null end,decision_note=btrim(p_note),decided_by=reviewer.id,decided_by_name=coalesce(nullif(btrim(to_jsonb(reviewer)->>'name'),''),nullif(btrim(reviewer.full_name),''),'Staff'),decided_at=now(),updated_at=now() where id=p_appeal; return jsonb_build_object('status',p_decision,'adjusted_score',case when p_decision='adjusted' then round(p_score,2) else null end,'decided_at',now()); end; $function$;
CREATE OR REPLACE FUNCTION public.discussion_guard()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare c uuid;
begin
  if tg_op = 'INSERT' then
    if auth.uid() is null or new.author_id <> auth.uid() then raise exception 'Invalid discussion author'; end if;
    select name, role into new.author_name, new.author_role from public.profiles
      where id = auth.uid() and status = 'Active';
    if not found then raise exception 'Active account required'; end if;
    new.created_at := now();
    if tg_table_name = 'discussion_replies' then new.is_answer := false; end if;
    if tg_table_name = 'discussion_threads' and new.unit_id is not null then
      if not exists (select 1 from public.learning_units u where u.id = new.unit_id
        and (u.cohort_id = new.cohort_id or (u.cohort_id is null and u.program_id = (select program_id from public.cohorts where id = new.cohort_id)))) then
        raise exception 'Lesson does not belong to this cohort';
      end if;
    end if;
  elsif tg_table_name = 'discussion_threads' then
    if new.id <> old.id
       or new.author_id <> old.author_id
       or new.cohort_id <> old.cohort_id
       or new.unit_id is distinct from old.unit_id
       or new.created_at <> old.created_at
       or new.author_name <> old.author_name
       or new.author_role <> old.author_role then
      raise exception 'Only the question title and details can be updated';
    end if;
  else
    if new.id <> old.id
       or new.author_id <> old.author_id
       or new.thread_id <> old.thread_id
       or new.created_at <> old.created_at
       or new.author_name <> old.author_name
       or new.author_role <> old.author_role then
      raise exception 'Only the reply text or answer flag can be updated';
    end if;
    if (to_jsonb(new) - 'is_answer') is distinct from (to_jsonb(old) - 'is_answer') then
      -- The author corrects their own text; a cohort instructor or academic
      -- administrator may also moderate it (the same people the UI lets edit).
      select cohort_id into c from public.discussion_threads where id = new.thread_id;
      if auth.uid() is null or (old.author_id <> auth.uid() and not (public.is_cohort_teacher(c) or public.has_permission('academic_plans.approve'))) then
        raise exception 'Only the author or a cohort instructor can edit this reply';
      end if;
    end if;
    if new.is_answer is distinct from old.is_answer then
      select cohort_id into c from public.discussion_threads where id = new.thread_id;
      if not public.can_read_discussion(c) or not (public.is_cohort_teacher(c) or public.has_permission('academic_plans.approve')) then
        raise exception 'Only the cohort teacher or an academic administrator can mark answers';
      end if;
    end if;
  end if;
  return new;
end; $function$;
CREATE OR REPLACE FUNCTION public.enqueue_email(p_to_email text, p_to_name text, p_template text, p_subject text, p_payload jsonb, p_related_user_id uuid, p_dedupe_key text DEFAULT NULL::text, p_send_after timestamp with time zone DEFAULT now())
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_id uuid;
begin
  if p_to_email is null or length(btrim(p_to_email)) = 0 then
    return null;
  end if;

  insert into public.email_outbox (
    to_email, to_name, template, subject, payload, related_user_id, dedupe_key, send_after
  ) values (
    btrim(p_to_email), coalesce(p_to_name, ''), p_template, p_subject, coalesce(p_payload, '{}'::jsonb),
    p_related_user_id, p_dedupe_key, coalesce(p_send_after, now())
  )
  on conflict (dedupe_key) do nothing
  returning id into v_id;

  return v_id;
exception when unique_violation then
  return null;
end;
$function$;
CREATE OR REPLACE FUNCTION public.finalize_expired_quiz_attempts(p_quiz_id uuid DEFAULT NULL::uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  n int := 0;
  r record;
begin
  for r in
    select a.id from public.quiz_attempts a
    where a.status = 'in_progress'
      and a.deadline_at is not null
      and now() > a.deadline_at + interval '10 seconds'
      and (p_quiz_id is null or a.quiz_id = p_quiz_id)
      and (
        a.student_id = auth.uid()
        or public.can_manage_quiz(a.quiz_id)
        or public.can_view_quiz_results(a.quiz_id)
      )
  loop
    perform public._grade_quiz_attempt(r.id, 'auto_submitted');
    n := n + 1;
  end loop;
  return n;
end;
$function$;
CREATE OR REPLACE FUNCTION public.get_quiz_review(p_attempt_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  att record;
  qz record;
  can_view boolean;
  allowed boolean := false;
  questions jsonb := '[]'::jsonb;
  qid uuid;
  q record;
  opts jsonb;
  order_ids jsonb;
  student_ans jsonb;
  res jsonb;
begin
  select * into att from public.quiz_attempts where id = p_attempt_id;
  if att.id is null then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  select * into qz from public.quizzes where id = att.quiz_id;

  can_view := public.can_view_quiz_results(qz.id) or public.can_manage_quiz(qz.id);

  if att.student_id = auth.uid() then
    if att.status = 'in_progress' then
      raise exception 'not_submitted' using errcode = 'P0001';
    end if;
    if qz.show_answers = 'after_submit' then
      allowed := true;
    elsif qz.show_answers = 'after_close' then
      allowed := qz.closes_at is not null and now() >= qz.closes_at;
    end if;
  elsif can_view then
    allowed := true;
  end if;

  if not allowed then
    raise exception 'review_unavailable' using errcode = 'P0001';
  end if;

  foreach qid in array att.question_order loop
    select * into q from public.quiz_questions where id = qid;
    order_ids := att.option_order -> qid::text;
    if order_ids is not null then
      select jsonb_agg(jsonb_build_object('id', o ->> 'id', 'text', o ->> 'text'))
        into opts
        from jsonb_array_elements(order_ids) oid
        join jsonb_array_elements(q.options) o on (o ->> 'id') = (oid ->> 'id');
    else
      opts := '[]'::jsonb;
    end if;
    student_ans := att.answers -> q.id::text;
    res := coalesce(att.results -> q.id::text, '{}'::jsonb);
    questions := questions || jsonb_build_array(jsonb_build_object(
      'id', q.id, 'type', q.type, 'prompt', q.prompt, 'points', q.points,
      'options', coalesce(opts, '[]'::jsonb), 'correct', q.correct, 'explanation', q.explanation,
      'answer', student_ans, 'awarded', res -> 'points', 'is_correct', res -> 'correct'
    ));
  end loop;

  return jsonb_build_object(
    'attempt_id', att.id, 'score', att.score, 'max_score', att.max_score, 'percent', att.percent,
    'passed', att.passed, 'status', att.status, 'submitted_at', att.submitted_at, 'questions', questions
  );
end;
$function$;
CREATE OR REPLACE FUNCTION public.guard_administrator_profile_changes()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if coalesce(auth.role(), '') in ('anon', 'authenticated') then
    if not exists (select 1 from public.profiles where id = auth.uid() and status = 'Active') then
      raise exception 'An active account is required';
    end if;
    if (old.role in ('School Admin', 'Super Admin') or new.role in ('School Admin', 'Super Admin'))
       and (new.role is distinct from old.role or new.status is distinct from old.status or new.email is distinct from old.email)
       and not exists (select 1 from public.profiles where id = auth.uid() and role = 'Super Admin' and status = 'Active') then
      raise exception 'Only an active Super Admin may change administrator access';
    end if;
  end if;
  return new;
end $function$;
CREATE OR REPLACE FUNCTION public.guard_transparency_file()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ begin if new.published and not exists (select 1 from storage.objects where bucket_id = 'transparency-reports' and name = new.file_path) then raise exception 'Upload the official PDF before publishing'; end if; return new; end; $function$;
CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  meta jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  app_meta jsonb := coalesce(new.raw_app_meta_data, '{}'::jsonb);
  program_list uuid[] := '{}';
begin
  begin
    select coalesce(array_agg(value::uuid), '{}')
      into program_list
      from jsonb_array_elements_text(coalesce(meta -> 'program_ids', '[]'::jsonb));
  exception when others then
    program_list := '{}';
  end;

  insert into public.profiles (id, name, full_name, email, phone, role, status, program_ids, note, documents)
  values (
    new.id,
    coalesce(meta ->> 'full_name', split_part(coalesce(new.email, 'member'), '@', 1)),
    meta ->> 'full_name',
    new.email,
    coalesce(meta ->> 'phone', ''),
    coalesce(app_meta ->> 'role', 'Student'),
    coalesce(app_meta ->> 'status', 'Pending Approval'),
    program_list,
    meta ->> 'note',
    meta ->> 'documents'
  )
  on conflict (id) do update
    set email = excluded.email,
        full_name = coalesce(public.profiles.full_name, excluded.full_name),
        updated_at = now();
  return new;
end $function$;
CREATE OR REPLACE FUNCTION public.has_permission(perm text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and p.status = 'Active'
      and (
        p.role = 'Super Admin'
        or exists (
          select 1 from public.role_permissions rp
          where rp.role = p.role and rp.permission = perm
        )
      )
  );
$function$;
CREATE OR REPLACE FUNCTION public.is_academic_reviewer()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select public.has_permission('academic_plans.approve');
$function$;
CREATE OR REPLACE FUNCTION public.is_admin()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
  select exists (
    select 1 from public.profiles
    where profiles.id = auth.uid()
      and profiles.status = 'Active'
      and profiles.role in ('Super Admin', 'School Admin', 'Registrar')
  )
$function$;
CREATE OR REPLACE FUNCTION public.is_chat_group_admin(gid uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (
    select 1 from public.chat_group_members m
    where m.group_id = gid
      and m.user_id = auth.uid()
      and m.member_role in ('owner', 'admin')
  );
$function$;
CREATE OR REPLACE FUNCTION public.is_chat_group_member(gid uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (
    select 1 from public.chat_group_members m
    where m.group_id = gid and m.user_id = auth.uid()
  );
$function$;
CREATE OR REPLACE FUNCTION public.is_cohort_member(c uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (
    select 1 from public.cohort_students
    where cohort_id = c and student_id = auth.uid() and active
  );
$function$;
CREATE OR REPLACE FUNCTION public.is_cohort_teacher(c uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (select 1 from public.cohorts where id = c and teacher_id = auth.uid());
$function$;
CREATE OR REPLACE FUNCTION public.is_portal_admin()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select public.has_permission('people.view');
$function$;
CREATE OR REPLACE FUNCTION public.is_staff()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
  select exists (
    select 1 from public.profiles
    where profiles.id = auth.uid()
      and profiles.status = 'Active'
      and profiles.role in ('Super Admin', 'School Admin', 'Registrar', 'Teacher', 'Admission Officer')
  )
$function$;
CREATE OR REPLACE FUNCTION public.is_super_admin()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'Super Admin' and status = 'Active'
  );
$function$;
CREATE OR REPLACE FUNCTION public.issue_certificate(p_student_id uuid, p_program_id uuid, p_honors text DEFAULT 'Pass'::text, p_certificate_type text DEFAULT 'Certificate of Completion'::text, p_completion_date date DEFAULT NULL::date)
 RETURNS certificates
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_certificate public.certificates%rowtype;
  v_student public.profiles%rowtype;
  v_manager boolean;
  v_units bigint;
  v_done bigint;
  v_type text := coalesce(nullif(btrim(p_certificate_type), ''), 'Certificate of Completion');
begin
  if auth.uid() is null or not exists (select 1 from public.profiles where id = auth.uid() and status = 'Active') then
    raise exception 'An active signed-in account is required';
  end if;
  v_manager := public.has_permission('certificates.manage');
  if not v_manager and p_student_id is distinct from auth.uid() then raise exception 'Not authorized'; end if;
  if p_honors is null or p_honors not in ('Pass', 'Merit', 'Distinction') then raise exception 'Invalid award class'; end if;
  if not v_manager and p_honors <> 'Pass' then raise exception 'Only certificate staff can assign honors'; end if;
  if v_type not in ('Certificate of Completion', 'Certificate of Achievement', 'Certificate of Participation',
                    'Professional Training Certificate', 'Certificate of Excellence', 'Diploma Certificate') then
    raise exception 'Invalid certificate type';
  end if;
  -- A diploma is only issued on an administrator's authority.
  if v_type = 'Diploma Certificate' and not v_manager then raise exception 'Not authorized for that certificate type'; end if;
  if p_completion_date is not null and p_completion_date > current_date then
    raise exception 'The completion date cannot be in the future';
  end if;

  select * into v_student from public.profiles where id = p_student_id and status = 'Active';
  if v_student.id is null then raise exception 'The holder must be an active account'; end if;
  if not exists (select 1 from public.programs where id = p_program_id) then raise exception 'Programme not found'; end if;

  perform pg_advisory_xact_lock(hashtextextended(p_student_id::text || ':' || p_program_id::text, 0));
  select * into v_certificate from public.certificates
    where student_id = p_student_id and program_id = p_program_id
    order by issue_date desc nulls last, id limit 1;
  -- Issuing again for the same holder and programme returns the existing record:
  -- that is the authorised reissue path and it never renumbers a serial.
  if v_certificate.id is not null then return v_certificate; end if;

  if not v_manager then
    select count(*), count(*) filter (where exists (
      select 1 from public.student_learning_progress pr
      where pr.student_id = p_student_id and pr.learning_unit_id = u.id and pr.status = 'completed'
    )) into v_units, v_done
    from public.learning_units u
    where u.program_id = p_program_id and u.status = 'approved'
      and (u.available_from is null or u.available_from <= now())
      and ((u.cohort_id is null and p_program_id::text in (select jsonb_array_elements_text(to_jsonb(v_student.program_ids))))
           or exists (select 1 from public.cohort_students cs where cs.cohort_id = u.cohort_id and cs.student_id = p_student_id and cs.active));
    if v_units = 0 or v_done <> v_units then raise exception 'Complete all approved lessons before claiming this certificate'; end if;
  end if;

  insert into public.certificates
    (student_id, program_id, serial, issue_date, honors, grade, status, certificate_type, completion_date)
  values
    (p_student_id, p_program_id, public.next_certificate_serial(), current_date, p_honors, '', 'Valid',
     v_type, coalesce(p_completion_date, current_date))
  returning * into v_certificate;
  return v_certificate;
end $function$;
CREATE OR REPLACE FUNCTION public.list_appealable_work()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ select coalesce(jsonb_agg(item order by item->>'recorded_at' desc), '[]'::jsonb) from (select jsonb_build_object('kind','assignment','ref_id',a.id,'title',a.title,'score',s.score,'max_score',a.max_score,'recorded_at',coalesce(to_jsonb(s)->>'submitted_at',a.due_date::text),'appeal_status',(select ga.status from public.grade_appeals ga where ga.student_id=auth.uid() and ga.assignment_id=a.id order by ga.created_at desc limit 1)) item from public.submissions s join public.assignments a on a.id=s.assignment_id where s.student_id=auth.uid() and s.score is not null and a.max_score>0 union all select jsonb_build_object('kind','quiz','ref_id',at.id,'title',q.title,'score',at.score,'max_score',at.max_score,'recorded_at',coalesce(at.submitted_at,at.started_at)::text,'appeal_status',(select ga.status from public.grade_appeals ga where ga.student_id=auth.uid() and ga.quiz_attempt_id=at.id order by ga.created_at desc limit 1)) item from public.quiz_attempts at join public.quizzes q on q.id=at.quiz_id where at.student_id=auth.uid() and at.status<>'in_progress' and at.score is not null and coalesce(at.max_score,0)>0) rows; $function$;
CREATE OR REPLACE FUNCTION public.log_certificate_event()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  insert into public.certificate_audit (certificate_id, serial, action, actor_id, reason)
  values (new.id, new.serial, case when new.status = 'Revoked' then 'revoked' else 'issued' end,
          auth.uid(), case when new.status = 'Revoked' then new.revocation_reason else null end);
  return new;
end $function$;
CREATE OR REPLACE FUNCTION public.my_course_status()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  result jsonb := '[]'::jsonb;
  e record;
  entry jsonb;
  v_standing jsonb;
  v_units_total integer;
  v_units_completed integer;
  v_next_unit jsonb;
  v_overdue jsonb;
  v_deadlines jsonb;
  v_grade jsonb;
  v_window text;
  v_days_remaining integer;
begin
  if auth.uid() is null then raise exception 'not_authenticated' using errcode = 'P0001'; end if;

  for e in
    select ce.id as enrollment_id, ce.cohort_id, ce.progress_percent, ce.completion_status,
           c.name as cohort_name, c.program_id, c.start_date, c.end_date,
           p.title as program_title, p.required_attendance_percent, p.completion_pass_mark
    from public.course_enrollments ce
    join public.cohorts c on c.id = ce.cohort_id
    join public.programs p on p.id = c.program_id
    where ce.student_id = auth.uid() and ce.status in ('approved', 'active', 'completed')
    order by c.start_date desc
  loop
    v_window := case
      when e.start_date > current_date then 'upcoming'
      when e.end_date < current_date then 'ended'
      else 'active'
    end;
    v_days_remaining := e.end_date - current_date;

    v_standing := public._attendance_standing(auth.uid(), e.cohort_id);

    select count(*) into v_units_total from public.learning_units u where u.cohort_id = e.cohort_id and u.status = 'approved';
    select count(*) into v_units_completed
    from public.student_learning_progress sp
    join public.learning_units u on u.id = sp.learning_unit_id
    where sp.student_id = auth.uid() and sp.cohort_id = e.cohort_id and sp.status = 'completed' and u.status = 'approved';

    select jsonb_build_object('id', u.id, 'title', u.title, 'unit_type', u.unit_type, 'position', u.position, 'available_from', u.available_from, 'due_at', u.due_at)
    into v_next_unit
    from public.learning_units u
    where u.cohort_id = e.cohort_id and u.status = 'approved'
      and (u.available_from is null or u.available_from <= now())
      and not exists (
        select 1 from public.student_learning_progress sp
        where sp.learning_unit_id = u.id and sp.student_id = auth.uid() and sp.status = 'completed'
      )
    order by u.position asc
    limit 1;

    select coalesce(jsonb_agg(jsonb_build_object('id', u.id, 'title', u.title, 'due_at', u.due_at) order by u.due_at asc), '[]'::jsonb)
    into v_overdue
    from public.learning_units u
    where u.cohort_id = e.cohort_id and u.status = 'approved' and u.due_at is not null and u.due_at < now()
      and not exists (
        select 1 from public.student_learning_progress sp
        where sp.learning_unit_id = u.id and sp.student_id = auth.uid() and sp.status = 'completed'
      );

    select coalesce(jsonb_agg(d order by (d ->> 'due_at')::timestamptz asc), '[]'::jsonb) into v_deadlines
    from (
      select jsonb_build_object('kind', 'classwork', 'id', a.id, 'title', a.title, 'due_at', a.due_date::timestamptz) as d
      from public.assignments a
      join public.learning_units u on u.classwork_assignment_id = a.id
      where a.cohort_id = e.cohort_id and u.status = 'approved'
        and a.due_date between current_date and current_date + 14
      union all
      select jsonb_build_object('kind', 'quiz', 'id', q.id, 'title', q.title, 'due_at', u.due_at)
      from public.quizzes q
      join public.learning_units u on u.quiz_id = q.id
      where u.cohort_id = e.cohort_id and u.status = 'approved' and u.due_at between now() and now() + interval '14 days'
      union all
      select jsonb_build_object('kind', 'unit', 'id', u.id, 'title', u.title, 'due_at', u.due_at)
      from public.learning_units u
      where u.cohort_id = e.cohort_id and u.status = 'approved' and u.due_at between now() and now() + interval '14 days'
    ) merged(d);

    select public.course_grade_summary(auth.uid(), e.cohort_id) into v_grade;

    entry := jsonb_build_object(
      'cohort_id', e.cohort_id, 'cohort_name', e.cohort_name, 'program_id', e.program_id, 'program_title', e.program_title,
      'start_date', e.start_date, 'end_date', e.end_date, 'days_remaining', v_days_remaining, 'window', v_window,
      'required_attendance_percent', e.required_attendance_percent, 'completion_pass_mark', e.completion_pass_mark,
      'sessions_held', v_standing -> 'sessions_held', 'sessions_attended', v_standing -> 'sessions_attended',
      'sessions_missed', v_standing -> 'sessions_missed', 'attendance_percent', v_standing -> 'attendance_percent',
      'attendance_ok', (v_standing ->> 'attendance_percent') is null or (v_standing ->> 'attendance_percent')::numeric >= e.required_attendance_percent,
      'missed', v_standing -> 'missed',
      'units_total', v_units_total, 'units_completed', v_units_completed,
      'progress_percent', e.progress_percent, 'completion_status', e.completion_status,
      'next_unit', v_next_unit, 'overdue_units', v_overdue, 'upcoming_deadlines', v_deadlines, 'grade', v_grade
    );
    result := result || jsonb_build_array(entry);
  end loop;

  return result;
end;
$function$;
CREATE OR REPLACE FUNCTION public.next_certificate_serial()
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_serial text;
begin
  loop
    v_serial := 'AOH-CERT-' || extract(year from current_date)::int::text || '-' || lpad(nextval('public.certificate_serial_sequence')::text, 10, '0');
    exit when not exists (select 1 from public.certificates where lower(btrim(serial)) = lower(v_serial));
  end loop;
  return v_serial;
end $function$;
CREATE OR REPLACE FUNCTION public.notifications_sync_read_state()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
begin
  if tg_op = 'INSERT' then
    if new.recipient_id is null and new.user_id is not null then new.recipient_id := new.user_id; end if;
    if new.user_id is null then new.user_id := new.recipient_id; end if;
    if new.read_at is not null then new.read := true;
    elsif coalesce(new.read,false) then new.read_at := now();
    else new.read := false; end if;
  else
    if new.read_at is distinct from old.read_at and new.read_at is not null then new.read := true;
    elsif new.read is distinct from old.read and coalesce(new.read,false) and new.read_at is null then new.read_at := now();
    elsif new.read is distinct from old.read and coalesce(new.read,false) = false then new.read_at := null;
    end if;
  end if;
  return new;
end $function$;
CREATE OR REPLACE FUNCTION public.preview_course_enrollment(p_cohort_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if auth.uid() is null then raise exception 'not_authenticated' using errcode = 'P0001'; end if;
  if not public.has_permission('courses.enroll') then
    raise exception 'forbidden' using errcode = 'P0001';
  end if;
  if not exists (select 1 from public.profiles where id = auth.uid() and role = 'Student' and status = 'Active') then
    raise exception 'active_student_required' using errcode = 'P0001';
  end if;
  return public._course_enrollment_preview(auth.uid(), p_cohort_id);
end;
$function$;
CREATE OR REPLACE FUNCTION public.programs_ensure_code()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
  declare
    slug text;
    frag text;
  begin
    if new.code is null or btrim(new.code) = '' then
      slug := regexp_replace(
        lower(coalesce(nullif(btrim(new.title), ''), nullif(btrim(new.name), ''), 'course')),
        '[^a-z0-9]+', '-', 'g'
      );
      slug := regexp_replace(slug, E'^-+|-+$', '', 'g');
      if slug is null or btrim(slug, '-') = '' then
        slug := 'course';
      end if;
      frag := left(regexp_replace(coalesce(new.id::text, gen_random_uuid()::text), '[^a-z0-9]', '', 'gi'), 4);
      new.code := left(slug, 48) || '-' || frag;
    end if;
    return new;
  end
  $function$;
CREATE OR REPLACE FUNCTION public.programs_sync_title_name()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
  begin
    begin
      if new.title is null or btrim(new.title) = '' then
        new.title := new.name;
      end if;
    exception when others then null;
    end;
    begin
      if new.name is null or btrim(new.name) = '' then
        new.name := new.title;
      end if;
    exception when others then null;
    end;
    return new;
  end
  $function$;
CREATE OR REPLACE FUNCTION public.protect_certificate_identity()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
begin
  if (new.id, new.serial, new.student_id, new.program_id, new.issue_date) is distinct from
     (old.id, old.serial, old.student_id, old.program_id, old.issue_date) then
    raise exception 'Certificate identity cannot be changed';
  end if;
  if old.status = 'Revoked' and new.status is distinct from old.status then raise exception 'Revocation cannot be reversed'; end if;
  return new;
end $function$;
CREATE OR REPLACE FUNCTION public.protect_profile_privileges()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  -- Service role, triggers (e.g. handle_new_user) and the SQL editor run as
  -- a role other than 'authenticated'/'anon' and are always trusted.
  if coalesce(auth.role(), '') not in ('authenticated', 'anon') then
    return new;
  end if;

  if tg_op = 'INSERT' then
    if new.role = 'Super Admin' and not public.is_super_admin() then
      raise exception 'Only a Super Admin can create a Super Admin account.';
    end if;

    if not public.has_permission('staff.manage') and not public.has_permission('students.manage') then
      if new.role <> 'Student' or new.status <> 'Pending Approval' then
        raise exception 'New accounts must self-register as a pending student.';
      end if;
    end if;

    return new;
  end if;

  -- tg_op = 'UPDATE'. Nobody may change their own role or status: this
  -- prevents both self-lockout and self-promotion.
  if new.id = auth.uid()
     and (new.role is distinct from old.role or new.status is distinct from old.status) then
    raise exception 'You cannot change your own role or status.';
  end if;

  -- Setting role = 'Super Admin', or touching a Super Admin's row, needs
  -- is_super_admin().
  if (old.role = 'Super Admin' or new.role = 'Super Admin') and not public.is_super_admin() then
    raise exception 'Only a Super Admin can change a Super Admin account.';
  end if;

  if new.role is distinct from old.role and not public.has_permission('staff.manage') then
    raise exception 'You do not have permission to change roles.';
  end if;

  if new.status is distinct from old.status then
    if old.role = 'Student' then
      if not public.has_permission('students.manage') then
        raise exception 'You do not have permission to change a student''s status.';
      end if;
    elsif not public.has_permission('staff.manage') then
      raise exception 'You do not have permission to change a staff member''s status.';
    end if;
  end if;

  if (new.program_ids is distinct from old.program_ids or new.cohort_ids is distinct from old.cohort_ids)
     and old.role = 'Student' and not public.has_permission('students.manage') then
    raise exception 'You do not have permission to assign programmes or cohorts.';
  end if;

  return new;
end;
$function$;
CREATE OR REPLACE FUNCTION public.protect_record_number()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
begin
  if tg_table_name = 'profiles' and (to_jsonb(new)->'account_number') is distinct from (to_jsonb(old)->'account_number') then
    raise exception 'Account numbers cannot be changed';
  elsif tg_table_name = 'programs' and (to_jsonb(new)->'course_number') is distinct from (to_jsonb(old)->'course_number') then
    raise exception 'Course numbers cannot be changed';
  end if;
  return new;
end $function$;
CREATE OR REPLACE FUNCTION public.protect_system_settings()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if coalesce(auth.role(), '') not in ('authenticated', 'anon') then
    return new;
  end if;

  if not public.has_permission('settings.manage') then
    if new.academy_name is distinct from old.academy_name
      or new.motto is distinct from old.motto
      or new.contact_email is distinct from old.contact_email
      or new.contact_phone is distinct from old.contact_phone
      or new.address is distinct from old.address
      or new.accreditation_no is distinct from old.accreditation_no
      or new.currency is distinct from old.currency
      or new.academic_year is distinct from old.academic_year
      or new.semester is distinct from old.semester
      or new.self_registration_open is distinct from old.self_registration_open
      or new.student_id_prefix is distinct from old.student_id_prefix
      or new.pass_mark is distinct from old.pass_mark
      or new.min_attendance is distinct from old.min_attendance
      or new.site_published is distinct from old.site_published
      or new.marketing_banner is distinct from old.marketing_banner
      or new.intake_status is distinct from old.intake_status
      or new.featured_program_ids is distinct from old.featured_program_ids
    then
      raise exception 'You do not have permission to change system settings.';
    end if;
  end if;

  if not public.has_permission('cms.manage') and new.website_settings is distinct from old.website_settings then
    raise exception 'You do not have permission to manage website content.';
  end if;

  return new;
end;
$function$;
CREATE OR REPLACE FUNCTION public.queue_account_congratulations(p_user_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_role text; v_status text; v_id uuid; v_mail_status text;
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  if not exists (select 1 from public.profiles where id = auth.uid() and status = 'Active') then raise exception 'active_account_required'; end if;
  select role, status into v_role, v_status from public.profiles where id = p_user_id;
  if not found then raise exception 'account_not_found'; end if;
  if v_role = 'Student' then
    if not public.has_permission('students.manage') then raise exception 'forbidden'; end if;
  elsif not public.has_permission('staff.manage') then raise exception 'forbidden';
  end if;
  if v_status not in ('Active', 'Pending Approval') then raise exception 'account_not_eligible'; end if;
  v_id := public._queue_account_congratulations(p_user_id);
  if v_id is null then raise exception 'confirmed_email_required'; end if;
  select status into v_mail_status from public.email_outbox where id = v_id;
  return jsonb_build_object('id', v_id, 'status', v_mail_status);
end;
$function$;
CREATE OR REPLACE FUNCTION public.queue_newsletter_campaign(p_template_id uuid, p_campaign_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_template public.email_templates%rowtype; v_sub public.newsletter_subscribers%rowtype; v_count int := 0; v_inserted uuid;
begin
  if not public.has_permission('settings.manage') then raise exception 'Not authorized'; end if;
  select * into v_template from public.email_templates where id = p_template_id;
  if not found then raise exception 'Save a valid template first'; end if;
  insert into public.newsletter_campaigns(id, template_id, subject, body, created_by)
  values (p_campaign_id, v_template.id, v_template.subject, v_template.body, auth.uid())
  on conflict (id) do nothing returning id into v_inserted;
  if v_inserted is null then
    select recipient_count into v_count from public.newsletter_campaigns where id = p_campaign_id;
    return v_count;
  end if;
  for v_sub in select * from public.newsletter_subscribers where status = 'active' loop
    perform public.enqueue_email(v_sub.email, v_sub.name, 'newsletter', v_template.subject,
      jsonb_build_object('body', v_template.body, 'subscriber_id', v_sub.id, 'campaign_id', p_campaign_id),
      null, 'newsletter:' || p_campaign_id::text || ':' || v_sub.id::text);
    v_count := v_count + 1;
  end loop;
  update public.newsletter_campaigns set recipient_count = v_count where id = p_campaign_id;
  return v_count;
end; $function$;
CREATE OR REPLACE FUNCTION public.quiz_visible_to_me(q uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (
    select 1 from public.quizzes qz
    where qz.id = q
      and qz.status = 'published'
      and (
        (qz.learning_unit_id is not null and exists (
          select 1
          from public.learning_units u
          join public.cohort_students cs on cs.cohort_id = u.cohort_id
          where u.id = qz.learning_unit_id and u.status = 'approved'
            and cs.student_id = auth.uid() and cs.active
        ))
        or (qz.learning_unit_id is null and qz.cohort_id is not null and exists (
          select 1 from public.cohort_students cs
          where cs.cohort_id = qz.cohort_id and cs.student_id = auth.uid() and cs.active
        ))
        or (qz.learning_unit_id is null and qz.program_id is not null and exists (
          select 1 from public.profiles p where p.id = auth.uid() and qz.program_id = any(p.program_ids)
        ))
        or (qz.learning_unit_id is null and qz.program_id is not null and exists (
          select 1 from public.cohort_students cs
          join public.cohorts c on c.id = cs.cohort_id
          where cs.student_id = auth.uid() and cs.active and c.program_id = qz.program_id
        ))
      )
  );
$function$;
CREATE OR REPLACE FUNCTION public.record_learning_progress(p_unit_id uuid, p_status text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_cohort uuid;
  v_enrollment public.course_enrollments%rowtype;
begin
  if auth.uid() is null then raise exception 'not_authenticated' using errcode = 'P0001'; end if;
  if p_status not in ('in_progress', 'completed') then
    raise exception 'invalid_progress_status' using errcode = 'P0001';
  end if;

  select cohort_id into v_cohort from public.learning_units where id = p_unit_id;
  if v_cohort is null then raise exception 'learning_unit_not_found' using errcode = 'P0002'; end if;

  -- This SECURITY DEFINER RPC bypasses the student_learning_progress RLS
  -- membership check entirely, so enforce it explicitly here. Staff
  -- (reviewers/cohort teachers) are left unrestricted, matching the existing
  -- staff bypass in _validate_student_learning_progress.
  if not (public.has_permission('academic_plans.approve') or public.is_cohort_teacher(v_cohort))
     and not public.is_cohort_member(v_cohort) then
    raise exception 'forbidden' using errcode = 'P0001';
  end if;

  insert into public.student_learning_progress (student_id, cohort_id, learning_unit_id, status, progress_percent, completed_at)
  values (auth.uid(), v_cohort, p_unit_id, p_status, case when p_status = 'completed' then 100 else 50 end,
    case when p_status = 'completed' then now() else null end)
  on conflict (student_id, cohort_id, learning_unit_id) do update
    set status = excluded.status, progress_percent = excluded.progress_percent, completed_at = excluded.completed_at;

  select * into v_enrollment from public.course_enrollments where cohort_id = v_cohort and student_id = auth.uid();

  return jsonb_build_object(
    'unit_id', p_unit_id, 'status', p_status,
    'progress_percent', v_enrollment.progress_percent,
    'completion_status', v_enrollment.completion_status
  );
end;
$function$;
CREATE OR REPLACE FUNCTION public.register_push_subscription(p_endpoint text, p_p256dh text, p_auth text, p_user_agent text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then
    raise exception 'Sign in to enable notifications' using errcode = '42501';
  end if;
  if coalesce(btrim(p_endpoint), '') = '' or coalesce(btrim(p_p256dh), '') = '' or coalesce(btrim(p_auth), '') = '' then
    raise exception 'Incomplete push subscription' using errcode = '22023';
  end if;

  insert into public.push_subscriptions (user_id, endpoint, p256dh, auth, user_agent, enabled, updated_at)
  values (v_user, p_endpoint, p_p256dh, p_auth, left(coalesce(p_user_agent, ''), 500), true, now())
  on conflict (endpoint) do update
    set user_id = v_user,
        p256dh = excluded.p256dh,
        auth = excluded.auth,
        user_agent = excluded.user_agent,
        enabled = true,
        updated_at = now();
end;
$function$;
CREATE OR REPLACE FUNCTION public.regrade_quiz(p_quiz_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  n int := 0;
  r record;
begin
  if not public.can_manage_quiz(p_quiz_id) then
    raise exception 'forbidden' using errcode = 'P0001';
  end if;
  for r in select id from public.quiz_attempts where quiz_id = p_quiz_id and status in ('submitted', 'auto_submitted') loop
    perform public._grade_quiz_attempt(r.id, null, true);
    n := n + 1;
  end loop;
  return n;
end;
$function$;
CREATE OR REPLACE FUNCTION public.reply_helpdesk_ticket(p_id uuid, p_ticket uuid, p_body text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare actor public.profiles%rowtype; ticket public.helpdesk_tickets%rowtype; existing public.helpdesk_messages%rowtype;
begin
  select * into actor from public.profiles where id = auth.uid() and status = 'Active';
  if not found then raise exception 'Active account required'; end if;
  select * into ticket from public.helpdesk_tickets where id = p_ticket for update;
  if not found or not (public.can_manage_helpdesk() or (actor.role = 'Student' and ticket.student_id = actor.id)) then
    raise exception 'Ticket unavailable or access denied';
  end if;
  select * into existing from public.helpdesk_messages where id = p_id;
  if found then
    if existing.ticket_id <> p_ticket or existing.author_id <> actor.id then raise exception 'Message ID unavailable'; end if;
    return existing.id;
  end if;
  if ticket.status <> 'open' then raise exception 'This ticket is closed. Ask staff to reopen it or create a new ticket'; end if;
  if p_body is null or length(btrim(p_body)) not between 1 and 10000 then raise exception 'Message must be 1–10000 characters'; end if;
  if (select count(*) from public.helpdesk_messages where ticket_id = p_ticket and author_id = actor.id and created_at > now() - interval '1 minute') >= 10 then
    raise exception 'Too many messages. Please wait a minute';
  end if;
  insert into public.helpdesk_messages(id, ticket_id, author_id, author_name, author_role, body)
    values(p_id, p_ticket, actor.id, coalesce(nullif(btrim(to_jsonb(actor)->>'name'), ''), nullif(btrim(actor.full_name), ''), 'Account holder'), actor.role, btrim(p_body));
  update public.helpdesk_tickets set updated_at = now() where id = p_ticket;
  return p_id;
end; $function$;
CREATE OR REPLACE FUNCTION public.request_newsletter_signup(p_email text, p_name text, p_consent text, p_hash text, p_link text, p_bucket text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_hits int; v_row public.newsletter_subscribers%rowtype;
begin
  delete from public.newsletter_signup_limits where expires_at < now();
  insert into public.newsletter_signup_limits(bucket, hits, expires_at)
  values (p_bucket, 1, now() + interval '1 hour')
  on conflict (bucket) do update set hits = newsletter_signup_limits.hits + 1
  returning hits into v_hits;
  if v_hits > 10 then return; end if;
  perform pg_advisory_xact_lock(hashtextextended(lower(p_email), 0));
  select * into v_row from public.newsletter_subscribers where email = lower(p_email) for update;
  if found and (v_row.status = 'active' or v_row.last_requested_at > now() - interval '15 minutes') then return; end if;
  insert into public.newsletter_subscribers(email, name, consent_text, confirmation_hash, confirmation_expires_at)
  values (lower(p_email), p_name, p_consent, p_hash, now() + interval '24 hours')
  on conflict (email) do update set name = excluded.name, status = 'pending',
    consent_text = excluded.consent_text, consent_at = now(), confirmed_at = null, unsubscribed_at = null,
    confirmation_hash = excluded.confirmation_hash, confirmation_expires_at = excluded.confirmation_expires_at,
    last_requested_at = now();
  perform public.enqueue_email(lower(p_email), p_name, 'newsletter_confirmation', 'Confirm your Africa of Hope newsletter subscription',
    jsonb_build_object('confirmation_url', p_link, 'confirmation_hash', p_hash), null, 'newsletter-confirm:' || p_hash);
end; $function$;
CREATE OR REPLACE FUNCTION public.retry_failed_emails()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_failed_count int;
  v_stale_count int;
begin
  if not public.has_permission('settings.manage') then
    raise exception 'forbidden' using errcode = 'P0001';
  end if;

  update public.email_outbox
    set status = 'queued', attempts = 0, last_error = null, send_after = now(), updated_at = now()
    where status = 'failed';
  get diagnostics v_failed_count = row_count;

  -- A row stuck in `sending` (e.g. the edge function crashed mid-send)
  -- never reaches 'failed', so the above update alone would never recover
  -- it. Anything claimed more than 15 minutes ago is treated as abandoned.
  update public.email_outbox
    set status = 'queued', attempts = coalesce(attempts, 0), last_error = 'reclaimed after being stuck in sending', send_after = now(), updated_at = now()
    where status = 'sending' and updated_at < now() - interval '15 minutes';
  get diagnostics v_stale_count = row_count;

  return v_failed_count + v_stale_count;
end;
$function$;
CREATE OR REPLACE FUNCTION public.review_academic_submission(p_entity_type text, p_entity_id uuid, p_decision text, p_note text DEFAULT ''::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  enrollment public.course_enrollments%rowtype;
  preview jsonb;
  result jsonb;
begin
  if auth.uid() is null then raise exception 'not_authenticated' using errcode = 'P0001'; end if;
  if p_entity_type not in ('enrollment', 'course_plan', 'class_session', 'learning_unit', 'training_material') then
    raise exception 'unsupported_entity_type' using errcode = 'P0001';
  end if;
  if p_decision not in ('approved', 'rejected', 'revision_requested') then
    raise exception 'invalid_decision' using errcode = 'P0001';
  end if;
  if p_decision in ('rejected', 'revision_requested') and btrim(coalesce(p_note, '')) = '' then
    raise exception 'decision_note_required' using errcode = 'P0001';
  end if;
  if (p_entity_type = 'training_material' and not public.has_permission('materials.approve'))
     or (p_entity_type <> 'training_material' and not public.has_permission('academic_plans.approve')) then
    raise exception 'forbidden' using errcode = 'P0001';
  end if;

  if p_entity_type = 'enrollment' then
    select student_id into enrollment.student_id from public.course_enrollments where id = p_entity_id;
    if enrollment.student_id is null then raise exception 'not_found' using errcode = 'P0002'; end if;
    -- Match the submit path's lock order to avoid a row/advisory deadlock.
    perform pg_advisory_xact_lock(hashtext('student:' || enrollment.student_id::text)::bigint);
    select * into enrollment from public.course_enrollments where id = p_entity_id for update;
    if enrollment.id is null then raise exception 'not_found' using errcode = 'P0002'; end if;
    if enrollment.status <> 'submitted' then raise exception 'submission_not_pending_review' using errcode = 'P0001'; end if;

    -- Serialise approvals for both the student and cohort so capacity and
    -- cross-course timetable checks cannot race.
    perform 1 from public.cohorts where id = enrollment.cohort_id for update;
    preview := public._course_enrollment_preview(enrollment.student_id, enrollment.cohort_id, false);
    if p_decision = 'approved' and not (preview ->> 'allowed')::boolean then
      raise exception 'enrollment_conflict_detected' using errcode = 'P0001', detail = preview::text;
    end if;

    update public.course_enrollments
      set status = p_decision,
          workload = jsonb_build_object('active_course_count', preview -> 'active_course_count', 'weekly_hours', preview -> 'weekly_hours'),
          conflict_warnings = preview -> 'conflicts', workload_warnings = preview -> 'warnings', reviewed_at = now(),
          approved_at = case when p_decision = 'approved' then now() else null end,
          reviewed_by = auth.uid(), revision_note = btrim(coalesce(p_note, ''))
      where id = enrollment.id
      returning * into enrollment;
    return jsonb_build_object('entity_type', p_entity_type, 'entity_id', enrollment.id, 'status', enrollment.status, 'conflicts', enrollment.conflict_warnings, 'warnings', enrollment.workload_warnings);
  elsif p_entity_type = 'course_plan' then
    update public.teacher_course_plans set status = p_decision, reviewed_at = now(), reviewed_by = auth.uid(),
      approved_at = case when p_decision = 'approved' then now() else null end, revision_note = nullif(btrim(coalesce(p_note, '')), '')
      where id = p_entity_id and status = 'submitted'
      returning jsonb_build_object('entity_type', p_entity_type, 'entity_id', id, 'status', status) into result;
  elsif p_entity_type = 'class_session' then
    perform pg_advisory_xact_lock(hashtext('teacher:' || teacher_id::text)::bigint),
           pg_advisory_xact_lock(hashtext('cohort:' || cohort_id::text)::bigint)
    from public.class_sessions where id = p_entity_id;
    update public.class_sessions set status = p_decision, reviewed_at = now(), reviewed_by = auth.uid(),
      approved_at = case when p_decision = 'approved' then now() else null end, revision_note = nullif(btrim(coalesce(p_note, '')), '')
      where id = p_entity_id and status = 'submitted'
      returning jsonb_build_object('entity_type', p_entity_type, 'entity_id', id, 'status', status) into result;
  elsif p_entity_type = 'learning_unit' then
    update public.learning_units set status = p_decision, reviewed_at = now(), reviewed_by = auth.uid(), revision_note = nullif(btrim(coalesce(p_note, '')), '')
      where id = p_entity_id and status = 'submitted'
      returning jsonb_build_object('entity_type', p_entity_type, 'entity_id', id, 'status', status) into result;
  else
    update public.training_materials set status = p_decision, reviewed_at = now(), reviewed_by = auth.uid(),
      approved_at = case when p_decision = 'approved' then now() else null end, revision_note = nullif(btrim(coalesce(p_note, '')), '')
      where id = p_entity_id and status = 'submitted'
      returning jsonb_build_object('entity_type', p_entity_type, 'entity_id', id, 'status', status) into result;
  end if;
  if result is null then raise exception 'not_found_or_not_pending_review' using errcode = 'P0002'; end if;
  return result;
end;
$function$;
CREATE OR REPLACE FUNCTION public.review_payment(p_submission_id uuid, p_decision text, p_note text, p_ledger_amount_usd numeric DEFAULT NULL::numeric)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_sub public.payment_submissions%rowtype;
  v_method text;
  v_fee_id uuid;
  v_receipt text;
  v_seq bigint;
  v_student_email text;
  v_student_name text;
  v_ledger_amount numeric(12, 2);
  v_fee_reference text;
begin
  if auth.uid() is null then raise exception 'not_authenticated' using errcode = 'P0001'; end if;
  if not public.has_permission('payments.confirm') then
    raise exception 'forbidden' using errcode = 'P0001';
  end if;
  if coalesce(p_decision, '') not in ('confirm', 'reject') then
    raise exception 'invalid_decision' using errcode = 'P0001';
  end if;
  if p_decision = 'reject' and length(btrim(coalesce(p_note, ''))) = 0 then
    raise exception 'rejection_note_required' using errcode = 'P0001';
  end if;

  select * into v_sub from public.payment_submissions where id = p_submission_id for update;
  if v_sub.id is null then raise exception 'payment_not_found' using errcode = 'P0002'; end if;
  if v_sub.status <> 'pending' then raise exception 'payment_not_pending' using errcode = 'P0001'; end if;

  -- The verified login identity's email, not the self-editable
  -- public.profiles.email column.
  select u.email, coalesce(p.full_name, p.name, '')
    into v_student_email, v_student_name
  from auth.users u
  left join public.profiles p on p.id = u.id
  where u.id = v_sub.student_id;

  if p_decision = 'confirm' then
    v_method := case v_sub.provider
      when 'mtn_momo' then 'MTN MoMo'
      when 'orange_money' then 'Orange Money'
      else v_sub.provider
    end;

    -- fee_transactions carries no currency column: the ledger is USD-only.
    -- A USD submission posts its own amount; an LRD submission requires the
    -- reviewer to supply the USD amount actually credited, and keeps the
    -- original LRD amount visible in the reference text instead.
    if v_sub.currency = 'USD' then
      v_ledger_amount := v_sub.amount;
      v_fee_reference := v_sub.transaction_reference;
    else
      if p_ledger_amount_usd is null or p_ledger_amount_usd <= 0 then
        raise exception 'ledger_amount_required' using errcode = 'P0001';
      end if;
      v_ledger_amount := p_ledger_amount_usd;
      v_fee_reference := v_sub.transaction_reference || ' (LRD ' || v_sub.amount::text || ')';
    end if;

    insert into public.fee_transactions (student_id, category, amount, transaction_date, method, reference)
    values (v_sub.student_id, v_sub.category, v_ledger_amount, v_sub.paid_on, v_method, v_fee_reference)
    returning id into v_fee_id;

    v_seq := nextval('public.payment_receipt_seq');
    v_receipt := 'AOH-RCPT-' || to_char(now(), 'YYYY') || '-'
      || lpad(v_seq::text, greatest(6, length(v_seq::text)), '0');

    update public.payment_submissions
      set status = 'confirmed', reviewed_by = auth.uid(), reviewed_at = now(),
          review_note = coalesce(p_note, ''), fee_transaction_id = v_fee_id, receipt_number = v_receipt,
          ledger_amount_usd = v_ledger_amount
      where id = p_submission_id;

    insert into public.notifications (recipient_id, kind, title, body, entity_type, entity_id)
    values (
      v_sub.student_id, 'payment_confirmed', 'Payment confirmed',
      'Your ' || v_method || ' payment of ' || v_sub.currency || ' ' || v_sub.amount::text
        || ' was confirmed. Receipt ' || v_receipt || '.',
      'payment_submission', p_submission_id
    );

    perform public.enqueue_email(
      v_student_email, v_student_name, 'payment_receipt',
      'Your Africa of Hope payment receipt ' || v_receipt,
      jsonb_build_object(
        'receipt_number', v_receipt, 'amount', v_sub.amount, 'currency', v_sub.currency,
        'ledger_amount_usd', v_ledger_amount,
        'category', v_sub.category, 'method', v_method, 'paid_on', v_sub.paid_on,
        'transaction_reference', v_sub.transaction_reference
      ),
      v_sub.student_id,
      'payment_receipt:' || p_submission_id::text
    );

    return jsonb_build_object('id', p_submission_id, 'status', 'confirmed', 'receipt_number', v_receipt);
  else
    update public.payment_submissions
      set status = 'rejected', reviewed_by = auth.uid(), reviewed_at = now(), review_note = p_note
      where id = p_submission_id;

    insert into public.notifications (recipient_id, kind, title, body, entity_type, entity_id)
    values (
      v_sub.student_id, 'payment_rejected', 'Payment report was rejected',
      coalesce(nullif(p_note, ''), 'Your reported payment could not be confirmed.'),
      'payment_submission', p_submission_id
    );

    perform public.enqueue_email(
      v_student_email, v_student_name, 'payment_rejected',
      'Your Africa of Hope payment report needs attention',
      jsonb_build_object(
        'amount', v_sub.amount, 'currency', v_sub.currency, 'category', v_sub.category,
        'transaction_reference', v_sub.transaction_reference, 'review_note', p_note
      ),
      v_sub.student_id,
      'payment_rejected:' || p_submission_id::text
    );

    return jsonb_build_object('id', p_submission_id, 'status', 'rejected', 'receipt_number', null);
  end if;
end;
$function$;
CREATE OR REPLACE FUNCTION public.revoke_certificate(p_certificate_id uuid, p_reason text)
 RETURNS certificates
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_certificate public.certificates%rowtype;
begin
  if auth.uid() is null or not exists (
    select 1 from public.profiles where id = auth.uid() and status = 'Active' and role in ('School Admin', 'Super Admin')
  ) then raise exception 'Only active School Admin or Super Admin accounts may revoke certificates'; end if;
  if p_reason is null or length(btrim(p_reason)) not between 5 and 1000 then raise exception 'Provide a revocation reason (5–1000 characters)'; end if;
  select * into v_certificate from public.certificates where id = p_certificate_id for update;
  if v_certificate.id is null then raise exception 'Certificate not found'; end if;
  if v_certificate.status = 'Revoked' then return v_certificate; end if;
  update public.certificates set status = 'Revoked', revoked_at = now(), revoked_by = auth.uid(), revocation_reason = btrim(p_reason)
    where id = p_certificate_id returning * into v_certificate;
  return v_certificate;
end $function$;
CREATE OR REPLACE FUNCTION public.save_quiz_answer(p_attempt_id uuid, p_question_id uuid, p_answer jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  att record;
  q record;
  valid boolean := false;
  grace interval := interval '10 seconds';
begin
  select * into att from public.quiz_attempts where id = p_attempt_id for update;
  if att.id is null or att.student_id <> auth.uid() then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  if att.status <> 'in_progress' then
    raise exception 'attempt_closed' using errcode = 'P0001';
  end if;
  if not (p_question_id = any(att.question_order)) then
    raise exception 'invalid_question' using errcode = 'P0001';
  end if;

  if att.deadline_at is not null and now() > att.deadline_at + grace then
    perform public._grade_quiz_attempt(p_attempt_id, 'auto_submitted');
    return jsonb_build_object('status', 'time_up');
  end if;

  select * into q from public.quiz_questions where id = p_question_id;

  if q.type = 'single' then
    valid := jsonb_typeof(p_answer) = 'string' and exists (
      select 1 from jsonb_array_elements(q.options) o where (o ->> 'id') = (p_answer #>> '{}')
    );
  elsif q.type = 'multi' then
    valid := jsonb_typeof(p_answer) = 'array' and not exists (
      select 1 from jsonb_array_elements_text(p_answer) a
      where not exists (select 1 from jsonb_array_elements(q.options) o where (o ->> 'id') = a.value)
    );
  elsif q.type = 'true_false' then
    valid := jsonb_typeof(p_answer) = 'boolean';
  elsif q.type = 'short' then
    valid := jsonb_typeof(p_answer) = 'string' and length(p_answer #>> '{}') <= 500;
  end if;

  if not valid then
    raise exception 'invalid_answer' using errcode = 'P0001';
  end if;

  update public.quiz_attempts
    set answers = answers || jsonb_build_object(p_question_id::text, p_answer)
    where id = p_attempt_id;

  return jsonb_build_object('saved_at', now(), 'server_now', now());
end;
$function$;
CREATE OR REPLACE FUNCTION public.set_helpdesk_status(p_ticket uuid, p_status text, p_reason text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare actor public.profiles%rowtype; ticket public.helpdesk_tickets%rowtype;
begin
  if not public.can_manage_helpdesk() then raise exception 'Helpdesk permission required'; end if;
  select * into actor from public.profiles where id = auth.uid() and status = 'Active';
  select * into ticket from public.helpdesk_tickets where id = p_ticket for update;
  if not found then raise exception 'Ticket not found'; end if;
  if p_status is null or p_status not in ('open', 'closed') then raise exception 'Invalid status'; end if;
  if ticket.status = p_status then return; end if;
  if p_reason is null or length(btrim(p_reason)) not between 1 and 2000 then raise exception 'Provide a reason (up to 2000 characters)'; end if;
  update public.helpdesk_tickets set status = p_status, updated_at = now() where id = p_ticket;
  insert into public.helpdesk_messages(ticket_id, author_id, author_name, author_role, kind, body)
    values(p_ticket, actor.id, coalesce(nullif(btrim(to_jsonb(actor)->>'name'), ''), nullif(btrim(actor.full_name), ''), 'Account holder'), actor.role, case when p_status = 'closed' then 'closed' else 'reopened' end, btrim(p_reason));
end; $function$;
CREATE OR REPLACE FUNCTION public.start_classwork(p_assignment_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_assignment public.assignments%rowtype;
  v_cohort_end date;
  v_unit_status text;
  v_unit_available timestamptz;
  v_sub public.submissions%rowtype;
begin
  if auth.uid() is null then raise exception 'not_authenticated' using errcode = 'P0001'; end if;

  select * into v_assignment from public.assignments where id = p_assignment_id;
  if v_assignment.id is null then raise exception 'assignment_not_found' using errcode = 'P0002'; end if;
  if not public.is_cohort_member(v_assignment.cohort_id) then
    raise exception 'forbidden' using errcode = 'P0001';
  end if;

  select end_date into v_cohort_end from public.cohorts where id = v_assignment.cohort_id;
  if v_cohort_end is not null and now()::date > v_cohort_end then
    raise exception 'course_window_closed' using errcode = 'P0001';
  end if;

  if v_assignment.learning_unit_id is not null then
    select status, available_from into v_unit_status, v_unit_available
    from public.learning_units where id = v_assignment.learning_unit_id;
    if v_unit_status is distinct from 'approved' or (v_unit_available is not null and v_unit_available > now()) then
      raise exception 'unit_not_available' using errcode = 'P0001';
    end if;
  end if;

  -- INSERT ... ON CONFLICT DO NOTHING + re-select avoids a race between a
  -- SELECT-then-INSERT when a student double-clicks "Start" (two concurrent
  -- calls); the loser of the race simply re-selects the winner's row below
  -- and both calls return the same submission/started_at.
  insert into public.submissions (assignment_id, student_id, status, started_at)
  values (p_assignment_id, auth.uid(), 'In Progress', now())
  on conflict (assignment_id, student_id) do nothing;

  select * into v_sub from public.submissions
  where assignment_id = p_assignment_id and student_id = auth.uid() for update;

  if v_sub.status in ('Submitted', 'Graded') then
    raise exception 'classwork_already_submitted' using errcode = 'P0001';
  elsif v_sub.started_at is null then
    -- A placeholder row with no started_at (for example 'Missing' seeded by a
    -- gradebook flow) starts the timer now. A row that already has a
    -- started_at keeps it, so the timer is never restarted.
    update public.submissions set status = 'In Progress', started_at = now()
    where id = v_sub.id
    returning * into v_sub;
  end if;

  return jsonb_build_object(
    'submission_id', v_sub.id,
    'started_at', v_sub.started_at,
    'deadline_at', case when v_assignment.time_limit_minutes is not null
      then v_sub.started_at + (v_assignment.time_limit_minutes || ' minutes')::interval
      else null end,
    'time_limit_minutes', v_assignment.time_limit_minutes,
    'status', v_sub.status,
    'server_now', now()
  );
end;
$function$;
CREATE OR REPLACE FUNCTION public.start_quiz_attempt(p_quiz_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  qz record;
  existing record;
  attempts_used int;
  new_id uuid;
  new_no int;
  qorder uuid[];
  oorder jsonb := '{}'::jsonb;
  q record;
  opt_ids jsonb;
  deadline timestamptz;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = 'P0001';
  end if;
  if not public.has_permission('quizzes.take') then
    raise exception 'forbidden' using errcode = 'P0001';
  end if;
  if not public.quiz_visible_to_me(p_quiz_id) then
    raise exception 'not_visible' using errcode = 'P0001';
  end if;

  perform pg_advisory_xact_lock(hashtext(p_quiz_id::text || ':' || auth.uid()::text)::bigint);

  select * into qz from public.quizzes where id = p_quiz_id;
  if qz.id is null then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  if (qz.opens_at is not null and now() < qz.opens_at) or (qz.closes_at is not null and now() >= qz.closes_at) then
    raise exception 'quiz_closed' using errcode = 'P0001';
  end if;

  select * into existing from public.quiz_attempts
    where quiz_id = p_quiz_id and student_id = auth.uid() and status = 'in_progress'
    order by attempt_no desc limit 1
    for update;

  if existing.id is not null and existing.deadline_at is not null
    and now() > existing.deadline_at + interval '10 seconds'
  then
    perform public._grade_quiz_attempt(existing.id, 'auto_submitted');
    existing.id := null;
  end if;

  if existing.id is not null then
    new_id := existing.id;
  else
    select coalesce(max(attempt_no), 0) into attempts_used
      from public.quiz_attempts where quiz_id = p_quiz_id and student_id = auth.uid();
    if attempts_used >= qz.max_attempts then
      raise exception 'attempts_exhausted' using errcode = 'P0001';
    end if;

    select array_agg(id order by (case when qz.shuffle_questions then random() else 0 end), position)
      into qorder
      from public.quiz_questions where quiz_id = p_quiz_id;
    if qorder is null or array_length(qorder, 1) = 0 then
      raise exception 'no_questions' using errcode = 'P0001';
    end if;

    for q in select * from public.quiz_questions where quiz_id = p_quiz_id loop
      if jsonb_array_length(q.options) > 0 then
        if qz.shuffle_options then
          select jsonb_agg(elem order by random()) into opt_ids from jsonb_array_elements(q.options) elem;
        else
          opt_ids := q.options;
        end if;
        oorder := oorder || jsonb_build_object(
          q.id::text, (select jsonb_agg(e -> 'id') from jsonb_array_elements(opt_ids) e)
        );
      end if;
    end loop;

    new_no := attempts_used + 1;
    deadline := case
      when qz.time_limit_minutes is not null then
        least(now() + (qz.time_limit_minutes || ' minutes')::interval,
              coalesce(qz.closes_at, now() + (qz.time_limit_minutes || ' minutes')::interval))
      else qz.closes_at
    end;

    insert into public.quiz_attempts (
      quiz_id, student_id, attempt_no, status, started_at, deadline_at, question_order, option_order, answers
    ) values (
      p_quiz_id, auth.uid(), new_no, 'in_progress', now(), deadline, qorder, oorder, '{}'::jsonb
    ) returning id into new_id;
  end if;

  return public._attempt_payload(new_id);
end;
$function$;
CREATE OR REPLACE FUNCTION public.submit_academic_item(p_entity_type text, p_entity_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare result jsonb;
begin
  if auth.uid() is null then raise exception 'not_authenticated' using errcode = 'P0001'; end if;
  if p_entity_type = 'course_plan' then
    update public.teacher_course_plans set status = 'submitted', submitted_at = now(), revision_note = null
      where id = p_entity_id and teacher_id = auth.uid() and status in ('draft', 'revision_requested')
      returning jsonb_build_object('entity_type', p_entity_type, 'entity_id', id, 'status', status) into result;
  elsif p_entity_type = 'class_session' then
    update public.class_sessions set status = 'submitted', submitted_at = now(), revision_note = null
      where id = p_entity_id and teacher_id = auth.uid() and status in ('draft', 'revision_requested')
      returning jsonb_build_object('entity_type', p_entity_type, 'entity_id', id, 'status', status) into result;
  elsif p_entity_type = 'learning_unit' then
    update public.learning_units set status = 'submitted', submitted_at = now(), revision_note = null
      where id = p_entity_id and created_by = auth.uid() and status in ('draft', 'revision_requested')
      returning jsonb_build_object('entity_type', p_entity_type, 'entity_id', id, 'status', status) into result;
  elsif p_entity_type = 'training_material' then
    update public.training_materials set status = 'submitted', submitted_at = now(), revision_note = null
      where id = p_entity_id and created_by = auth.uid() and status in ('draft', 'revision_requested')
      returning jsonb_build_object('entity_type', p_entity_type, 'entity_id', id, 'status', status) into result;
  else
    raise exception 'unsupported_entity_type' using errcode = 'P0001';
  end if;
  if result is null then raise exception 'not_found_or_not_submittable' using errcode = 'P0002'; end if;
  return result;
end;
$function$;
CREATE OR REPLACE FUNCTION public.submit_classwork(p_assignment_id uuid, p_response_text text, p_attachment_path text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_assignment public.assignments%rowtype;
  v_sub public.submissions%rowtype;
  v_response text;
  v_attachment text;
  v_is_late boolean;
  v_cohort_teacher uuid;
begin
  if auth.uid() is null then raise exception 'not_authenticated' using errcode = 'P0001'; end if;

  select * into v_assignment from public.assignments where id = p_assignment_id;
  if v_assignment.id is null then raise exception 'assignment_not_found' using errcode = 'P0002'; end if;
  -- Re-check cohort membership at submit time too, in case the student was
  -- removed from the cohort between starting and submitting the classwork.
  if not public.is_cohort_member(v_assignment.cohort_id) then
    raise exception 'forbidden' using errcode = 'P0001';
  end if;

  select * into v_sub from public.submissions
  where assignment_id = p_assignment_id and student_id = auth.uid() for update;
  if v_sub.id is null or v_sub.started_at is null then
    raise exception 'classwork_not_started' using errcode = 'P0001';
  end if;
  if v_sub.status in ('Submitted', 'Graded') then
    raise exception 'classwork_already_submitted' using errcode = 'P0001';
  end if;

  v_response := coalesce(p_response_text, '');
  v_attachment := nullif(btrim(coalesce(p_attachment_path, '')), '');

  if v_attachment is not null then
    if v_attachment not like (p_assignment_id::text || '/' || auth.uid()::text || '/%') then
      raise exception 'invalid_attachment_path' using errcode = 'P0001';
    end if;
    if not exists (select 1 from storage.objects where bucket_id = 'classwork-submissions' and name = v_attachment) then
      raise exception 'attachment_not_found' using errcode = 'P0001';
    end if;
  end if;

  if length(btrim(v_response)) = 0 and v_attachment is null then
    raise exception 'classwork_empty' using errcode = 'P0001';
  end if;

  v_is_late := (
    v_assignment.time_limit_minutes is not null
    and now() > v_sub.started_at + (v_assignment.time_limit_minutes || ' minutes')::interval + interval '2 minutes'
  ) or (v_assignment.due_date is not null and now()::date > v_assignment.due_date);

  update public.submissions
  set status = 'Submitted',
      submitted_at = now(),
      response_text = v_response,
      attachment_path = v_attachment,
      time_spent_seconds = greatest(0, extract(epoch from (now() - v_sub.started_at))::integer),
      is_late = v_is_late
  where id = v_sub.id
  returning * into v_sub;

  select teacher_id into v_cohort_teacher from public.cohorts where id = v_assignment.cohort_id;
  if v_cohort_teacher is not null then
    insert into public.notifications (recipient_id, kind, title, body, entity_type, entity_id)
    values (
      v_cohort_teacher, 'classwork_submitted', 'Classwork submitted',
      coalesce((select full_name from public.profiles where id = auth.uid()), 'A student')
        || ' submitted "' || v_assignment.title || '"' || case when v_is_late then ' (late).' else '.' end,
      'submission', v_sub.id
    );
  end if;

  return jsonb_build_object(
    'submission_id', v_sub.id, 'status', v_sub.status, 'is_late', v_sub.is_late, 'submitted_at', v_sub.submitted_at
  );
end;
$function$;
CREATE OR REPLACE FUNCTION public.submit_course_enrollment(p_cohort_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  preview jsonb;
  enrollment public.course_enrollments%rowtype;
begin
  if auth.uid() is null then raise exception 'not_authenticated' using errcode = 'P0001'; end if;
  if not public.has_permission('courses.enroll') then
    raise exception 'forbidden' using errcode = 'P0001';
  end if;
  if not exists (select 1 from public.profiles where id = auth.uid() and role = 'Student' and status = 'Active') then
    raise exception 'active_student_required' using errcode = 'P0001';
  end if;

  perform pg_advisory_xact_lock(hashtext('student:' || auth.uid()::text)::bigint);

  select * into enrollment from public.course_enrollments
  where cohort_id = p_cohort_id and student_id = auth.uid() for update;

  if enrollment.id is not null and enrollment.status = 'approved' then
    return jsonb_build_object('allowed', true, 'conflicts', '[]'::jsonb, 'warnings', '[]'::jsonb,
      'weekly_hours', coalesce((enrollment.workload ->> 'weekly_hours')::numeric, 0),
      'enrollment_id', enrollment.id, 'status', enrollment.status, 'already_approved', true);
  end if;
  if enrollment.id is not null and enrollment.status not in ('draft', 'rejected', 'revision_requested') then
    raise exception 'enrollment_not_submittable' using errcode = 'P0001';
  end if;

  preview := public._course_enrollment_preview(auth.uid(), p_cohort_id);
  if not (preview ->> 'allowed')::boolean then
    raise exception 'enrollment_not_allowed' using errcode = 'P0001', detail = preview::text;
  end if;

  if enrollment.id is null then
    insert into public.course_enrollments (cohort_id, student_id, status, workload, conflict_warnings, workload_warnings, submitted_at)
    values (
      p_cohort_id, auth.uid(), 'submitted',
      jsonb_build_object('active_course_count', preview -> 'active_course_count', 'weekly_hours', preview -> 'weekly_hours'),
      preview -> 'conflicts', preview -> 'warnings', now()
    )
    returning * into enrollment;
  else
    update public.course_enrollments
      set status = 'submitted',
          workload = jsonb_build_object('active_course_count', preview -> 'active_course_count', 'weekly_hours', preview -> 'weekly_hours'),
          conflict_warnings = preview -> 'conflicts', workload_warnings = preview -> 'warnings', submitted_at = now(),
          reviewed_at = null, reviewed_by = null, revision_note = ''
      where id = enrollment.id
      returning * into enrollment;
  end if;

  return preview || jsonb_build_object('enrollment_id', enrollment.id, 'status', enrollment.status);
end;
$function$;
CREATE OR REPLACE FUNCTION public.submit_course_enrollment_with_arrangement(p_cohort_id uuid, p_arrangement text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  result jsonb;
  enrollment public.course_enrollments%rowtype;
  allowed_modes text[];
begin
  if p_arrangement is null
     or p_arrangement not in ('self_paced', 'blended', 'full_onsite') then
    raise exception 'invalid_learning_arrangement' using errcode = 'P0001';
  end if;

  select p.delivery_modes into allowed_modes
  from public.cohorts c
  join public.programs p on p.id = c.program_id
  where c.id = p_cohort_id;

  if not (
    p_arrangement = any(coalesce(allowed_modes, array['blended']::text[]))
  ) then
    raise exception 'learning_arrangement_not_offered' using errcode = 'P0001';
  end if;

  result := public.submit_course_enrollment(p_cohort_id);

  if (result ->> 'enrollment_id') is not null then
    select *
    into enrollment
    from public.course_enrollments
    where id = (result ->> 'enrollment_id')::uuid;

    update public.course_enrollments
    set learning_arrangement = p_arrangement,
        arrangement_changed_at = case
          when learning_arrangement = p_arrangement then arrangement_changed_at
          else now()
        end,
        arrangement_config = jsonb_build_object(
          'attendance_required', p_arrangement <> 'self_paced'
        )
    where id = enrollment.id;

    if enrollment.learning_arrangement is distinct from p_arrangement then
      insert into public.enrollment_arrangement_history (
        enrollment_id,
        previous_arrangement,
        next_arrangement,
        reason
      )
      values (
        enrollment.id,
        enrollment.learning_arrangement,
        p_arrangement,
        'Student enrollment submission'
      );
    end if;
  end if;

  return result || jsonb_build_object('learning_arrangement', p_arrangement);
end;
$function$;
CREATE OR REPLACE FUNCTION public.submit_payment(p_channel_id uuid, p_amount numeric, p_currency text, p_category text, p_payer_phone text, p_transaction_reference text, p_paid_on date, p_note text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_reference text;
  v_provider text;
  v_submission_id uuid;
  v_category text;
  v_phone text;
  v_phone_digits text;
  v_note text;
begin
  if auth.uid() is null then raise exception 'not_authenticated' using errcode = 'P0001'; end if;
  if not public.has_permission('payments.submit') then
    raise exception 'forbidden' using errcode = 'P0001';
  end if;
  if not exists (select 1 from public.profiles where id = auth.uid() and status = 'Active') then
    raise exception 'active_account_required' using errcode = 'P0001';
  end if;

  if p_amount is null or p_amount <= 0 then
    raise exception 'invalid_amount' using errcode = 'P0001';
  end if;
  if coalesce(p_currency, '') not in ('USD', 'LRD') then
    raise exception 'invalid_currency' using errcode = 'P0001';
  end if;
  if p_paid_on is null then
    raise exception 'paid_on_required' using errcode = 'P0001';
  end if;
  if p_channel_id is null then
    raise exception 'channel_required' using errcode = 'P0001';
  end if;

  v_phone := btrim(coalesce(p_payer_phone, ''));
  v_phone_digits := regexp_replace(v_phone, '[[:space:]-]', '', 'g');
  if v_phone_digits !~ '^\+?[0-9]{7,15}$' then
    raise exception 'invalid_payer_phone' using errcode = 'P0001';
  end if;

  v_category := coalesce(nullif(btrim(p_category), ''), 'Tuition');
  if length(v_category) > 60 then
    raise exception 'category_too_long' using errcode = 'P0001';
  end if;

  v_note := coalesce(p_note, '');
  if length(v_note) > 500 then
    raise exception 'note_too_long' using errcode = 'P0001';
  end if;

  v_reference := upper(btrim(coalesce(p_transaction_reference, '')));
  if length(v_reference) < 4 or length(v_reference) > 64 then
    raise exception 'invalid_transaction_reference' using errcode = 'P0001';
  end if;

  select provider into v_provider from public.payment_channels where id = p_channel_id and active;
  if v_provider is null then
    raise exception 'channel_not_found' using errcode = 'P0002';
  end if;

  -- Mirrors payment_submissions_provider_reference_active_key: a reference
  -- can be reused once its earlier submission was rejected.
  if exists (
    select 1 from public.payment_submissions
    where provider = v_provider and transaction_reference = v_reference and status <> 'rejected'
  ) then
    raise exception 'payment_reference_used' using errcode = 'P0001';
  end if;

  insert into public.payment_submissions (
    student_id, channel_id, provider, amount, currency, category,
    payer_phone, transaction_reference, paid_on, note
  ) values (
    auth.uid(), p_channel_id, v_provider, p_amount, p_currency,
    v_category, v_phone, v_reference, p_paid_on, v_note
  )
  returning id into v_submission_id;

  insert into public.notifications (recipient_id, kind, title, body, entity_type, entity_id)
  select p.id, 'payment_submitted', 'New mobile money payment reported',
    'A ' || v_provider || ' payment of ' || p_currency || ' ' || p_amount::text || ' was reported for review.',
    'payment_submission', v_submission_id
  from public.profiles p
  where p.status = 'Active'
    and (p.role = 'Super Admin' or exists (
      select 1 from public.role_permissions rp where rp.role = p.role and rp.permission = 'payments.confirm'
    ));

  return v_submission_id;
exception when unique_violation then
  raise exception 'payment_reference_used' using errcode = 'P0001';
end;
$function$;
CREATE OR REPLACE FUNCTION public.submit_quiz_attempt(p_attempt_id uuid, p_answers jsonb DEFAULT NULL::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  att record;
  merged jsonb;
  k text;
  v jsonb;
  grace interval := interval '10 seconds';
  late boolean;
  result jsonb;
begin
  select * into att from public.quiz_attempts where id = p_attempt_id for update;
  if att.id is null or att.student_id <> auth.uid() then
    raise exception 'not_found' using errcode = 'P0002';
  end if;

  if att.status <> 'in_progress' then
    return jsonb_build_object(
      'score', att.score, 'max_score', att.max_score, 'percent', att.percent, 'passed', att.passed,
      'status', att.status, 'submitted_at', att.submitted_at, 'review_available', true
    );
  end if;

  late := att.deadline_at is not null and now() > att.deadline_at + grace;

  if not late and p_answers is not null then
    merged := att.answers;
    for k, v in select * from jsonb_each(p_answers) loop
      begin
        if k::uuid = any(att.question_order) then
          merged := merged || jsonb_build_object(k, v);
        end if;
      exception when others then
        null;
      end;
    end loop;
    update public.quiz_attempts set answers = merged where id = p_attempt_id;
  end if;

  select public._grade_quiz_attempt(p_attempt_id, case when late then 'auto_submitted' else 'submitted' end)
    into result;
  return result || jsonb_build_object('review_available', true);
end;
$function$;
CREATE OR REPLACE FUNCTION public.sync_aptitude_to_entrance()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
begin
  update public.entrance_settings set updated_at = now() where id = new.id;
  return new;
end $function$;
CREATE OR REPLACE FUNCTION public.teaches_student(s uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (
    select 1 from public.cohort_students cs
    join public.cohorts c on c.id = cs.cohort_id
    where cs.student_id = s and c.teacher_id = auth.uid()
  );
$function$;
CREATE OR REPLACE FUNCTION public.update_helpdesk_ticket_status(p_ticket_id uuid, p_status text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ begin if not public.can_manage_helpdesk() then raise exception 'Not authorized'; end if; if p_status not in ('open','closed') then raise exception 'Invalid status'; end if; update public.helpdesk_tickets set status = p_status, updated_at = now() where id = p_ticket_id; if not found then raise exception 'Ticket not found'; end if; end; $function$;
CREATE OR REPLACE FUNCTION public.verify_public_certificate(p_serial text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_result jsonb;
begin
  if p_serial is null or length(btrim(p_serial)) not between 1 and 80 then
    raise exception 'A certificate serial between 1 and 80 characters is required';
  end if;
  select jsonb_build_object(
    'serial', c.serial, 'issueDate', c.issue_date, 'honors', c.honors,
    'grade', c.grade, 'status', case when c.status = 'Valid' then 'Valid' else 'Revoked' end,
    'certificateType', coalesce(c.certificate_type, 'Certificate of Completion'),
    'completionDate', c.completion_date,
    'holderName', coalesce(p.name, p.full_name, 'Not recorded'),
    'programTitle', coalesce(pr.title, 'Not recorded'),
    'revokedAt', c.revoked_at
  ) into v_result
  from public.certificates c
  left join public.profiles p on p.id = c.student_id
  left join public.programs pr on pr.id = c.program_id
  where lower(btrim(c.serial)) = lower(btrim(p_serial))
  limit 1;
  return v_result;
end $function$;

-- ---------------------------------------------------------------------------
-- Triggers
-- ---------------------------------------------------------------------------
CREATE TRIGGER aptitude_sync_to_entrance AFTER INSERT OR UPDATE ON aptitude_control_settings FOR EACH ROW EXECUTE FUNCTION sync_aptitude_to_entrance();
CREATE TRIGGER assignments_validate_learning_unit BEFORE INSERT OR UPDATE ON assignments FOR EACH ROW EXECUTE FUNCTION _validate_learning_unit_component();
CREATE TRIGGER attendance_notify AFTER INSERT OR UPDATE OF status ON attendance FOR EACH ROW EXECUTE FUNCTION _notify_attendance();
CREATE TRIGGER blog_posts_touch BEFORE UPDATE ON blog_posts FOR EACH ROW EXECUTE FUNCTION _blog_payments_touch();
CREATE TRIGGER log_certificate_event AFTER INSERT OR UPDATE OF status ON certificates FOR EACH ROW EXECUTE FUNCTION log_certificate_event();
CREATE TRIGGER protect_certificate_identity BEFORE UPDATE ON certificates FOR EACH ROW EXECUTE FUNCTION protect_certificate_identity();
CREATE TRIGGER class_sessions_audit AFTER INSERT OR UPDATE OF status ON class_sessions FOR EACH ROW EXECUTE FUNCTION _record_approval_event('class_session');
CREATE TRIGGER class_sessions_notify AFTER INSERT OR UPDATE OF status ON class_sessions FOR EACH ROW EXECUTE FUNCTION _notify_academic_status('class_session');
CREATE TRIGGER class_sessions_notify_schedule AFTER UPDATE OF session_date, starts_at, ends_at, room ON class_sessions FOR EACH ROW EXECUTE FUNCTION _notify_schedule_updated();
CREATE TRIGGER class_sessions_touch BEFORE UPDATE ON class_sessions FOR EACH ROW EXECUTE FUNCTION _touch_academic_row();
CREATE TRIGGER class_sessions_validate BEFORE INSERT OR UPDATE ON class_sessions FOR EACH ROW EXECUTE FUNCTION _validate_class_session();
CREATE TRIGGER course_completions_touch BEFORE UPDATE ON course_completions FOR EACH ROW EXECUTE FUNCTION _touch_academic_row();
CREATE TRIGGER course_enrollments_audit AFTER INSERT OR UPDATE OF status ON course_enrollments FOR EACH ROW EXECUTE FUNCTION _record_approval_event('enrollment');
CREATE TRIGGER course_enrollments_notify AFTER INSERT OR UPDATE OF status ON course_enrollments FOR EACH ROW EXECUTE FUNCTION _notify_academic_status('enrollment');
CREATE TRIGGER course_enrollments_roster AFTER INSERT OR UPDATE OF status ON course_enrollments FOR EACH ROW EXECUTE FUNCTION _approved_enrollment_to_roster();
CREATE TRIGGER course_enrollments_touch BEFORE UPDATE ON course_enrollments FOR EACH ROW EXECUTE FUNCTION _touch_academic_row();
CREATE TRIGGER direct_message_notification AFTER INSERT ON direct_messages FOR EACH ROW EXECUTE FUNCTION _notify_direct_message();
CREATE TRIGGER discussion_reply_guard BEFORE INSERT OR UPDATE ON discussion_replies FOR EACH ROW EXECUTE FUNCTION discussion_guard();
CREATE TRIGGER discussion_thread_guard BEFORE INSERT OR UPDATE ON discussion_threads FOR EACH ROW EXECUTE FUNCTION discussion_guard();
CREATE TRIGGER email_outbox_touch BEFORE UPDATE ON email_outbox FOR EACH ROW EXECUTE FUNCTION _blog_payments_touch();
CREATE TRIGGER group_message_notification AFTER INSERT ON group_messages FOR EACH ROW EXECUTE FUNCTION _notify_group_message();
CREATE TRIGGER learning_units_audit AFTER INSERT OR UPDATE OF status ON learning_units FOR EACH ROW EXECUTE FUNCTION _record_approval_event('learning_unit');
CREATE TRIGGER learning_units_notify AFTER INSERT OR UPDATE OF status ON learning_units FOR EACH ROW EXECUTE FUNCTION _notify_academic_status('learning_unit');
CREATE TRIGGER learning_units_recompute_progress AFTER INSERT OR DELETE OR UPDATE OF status ON learning_units FOR EACH ROW EXECUTE FUNCTION _recompute_progress_on_unit_change();
CREATE TRIGGER learning_units_touch BEFORE UPDATE ON learning_units FOR EACH ROW EXECUTE FUNCTION _touch_academic_row();
CREATE TRIGGER learning_units_validate_approval BEFORE INSERT OR UPDATE ON learning_units FOR EACH ROW EXECUTE FUNCTION _validate_learning_unit_approval();
CREATE TRIGGER notifications_dispatch_knock AFTER INSERT ON notifications FOR EACH ROW EXECUTE FUNCTION _dispatch_knock_for_notification();
CREATE TRIGGER notifications_enqueue_email AFTER INSERT ON notifications FOR EACH ROW EXECUTE FUNCTION _enqueue_notification_email();
CREATE TRIGGER notifications_queue_push AFTER INSERT ON notifications FOR EACH ROW EXECUTE FUNCTION _queue_push_for_notification();
CREATE TRIGGER notifications_sync_read_state BEFORE INSERT OR UPDATE ON notifications FOR EACH ROW EXECUTE FUNCTION notifications_sync_read_state();
CREATE TRIGGER payment_channels_touch BEFORE UPDATE ON payment_channels FOR EACH ROW EXECUTE FUNCTION _blog_payments_touch();
CREATE TRIGGER payment_submissions_touch BEFORE UPDATE ON payment_submissions FOR EACH ROW EXECUTE FUNCTION _blog_payments_touch();
CREATE TRIGGER guard_administrator_profile_changes BEFORE UPDATE OF role, status, email ON profiles FOR EACH ROW EXECUTE FUNCTION guard_administrator_profile_changes();
CREATE TRIGGER profile_account_congratulations AFTER INSERT OR UPDATE OF status ON profiles FOR EACH ROW EXECUTE FUNCTION _profile_congratulations_trigger();
CREATE TRIGGER protect_account_number BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION protect_record_number();
CREATE TRIGGER protect_profile_privileges BEFORE INSERT OR UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION protect_profile_privileges();
CREATE TRIGGER programs_ensure_code BEFORE INSERT OR UPDATE OF code, title, name ON programs FOR EACH ROW EXECUTE FUNCTION programs_ensure_code();
CREATE TRIGGER programs_sync_title_name BEFORE INSERT OR UPDATE ON programs FOR EACH ROW EXECUTE FUNCTION programs_sync_title_name();
CREATE TRIGGER protect_course_number BEFORE UPDATE ON programs FOR EACH ROW EXECUTE FUNCTION protect_record_number();
CREATE TRIGGER quiz_questions_totals AFTER INSERT OR DELETE OR UPDATE ON quiz_questions FOR EACH ROW EXECUTE FUNCTION _quiz_questions_totals();
CREATE TRIGGER quiz_questions_validate BEFORE INSERT OR UPDATE ON quiz_questions FOR EACH ROW EXECUTE FUNCTION _quiz_questions_validate();
CREATE TRIGGER quizzes_touch BEFORE UPDATE ON quizzes FOR EACH ROW EXECUTE FUNCTION _quizzes_touch();
CREATE TRIGGER quizzes_validate_learning_unit BEFORE INSERT OR UPDATE ON quizzes FOR EACH ROW EXECUTE FUNCTION _validate_learning_unit_component();
CREATE TRIGGER school_policies_touch BEFORE UPDATE ON school_policies FOR EACH ROW EXECUTE FUNCTION _touch_updated_at();
CREATE TRIGGER student_learning_progress_recompute AFTER INSERT OR DELETE OR UPDATE ON student_learning_progress FOR EACH ROW EXECUTE FUNCTION _recompute_course_progress();
CREATE TRIGGER student_learning_progress_touch BEFORE UPDATE ON student_learning_progress FOR EACH ROW EXECUTE FUNCTION _touch_academic_row();
CREATE TRIGGER student_learning_progress_validate BEFORE INSERT OR UPDATE ON student_learning_progress FOR EACH ROW EXECUTE FUNCTION _validate_student_learning_progress();
CREATE TRIGGER protect_system_settings_trigger BEFORE UPDATE ON system_settings FOR EACH ROW EXECUTE FUNCTION protect_system_settings();
CREATE TRIGGER teacher_course_plans_audit AFTER INSERT OR UPDATE OF status ON teacher_course_plans FOR EACH ROW EXECUTE FUNCTION _record_approval_event('course_plan');
CREATE TRIGGER teacher_course_plans_notify AFTER INSERT OR UPDATE OF status ON teacher_course_plans FOR EACH ROW EXECUTE FUNCTION _notify_academic_status('course_plan');
CREATE TRIGGER teacher_course_plans_touch BEFORE UPDATE ON teacher_course_plans FOR EACH ROW EXECUTE FUNCTION _touch_academic_row();
CREATE TRIGGER training_materials_audit AFTER INSERT OR UPDATE OF status ON training_materials FOR EACH ROW EXECUTE FUNCTION _record_approval_event('training_material');
CREATE TRIGGER training_materials_normalize_status BEFORE INSERT OR UPDATE OF status ON training_materials FOR EACH ROW EXECUTE FUNCTION _normalize_training_material_status();
CREATE TRIGGER training_materials_notify AFTER INSERT OR UPDATE OF status ON training_materials FOR EACH ROW EXECUTE FUNCTION _notify_academic_status('training_material');
CREATE TRIGGER training_materials_touch BEFORE UPDATE ON training_materials FOR EACH ROW EXECUTE FUNCTION _touch_academic_row();
CREATE TRIGGER transparency_file_guard BEFORE INSERT OR UPDATE ON transparency_reports FOR EACH ROW EXECUTE FUNCTION guard_transparency_file();

-- ---------------------------------------------------------------------------
-- Views
-- ---------------------------------------------------------------------------
create or replace view "public"."academic_approval_queue" with (security_invoker = true) as
SELECT 'enrollment'::text AS entity_type,
    e.id AS entity_id,
    c.name AS title,
    COALESCE(p.name, p.full_name, p.email, 'Student'::text) AS owner_name,
    COALESCE(e.submitted_at, e.created_at) AS submitted_at,
    e.status,
    e.revision_note,
    to_jsonb(e.*) || jsonb_build_object('cohort_name', c.name, 'student_name', COALESCE(p.name, p.full_name, p.email)) AS context
   FROM course_enrollments e
     JOIN cohorts c ON c.id = e.cohort_id
     LEFT JOIN profiles p ON p.id = e.student_id
  WHERE e.status = 'submitted'::text
UNION ALL
 SELECT 'course_plan'::text AS entity_type,
    cp.id AS entity_id,
    cp.title,
    COALESCE(p.name, p.full_name, p.email, 'Teacher'::text) AS owner_name,
    COALESCE(cp.submitted_at, cp.created_at) AS submitted_at,
    cp.status,
    cp.revision_note,
    to_jsonb(cp.*) AS context
   FROM teacher_course_plans cp
     LEFT JOIN profiles p ON p.id = cp.teacher_id
  WHERE cp.status = 'submitted'::text
UNION ALL
 SELECT 'class_session'::text AS entity_type,
    s.id AS entity_id,
    s.title,
    COALESCE(p.name, p.full_name, p.email, 'Teacher'::text) AS owner_name,
    COALESCE(s.submitted_at, s.created_at) AS submitted_at,
    s.status,
    s.revision_note,
    to_jsonb(s.*) AS context
   FROM class_sessions s
     LEFT JOIN profiles p ON p.id = s.teacher_id
  WHERE s.status = 'submitted'::text
UNION ALL
 SELECT 'learning_unit'::text AS entity_type,
    u.id AS entity_id,
    u.title,
    COALESCE(p.name, p.full_name, p.email, 'Teacher'::text) AS owner_name,
    COALESCE(u.submitted_at, u.created_at) AS submitted_at,
    u.status,
    u.revision_note,
    to_jsonb(u.*) AS context
   FROM learning_units u
     LEFT JOIN profiles p ON p.id = u.created_by
  WHERE u.status = 'submitted'::text
UNION ALL
 SELECT 'training_material'::text AS entity_type,
    m.id AS entity_id,
    m.title,
    COALESCE(p.name, p.full_name, p.email, 'Teacher'::text) AS owner_name,
    COALESCE(m.submitted_at, m.created_at) AS submitted_at,
    m.status,
    m.revision_note,
    to_jsonb(m.*) AS context
   FROM training_materials m
     LEFT JOIN profiles p ON p.id = m.created_by
  WHERE m.status = 'submitted'::text;
create or replace view "public"."aptitude_test_results" with (security_invoker = true) as
SELECT id,
    quiz_id,
    quiz_title,
    name,
    contact,
    programme,
    score,
    max_score,
    percent,
    passed,
    ref,
    applicant_id,
    created_at
   FROM entrance_test_results;
create or replace view "public"."gradebook_settings" with (security_invoker = true) as
SELECT id,
    quizzes_weight,
    assignments_weight,
    exams_weight,
    pass_mark,
    distinction_mark,
    published,
    updated_at
   FROM grade_evaluation_settings;

-- ---------------------------------------------------------------------------
-- Policies
-- ---------------------------------------------------------------------------
create policy "alumni_biz_public_approved" on "public"."alumni_businesses" for select to "anon", "authenticated"
  using ((is_approved = true));
create policy "alumni_biz_public_insert" on "public"."alumni_businesses" for insert to "anon", "authenticated"
  with check ((((length(btrim(name)) >= 2) AND (length(btrim(name)) <= 120)) AND (length(btrim(owner_name)) <= 120) AND ((length(btrim(category)) >= 1) AND (length(btrim(category)) <= 80)) AND (length(btrim(location)) <= 160) AND ((length(btrim(contact)) >= 3) AND (length(btrim(contact)) <= 180)) AND ((length(btrim(description)) >= 10) AND (length(btrim(description)) <= 2000)) AND (is_approved = false) AND (created_by IS NULL)));
create policy "alumni_biz_staff_all" on "public"."alumni_businesses" for all to "authenticated"
  using (has_permission('cms.manage'::text))
  with check (has_permission('cms.manage'::text));
create policy "announcements_read" on "public"."announcements" for select to public
  using (announcement_visible_to_me(id));
create policy "announcements_write" on "public"."announcements" for all to "authenticated"
  using (( SELECT has_permission('announcements.manage'::text) AS has_permission))
  with check (( SELECT has_permission('announcements.manage'::text) AS has_permission));
create policy "app_integration_events_own_read" on "public"."app_integration_events" for select to "authenticated"
  using ((user_id = auth.uid()));
create policy "app_drafts_staff_all" on "public"."application_drafts" for all to "authenticated"
  using (has_permission('cms.manage'::text))
  with check (has_permission('cms.manage'::text));
create policy "approval_events_read" on "public"."approval_events" for select to "authenticated"
  using ((is_academic_reviewer() OR has_permission('materials.approve'::text) OR ((entity_type = 'enrollment'::text) AND (EXISTS ( SELECT 1
   FROM course_enrollments e
  WHERE ((e.id = approval_events.entity_id) AND (e.student_id = auth.uid()))))) OR ((entity_type = 'learning_unit'::text) AND (EXISTS ( SELECT 1
   FROM learning_units u
  WHERE ((u.id = approval_events.entity_id) AND ((u.created_by = auth.uid()) OR is_cohort_teacher(u.cohort_id)))))) OR ((entity_type = 'course_plan'::text) AND (EXISTS ( SELECT 1
   FROM teacher_course_plans p
  WHERE ((p.id = approval_events.entity_id) AND (p.teacher_id = auth.uid()))))) OR ((entity_type = 'class_session'::text) AND (EXISTS ( SELECT 1
   FROM class_sessions s
  WHERE ((s.id = approval_events.entity_id) AND (s.teacher_id = auth.uid()))))) OR ((entity_type = 'training_material'::text) AND (EXISTS ( SELECT 1
   FROM training_materials m
  WHERE ((m.id = approval_events.entity_id) AND (m.created_by = auth.uid())))))));
create policy "aptitude_settings_insert_staff" on "public"."aptitude_control_settings" for insert to "authenticated"
  with check (((id = 1) AND (EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.status = 'Active'::text) AND (p.role = ANY (ARRAY['Super Admin'::text, 'School Admin'::text, 'Registrar'::text, 'Director of Education'::text])))))));
create policy "aptitude_settings_read_all" on "public"."aptitude_control_settings" for select to public
  using (true);
create policy "aptitude_settings_write_staff" on "public"."aptitude_control_settings" for update to "authenticated"
  using ((EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.status = 'Active'::text) AND (p.role = ANY (ARRAY['Super Admin'::text, 'School Admin'::text, 'Registrar'::text, 'Director of Education'::text]))))))
  with check ((EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.status = 'Active'::text) AND (p.role = ANY (ARRAY['Super Admin'::text, 'School Admin'::text, 'Registrar'::text, 'Director of Education'::text]))))));
create policy "aptitude_prep_read_all" on "public"."aptitude_preparations" for select to public
  using (true);
create policy "aptitude_prep_write_staff" on "public"."aptitude_preparations" for all to public
  using ((EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = ANY (ARRAY['School Admin'::text, 'Registrar'::text, 'Teacher'::text, 'Director of Education'::text, 'Executive Assistant'::text]))))))
  with check ((EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = ANY (ARRAY['School Admin'::text, 'Registrar'::text, 'Teacher'::text, 'Director of Education'::text, 'Executive Assistant'::text]))))));
create policy "assignments_read" on "public"."assignments" for select to "authenticated"
  using (((((learning_unit_id IS NULL) OR (EXISTS ( SELECT 1
   FROM learning_units u
  WHERE ((u.id = assignments.learning_unit_id) AND (u.status = 'approved'::text))))) AND is_cohort_member(cohort_id)) OR is_cohort_teacher(cohort_id) OR has_permission('assignments.manage'::text) OR has_permission('people.view'::text)));
create policy "assignments_write" on "public"."assignments" for all to "authenticated"
  using ((((learning_unit_id IS NULL) OR (NOT (EXISTS ( SELECT 1
   FROM learning_units u
  WHERE ((u.id = assignments.learning_unit_id) AND (u.status = 'approved'::text)))))) AND (has_permission('assignments.manage'::text) OR (has_permission('assignments.own'::text) AND is_cohort_teacher(cohort_id)))))
  with check ((has_permission('assignments.manage'::text) OR (has_permission('assignments.own'::text) AND is_cohort_teacher(cohort_id))));
create policy "assistant_research_owner_delete" on "public"."assistant_research_resources" for delete to "authenticated"
  using ((owner_id = auth.uid()));
create policy "assistant_research_owner_insert" on "public"."assistant_research_resources" for insert to "authenticated"
  with check ((owner_id = auth.uid()));
create policy "assistant_research_owner_read" on "public"."assistant_research_resources" for select to "authenticated"
  using (((owner_id = auth.uid()) OR ((visibility = 'staff'::text) AND (EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.role <> 'Student'::text) AND (p.status = 'Active'::text)))))));
create policy "assistant_research_owner_update" on "public"."assistant_research_resources" for update to "authenticated"
  using ((owner_id = auth.uid()))
  with check ((owner_id = auth.uid()));
create policy "assistant_usage_no_client_access" on "public"."assistant_usage" as restrictive for all to "anon", "authenticated"
  using (false)
  with check (false);
create policy "attendance_read" on "public"."attendance" for select to "authenticated"
  using (((student_id = auth.uid()) OR ( SELECT is_cohort_teacher(attendance.cohort_id) AS is_cohort_teacher) OR ( SELECT has_permission('attendance.manage'::text) AS has_permission) OR ( SELECT has_permission('people.view'::text) AS has_permission)));
create policy "attendance_write" on "public"."attendance" for all to "authenticated"
  using ((( SELECT has_permission('attendance.manage'::text) AS has_permission) OR (( SELECT has_permission('attendance.own'::text) AS has_permission) AND ( SELECT is_cohort_teacher(attendance.cohort_id) AS is_cohort_teacher))))
  with check ((( SELECT has_permission('attendance.manage'::text) AS has_permission) OR (( SELECT has_permission('attendance.own'::text) AS has_permission) AND ( SELECT is_cohort_teacher(attendance.cohort_id) AS is_cohort_teacher))));
create policy "blog_posts_manage_all" on "public"."blog_posts" for all to "authenticated"
  using (( SELECT has_permission('blog.manage'::text) AS has_permission))
  with check (( SELECT has_permission('blog.manage'::text) AS has_permission));
create policy "blog_posts_public_read" on "public"."blog_posts" for select to public
  using (((status = ANY (ARRAY['published'::text, 'scheduled'::text])) AND (published_at <= now())));
create policy "certificate_audit_staff_only" on "public"."certificate_audit" as restrictive for select to "authenticated"
  using (has_permission('certificates.manage'::text));
create policy "certificates_private_register" on "public"."certificates" as restrictive for select to "authenticated"
  using (((EXISTS ( SELECT 1
   FROM profiles me
  WHERE ((me.id = auth.uid()) AND (me.status = 'Active'::text)))) AND ((student_id = auth.uid()) OR ( SELECT has_permission('certificates.manage'::text) AS has_permission))));
create policy "certificates_write" on "public"."certificates" for all to "authenticated"
  using (( SELECT has_permission('certificates.manage'::text) AS has_permission))
  with check (( SELECT has_permission('certificates.manage'::text) AS has_permission));
create policy "chat_drafts_own" on "public"."chat_drafts" for all to public
  using ((user_id = auth.uid()))
  with check ((user_id = auth.uid()));
create policy "chat_group_invites_delete" on "public"."chat_group_invites" for delete to "authenticated"
  using (((auth.uid() = inviter_id) OR (auth.uid() = invitee_id) OR (EXISTS ( SELECT 1
   FROM chat_group_members m
  WHERE ((m.group_id = chat_group_invites.group_id) AND (m.user_id = auth.uid()) AND (m.member_role = ANY (ARRAY['owner'::text, 'admin'::text])))))));
create policy "chat_group_invites_insert" on "public"."chat_group_invites" for insert to "authenticated"
  with check ((auth.uid() = inviter_id));
create policy "chat_group_invites_read" on "public"."chat_group_invites" for select to "authenticated"
  using (((auth.uid() = invitee_id) OR (auth.uid() = inviter_id) OR (EXISTS ( SELECT 1
   FROM chat_group_members m
  WHERE ((m.group_id = chat_group_invites.group_id) AND (m.user_id = auth.uid()) AND (m.member_role = ANY (ARRAY['owner'::text, 'admin'::text])))))));
create policy "chat_group_invites_update" on "public"."chat_group_invites" for update to "authenticated"
  using ((auth.uid() = invitee_id))
  with check ((auth.uid() = invitee_id));
create policy "chat_group_join_requests_delete" on "public"."chat_group_join_requests" for delete to "authenticated"
  using (((auth.uid() = user_id) OR (EXISTS ( SELECT 1
   FROM chat_group_members m
  WHERE ((m.group_id = chat_group_join_requests.group_id) AND (m.user_id = auth.uid()) AND (m.member_role = ANY (ARRAY['owner'::text, 'admin'::text])))))));
create policy "chat_group_join_requests_insert" on "public"."chat_group_join_requests" for insert to "authenticated"
  with check ((auth.uid() = user_id));
create policy "chat_group_join_requests_read" on "public"."chat_group_join_requests" for select to "authenticated"
  using (((auth.uid() = user_id) OR (EXISTS ( SELECT 1
   FROM chat_group_members m
  WHERE ((m.group_id = chat_group_join_requests.group_id) AND (m.user_id = auth.uid()) AND (m.member_role = ANY (ARRAY['owner'::text, 'admin'::text])))))));
create policy "chat_group_join_requests_update" on "public"."chat_group_join_requests" for update to "authenticated"
  using ((EXISTS ( SELECT 1
   FROM chat_group_members m
  WHERE ((m.group_id = chat_group_join_requests.group_id) AND (m.user_id = auth.uid()) AND (m.member_role = ANY (ARRAY['owner'::text, 'admin'::text]))))))
  with check ((EXISTS ( SELECT 1
   FROM chat_group_members m
  WHERE ((m.group_id = chat_group_join_requests.group_id) AND (m.user_id = auth.uid()) AND (m.member_role = ANY (ARRAY['owner'::text, 'admin'::text]))))));
create policy "chat_group_members_delete" on "public"."chat_group_members" for delete to public
  using (((user_id = auth.uid()) OR is_chat_group_admin(group_id) OR (EXISTS ( SELECT 1
   FROM chat_groups g
  WHERE ((g.id = chat_group_members.group_id) AND (g.created_by = auth.uid()))))));
create policy "chat_group_members_insert" on "public"."chat_group_members" for insert to public
  with check ((((user_id = auth.uid()) AND (EXISTS ( SELECT 1
   FROM chat_groups g
  WHERE ((g.id = chat_group_members.group_id) AND (g.created_by = auth.uid()))))) OR is_chat_group_admin(group_id)));
create policy "chat_group_members_read" on "public"."chat_group_members" for select to public
  using (((user_id = auth.uid()) OR is_chat_group_member(group_id)));
create policy "chat_group_members_update" on "public"."chat_group_members" for update to public
  using (((user_id = auth.uid()) OR is_chat_group_admin(group_id)));
create policy "chat_groups_delete" on "public"."chat_groups" for delete to public
  using ((created_by = auth.uid()));
create policy "chat_groups_insert" on "public"."chat_groups" for insert to public
  with check ((created_by = auth.uid()));
create policy "chat_groups_read" on "public"."chat_groups" for select to public
  using ((is_chat_group_member(id) OR (created_by = auth.uid())));
create policy "chat_groups_update" on "public"."chat_groups" for update to public
  using (((created_by = auth.uid()) OR is_chat_group_admin(id)));
create policy "chat_poll_votes_delete" on "public"."chat_poll_votes" for delete to "authenticated"
  using ((auth.uid() = user_id));
create policy "chat_poll_votes_insert" on "public"."chat_poll_votes" for insert to "authenticated"
  with check (((auth.uid() = user_id) AND (EXISTS ( SELECT 1
   FROM chat_polls p
  WHERE ((p.id = chat_poll_votes.poll_id) AND ((p.expires_at IS NULL) OR (p.expires_at > now())) AND (((p.group_id IS NOT NULL) AND (EXISTS ( SELECT 1
           FROM chat_group_members m
          WHERE ((m.group_id = p.group_id) AND (m.user_id = auth.uid()))))) OR ((p.dm_thread IS NOT NULL) AND ((split_part(p.dm_thread, ':'::text, 1) = (auth.uid())::text) OR (split_part(p.dm_thread, ':'::text, 2) = (auth.uid())::text))) OR (p.creator_id = auth.uid())))))));
create policy "chat_poll_votes_read" on "public"."chat_poll_votes" for select to "authenticated"
  using ((EXISTS ( SELECT 1
   FROM chat_polls p
  WHERE ((p.id = chat_poll_votes.poll_id) AND (((p.group_id IS NOT NULL) AND (EXISTS ( SELECT 1
           FROM chat_group_members m
          WHERE ((m.group_id = p.group_id) AND (m.user_id = auth.uid()))))) OR ((p.dm_thread IS NOT NULL) AND ((split_part(p.dm_thread, ':'::text, 1) = (auth.uid())::text) OR (split_part(p.dm_thread, ':'::text, 2) = (auth.uid())::text))) OR (p.creator_id = auth.uid()))))));
create policy "chat_polls_delete" on "public"."chat_polls" for delete to "authenticated"
  using ((auth.uid() = creator_id));
create policy "chat_polls_insert" on "public"."chat_polls" for insert to "authenticated"
  with check ((auth.uid() = creator_id));
create policy "chat_polls_read" on "public"."chat_polls" for select to "authenticated"
  using ((((group_id IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM chat_group_members m
  WHERE ((m.group_id = chat_polls.group_id) AND (m.user_id = auth.uid()))))) OR ((dm_thread IS NOT NULL) AND ((split_part(dm_thread, ':'::text, 1) = (auth.uid())::text) OR (split_part(dm_thread, ':'::text, 2) = (auth.uid())::text))) OR (creator_id = auth.uid())));
create policy "chat_polls_update" on "public"."chat_polls" for update to "authenticated"
  using ((auth.uid() = creator_id))
  with check ((auth.uid() = creator_id));
create policy "class_sessions_read" on "public"."class_sessions" for select to "authenticated"
  using ((((status = 'approved'::text) AND is_cohort_member(cohort_id)) OR is_cohort_teacher(cohort_id) OR is_academic_reviewer()));
create policy "class_sessions_write" on "public"."class_sessions" for all to "authenticated"
  using (((status <> 'approved'::text) AND can_manage_cohort_plan(cohort_id)))
  with check (((is_academic_reviewer() AND (status = ANY (ARRAY['draft'::text, 'submitted'::text, 'rejected'::text, 'revision_requested'::text, 'cancelled'::text, 'completed'::text]))) OR (can_manage_cohort_plan(cohort_id) AND (status = ANY (ARRAY['draft'::text, 'submitted'::text, 'rejected'::text, 'revision_requested'::text, 'cancelled'::text, 'completed'::text])))));
create policy "cohort_students_read" on "public"."cohort_students" for select to "authenticated"
  using (((student_id = auth.uid()) OR ( SELECT is_cohort_teacher(cohort_students.cohort_id) AS is_cohort_teacher) OR ( SELECT has_permission('people.view'::text) AS has_permission) OR ( SELECT has_permission('cohorts.manage'::text) AS has_permission)));
create policy "cohort_students_write" on "public"."cohort_students" for all to "authenticated"
  using ((( SELECT has_permission('cohorts.manage'::text) AS has_permission) OR ( SELECT has_permission('students.manage'::text) AS has_permission)))
  with check ((( SELECT has_permission('cohorts.manage'::text) AS has_permission) OR ( SELECT has_permission('students.manage'::text) AS has_permission)));
create policy "cohort_timetable_read_all" on "public"."cohort_timetable_slots" for select to public
  using (true);
create policy "cohort_timetable_write_staff" on "public"."cohort_timetable_slots" for all to public
  using ((EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = ANY (ARRAY['School Admin'::text, 'Registrar'::text, 'Teacher'::text, 'Director of Education'::text, 'Executive Assistant'::text, 'Super Admin'::text]))))))
  with check ((EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = ANY (ARRAY['School Admin'::text, 'Registrar'::text, 'Teacher'::text, 'Director of Education'::text, 'Executive Assistant'::text, 'Super Admin'::text]))))));
create policy "cohorts_read" on "public"."cohorts" for select to "authenticated"
  using (true);
create policy "cohorts_write" on "public"."cohorts" for all to "authenticated"
  using (( SELECT has_permission('cohorts.manage'::text) AS has_permission))
  with check (( SELECT has_permission('cohorts.manage'::text) AS has_permission));
create policy "course_completions_read" on "public"."course_completions" for select to "authenticated"
  using (((student_id = auth.uid()) OR is_cohort_teacher(cohort_id) OR is_academic_reviewer()));
create policy "course_completions_write" on "public"."course_completions" for all to "authenticated"
  using ((is_cohort_teacher(cohort_id) OR is_academic_reviewer()))
  with check ((is_cohort_teacher(cohort_id) OR is_academic_reviewer()));
create policy "course_enrollments_read" on "public"."course_enrollments" for select to "authenticated"
  using (((student_id = auth.uid()) OR is_academic_reviewer() OR ((status = 'approved'::text) AND is_cohort_teacher(cohort_id))));
create policy "crash_course_attempts_own_insert" on "public"."crash_course_attempts" for insert to "authenticated"
  with check ((student_id = ( SELECT auth.uid() AS uid)));
create policy "crash_course_attempts_own_read" on "public"."crash_course_attempts" for select to "authenticated"
  using ((student_id = ( SELECT auth.uid() AS uid)));
create policy "crash_course_attempts_own_update" on "public"."crash_course_attempts" for update to "authenticated"
  using ((student_id = ( SELECT auth.uid() AS uid)))
  with check ((student_id = ( SELECT auth.uid() AS uid)));
create policy "crash_course_enrollments_own_insert" on "public"."crash_course_enrollments" for insert to "authenticated"
  with check ((student_id = ( SELECT auth.uid() AS uid)));
create policy "crash_course_enrollments_own_read" on "public"."crash_course_enrollments" for select to "authenticated"
  using ((student_id = ( SELECT auth.uid() AS uid)));
create policy "crash_course_enrollments_own_update" on "public"."crash_course_enrollments" for update to "authenticated"
  using ((student_id = ( SELECT auth.uid() AS uid)))
  with check ((student_id = ( SELECT auth.uid() AS uid)));
create policy "crash_course_lessons_enrolled_read" on "public"."crash_course_lessons" for select to "authenticated"
  using ((EXISTS ( SELECT 1
   FROM crash_course_enrollments e
  WHERE ((e.course_id = crash_course_lessons.course_id) AND (e.student_id = ( SELECT auth.uid() AS uid))))));
create policy "crash_courses_live_read" on "public"."crash_courses" for select to "authenticated"
  using (((status = 'live'::text) OR (( SELECT auth.uid() AS uid) = created_by)));
create policy "Admins manage crash programs" on "public"."crash_programs" for all to "authenticated"
  using (( SELECT has_permission('programs.manage'::text) AS has_permission))
  with check (( SELECT has_permission('programs.manage'::text) AS has_permission));
create policy "Published crash programs are public" on "public"."crash_programs" for select to "anon", "authenticated"
  using (((published = true) OR ( SELECT is_portal_admin() AS is_portal_admin)));
create policy "data_migrations_no_client_access" on "public"."data_migrations" as restrictive for all to "anon", "authenticated"
  using (false)
  with check (false);
create policy "Members read own chats" on "public"."direct_messages" for select to public
  using (((auth.uid() = sender_id) OR (auth.uid() = receiver_id)));
create policy "Members send chats" on "public"."direct_messages" for insert to public
  with check ((auth.uid() = sender_id));
create policy "Receivers mark seen" on "public"."direct_messages" for update to public
  using (((auth.uid() = receiver_id) OR (auth.uid() = sender_id)));
create policy "Senders delete own messages" on "public"."direct_messages" for delete to public
  using ((auth.uid() = sender_id));
create policy "Senders edit own messages" on "public"."direct_messages" for update to public
  using ((auth.uid() = sender_id))
  with check ((auth.uid() = sender_id));
create policy "discussion_replies_delete" on "public"."discussion_replies" for delete to "authenticated"
  using (((author_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM discussion_threads t
  WHERE ((t.id = discussion_replies.thread_id) AND (is_cohort_teacher(t.cohort_id) OR has_permission('academic_plans.approve'::text)))))));
create policy "discussion_replies_edit" on "public"."discussion_replies" for update to "authenticated"
  using (((author_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM discussion_threads t
  WHERE ((t.id = discussion_replies.thread_id) AND (is_cohort_teacher(t.cohort_id) OR has_permission('academic_plans.approve'::text)))))))
  with check (((author_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM discussion_threads t
  WHERE ((t.id = discussion_replies.thread_id) AND (is_cohort_teacher(t.cohort_id) OR has_permission('academic_plans.approve'::text)))))));
create policy "discussion_replies_post" on "public"."discussion_replies" for insert to "authenticated"
  with check (((author_id = auth.uid()) AND (EXISTS ( SELECT 1
   FROM discussion_threads t
  WHERE ((t.id = discussion_replies.thread_id) AND can_read_discussion(t.cohort_id))))));
create policy "discussion_replies_read" on "public"."discussion_replies" for select to "authenticated"
  using ((EXISTS ( SELECT 1
   FROM discussion_threads t
  WHERE ((t.id = discussion_replies.thread_id) AND can_read_discussion(t.cohort_id)))));
create policy "discussion_threads_delete" on "public"."discussion_threads" for delete to "authenticated"
  using (((author_id = auth.uid()) OR is_cohort_teacher(cohort_id) OR has_permission('academic_plans.approve'::text)));
create policy "discussion_threads_edit" on "public"."discussion_threads" for update to "authenticated"
  using (((author_id = auth.uid()) OR is_cohort_teacher(cohort_id) OR has_permission('academic_plans.approve'::text)))
  with check (((author_id = auth.uid()) OR is_cohort_teacher(cohort_id) OR has_permission('academic_plans.approve'::text)));
create policy "discussion_threads_post" on "public"."discussion_threads" for insert to "authenticated"
  with check (((author_id = auth.uid()) AND can_read_discussion(cohort_id)));
create policy "discussion_threads_read" on "public"."discussion_threads" for select to "authenticated"
  using (can_read_discussion(cohort_id));
create policy "email_outbox_read" on "public"."email_outbox" for select to "authenticated"
  using (( SELECT has_permission('settings.manage'::text) AS has_permission));
create policy "email_outbox_read_email_manage" on "public"."email_outbox" for select to public
  using (( SELECT has_permission('email.manage'::text) AS has_permission));
create policy "email templates managers" on "public"."email_templates" for all to "authenticated"
  using (has_permission('settings.manage'::text))
  with check (has_permission('settings.manage'::text));
create policy "enrollment_arrangement_history_read" on "public"."enrollment_arrangement_history" for select to "authenticated"
  using ((EXISTS ( SELECT 1
   FROM course_enrollments e
  WHERE ((e.id = enrollment_arrangement_history.enrollment_id) AND ((e.student_id = auth.uid()) OR is_academic_reviewer())))));
create policy "entrance_settings_read_all" on "public"."entrance_settings" for select to public
  using (true);
create policy "entrance_settings_write_staff" on "public"."entrance_settings" for all to public
  using ((EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = ANY (ARRAY['School Admin'::text, 'Registrar'::text, 'Director of Education'::text]))))))
  with check ((EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = ANY (ARRAY['School Admin'::text, 'Registrar'::text, 'Director of Education'::text]))))));
create policy "entrance_results_insert_any" on "public"."entrance_test_results" for insert to public
  with check (true);
create policy "entrance_results_read_staff" on "public"."entrance_test_results" for select to public
  using ((EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = ANY (ARRAY['School Admin'::text, 'Registrar'::text, 'Admission Officer'::text, 'Teacher'::text, 'Executive Assistant'::text, 'Research Officer'::text, 'Data Entry Officer'::text, 'Customer Care Officer'::text, 'Public Relations Officer'::text, 'Director of Education'::text, 'Finance Officer'::text]))))));
create policy "fee_transactions_read" on "public"."fee_transactions" for select to "authenticated"
  using (((student_id = auth.uid()) OR ( SELECT has_permission('fees.view'::text) AS has_permission) OR ( SELECT has_permission('fees.manage'::text) AS has_permission)));
create policy "fee_transactions_write" on "public"."fee_transactions" for all to "authenticated"
  using (( SELECT has_permission('fees.manage'::text) AS has_permission))
  with check (( SELECT has_permission('fees.manage'::text) AS has_permission));
create policy "fs_insert_own" on "public"."file_submissions" for insert to "authenticated"
  with check ((submitter_id = auth.uid()));
create policy "fs_select_own_or_admin" on "public"."file_submissions" for select to "authenticated"
  using (((submitter_id = auth.uid()) OR is_portal_admin() OR has_permission('students.manage'::text)));
create policy "fs_update_admin" on "public"."file_submissions" for update to "authenticated"
  using ((is_portal_admin() OR has_permission('students.manage'::text)))
  with check ((is_portal_admin() OR has_permission('students.manage'::text)));
create policy "grade_appeals_read" on "public"."grade_appeals" for select to "authenticated"
  using ((can_review_grade_appeals() OR ((student_id = auth.uid()) AND (EXISTS ( SELECT 1
   FROM profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.status = 'Active'::text)))))));
create policy "grade_assessments_read_all" on "public"."grade_assessments" for select to public
  using (true);
create policy "grade_assessments_write_staff" on "public"."grade_assessments" for all to public
  using ((EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = ANY (ARRAY['School Admin'::text, 'Registrar'::text, 'Teacher'::text, 'Director of Education'::text, 'Executive Assistant'::text]))))))
  with check ((EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = ANY (ARRAY['School Admin'::text, 'Registrar'::text, 'Teacher'::text, 'Director of Education'::text, 'Executive Assistant'::text]))))));
create policy "grade_evaluation_insert_staff" on "public"."grade_evaluation_settings" for insert to public
  with check ((EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = ANY (ARRAY['School Admin'::text, 'Registrar'::text, 'Teacher'::text, 'Director of Education'::text, 'Executive Assistant'::text]))))));
create policy "grade_evaluation_read_all" on "public"."grade_evaluation_settings" for select to public
  using (true);
create policy "grade_evaluation_write_staff" on "public"."grade_evaluation_settings" for update to public
  using ((EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = ANY (ARRAY['School Admin'::text, 'Registrar'::text, 'Teacher'::text, 'Director of Education'::text, 'Executive Assistant'::text]))))));
create policy "group_messages_delete" on "public"."group_messages" for delete to public
  using (((sender_id = auth.uid()) OR is_chat_group_admin(group_id)));
create policy "group_messages_insert" on "public"."group_messages" for insert to public
  with check (((sender_id = auth.uid()) AND is_chat_group_member(group_id)));
create policy "group_messages_read" on "public"."group_messages" for select to public
  using (is_chat_group_member(group_id));
create policy "group_messages_sender_update" on "public"."group_messages" for update to public
  using (((sender_id = auth.uid()) OR is_chat_group_admin(group_id)))
  with check (((sender_id = auth.uid()) OR is_chat_group_admin(group_id)));
create policy "group_messages_update" on "public"."group_messages" for update to public
  using (((sender_id = auth.uid()) OR is_chat_group_admin(group_id)))
  with check (((sender_id = auth.uid()) OR is_chat_group_admin(group_id)));
create policy "helpdesk_message_read" on "public"."helpdesk_messages" for select to "authenticated"
  using ((EXISTS ( SELECT 1
   FROM helpdesk_tickets t
  WHERE (t.id = helpdesk_messages.ticket_id))));
create policy "helpdesk_ticket_read" on "public"."helpdesk_tickets" for select to "authenticated"
  using ((can_manage_helpdesk() OR ((student_id = auth.uid()) AND (EXISTS ( SELECT 1
   FROM profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.status = 'Active'::text) AND (profiles.role = 'Student'::text)))))));
create policy "knock_events_staff_read" on "public"."knock_notification_events" for select to "authenticated"
  using (is_staff());
create policy "learning_memory_delete" on "public"."learning_memory" for delete to "authenticated"
  using ((user_id = auth.uid()));
create policy "learning_memory_insert" on "public"."learning_memory" for insert to "authenticated"
  with check (((user_id = auth.uid()) AND (EXISTS ( SELECT 1
   FROM learning_units u
  WHERE ((u.id = learning_memory.unit_id) AND (u.program_id = u.program_id))))));
create policy "learning_memory_read" on "public"."learning_memory" for select to "authenticated"
  using (((user_id = auth.uid()) AND (EXISTS ( SELECT 1
   FROM learning_units u
  WHERE (u.id = learning_memory.unit_id)))));
create policy "learning_memory_update" on "public"."learning_memory" for update to "authenticated"
  using ((user_id = auth.uid()))
  with check (((user_id = auth.uid()) AND (EXISTS ( SELECT 1
   FROM learning_units u
  WHERE ((u.id = learning_memory.unit_id) AND (u.program_id = u.program_id))))));
create policy "learning_units_read" on "public"."learning_units" for select to "authenticated"
  using ((((status = 'approved'::text) AND (cohort_id IS NOT NULL) AND is_cohort_member(cohort_id)) OR can_manage_learning_unit(id) OR is_academic_reviewer()));
create policy "learning_units_write" on "public"."learning_units" for all to "authenticated"
  using (((status <> 'approved'::text) AND (can_manage_learning_unit(id) OR is_academic_reviewer())))
  with check (((is_academic_reviewer() AND (status = ANY (ARRAY['draft'::text, 'submitted'::text, 'rejected'::text, 'revision_requested'::text]))) OR (has_permission('lessons.manage'::text) AND (cohort_id IS NOT NULL) AND is_cohort_teacher(cohort_id) AND (status = ANY (ARRAY['draft'::text, 'submitted'::text, 'rejected'::text, 'revision_requested'::text])))));
create policy "message_reactions_delete" on "public"."message_reactions" for delete to public
  using ((user_id = auth.uid()));
create policy "message_reactions_insert" on "public"."message_reactions" for insert to public
  with check (((user_id = auth.uid()) AND (((message_kind = 'dm'::text) AND (EXISTS ( SELECT 1
   FROM direct_messages d
  WHERE ((d.id = message_reactions.message_id) AND ((d.sender_id = auth.uid()) OR (d.receiver_id = auth.uid())))))) OR ((message_kind = 'group'::text) AND is_chat_group_member(( SELECT g.group_id
   FROM group_messages g
  WHERE (g.id = message_reactions.message_id)))))));
create policy "message_reactions_read" on "public"."message_reactions" for select to public
  using (((user_id = auth.uid()) OR ((message_kind = 'dm'::text) AND (EXISTS ( SELECT 1
   FROM direct_messages d
  WHERE ((d.id = message_reactions.message_id) AND ((d.sender_id = auth.uid()) OR (d.receiver_id = auth.uid())))))) OR ((message_kind = 'group'::text) AND is_chat_group_member(( SELECT g.group_id
   FROM group_messages g
  WHERE (g.id = message_reactions.message_id))))));
create policy "module_responsibilities_manage" on "public"."module_responsibilities" for all to "authenticated"
  using (( SELECT has_permission('academic_plans.approve'::text) AS has_permission))
  with check (( SELECT has_permission('academic_plans.approve'::text) AS has_permission));
create policy "module_responsibilities_read" on "public"."module_responsibilities" for select to "authenticated"
  using (((staff_id = auth.uid()) OR ( SELECT has_permission('academic_plans.approve'::text) AS has_permission)));
create policy "newsletter campaigns managers read" on "public"."newsletter_campaigns" for select to "authenticated"
  using (has_permission('settings.manage'::text));
create policy "newsletter subscribers managers read" on "public"."newsletter_subscribers" for select to "authenticated"
  using (has_permission('settings.manage'::text));
create policy "staff outbox read" on "public"."notification_outbox" for select to public
  using ((EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (lower(replace(p.role, ' '::text, '_'::text)) = ANY (ARRAY['admin'::text, 'super_admin'::text, 'school_admin'::text, 'registrar'::text, 'support'::text, 'teacher'::text, 'instructor'::text, 'admissions'::text]))))));
create policy "notifications_insert_self" on "public"."notifications" for insert to "authenticated"
  with check ((recipient_id = auth.uid()));
create policy "notifications_insert_staff" on "public"."notifications" for insert to "authenticated"
  with check ((is_staff() AND ((recipient_id = auth.uid()) OR has_permission('announcements.manage'::text) OR (EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = notifications.recipient_id) AND (p.role = 'Student'::text)))) OR (EXISTS ( SELECT 1
   FROM (cohort_students cs
     JOIN cohorts c ON ((c.id = cs.cohort_id)))
  WHERE ((cs.student_id = notifications.recipient_id) AND COALESCE(cs.active, true) AND ((c.teacher_id = auth.uid()) OR is_cohort_teacher(c.id))))))));
create policy "notifications_read_own" on "public"."notifications" for select to "authenticated"
  using ((recipient_id = auth.uid()));
create policy "notifications_update_own" on "public"."notifications" for update to "authenticated"
  using ((recipient_id = auth.uid()))
  with check ((recipient_id = auth.uid()));
create policy "own devices all" on "public"."onesignal_devices" for all to public
  using ((auth.uid() = user_id))
  with check ((auth.uid() = user_id));
create policy "payment_channels_read" on "public"."payment_channels" for select to "authenticated"
  using ((active OR ( SELECT has_permission('fees.manage'::text) AS has_permission) OR ( SELECT has_permission('payments.confirm'::text) AS has_permission)));
create policy "payment_channels_write" on "public"."payment_channels" for all to "authenticated"
  using ((( SELECT has_permission('fees.manage'::text) AS has_permission) OR ( SELECT has_permission('payments.confirm'::text) AS has_permission)))
  with check ((( SELECT has_permission('fees.manage'::text) AS has_permission) OR ( SELECT has_permission('payments.confirm'::text) AS has_permission)));
create policy "payment_submissions_read" on "public"."payment_submissions" for select to "authenticated"
  using (((student_id = auth.uid()) OR ( SELECT has_permission('payments.confirm'::text) AS has_permission) OR ( SELECT has_permission('fees.view'::text) AS has_permission)));
create policy "permissions_read" on "public"."permissions" for select to "authenticated"
  using (true);
create policy "permissions_write" on "public"."permissions" for all to "authenticated"
  using (( SELECT is_super_admin() AS is_super_admin))
  with check (( SELECT is_super_admin() AS is_super_admin));
create policy "policy_acceptances_read" on "public"."policy_acceptances" for select to "authenticated"
  using (((user_id = auth.uid()) OR ( SELECT has_permission('students.manage'::text) AS has_permission) OR ( SELECT has_permission('settings.manage'::text) AS has_permission)));
create policy "policy_acceptances_write" on "public"."policy_acceptances" for all to "authenticated"
  using (((user_id = auth.uid()) OR ( SELECT has_permission('students.manage'::text) AS has_permission) OR ( SELECT has_permission('settings.manage'::text) AS has_permission)))
  with check (((user_id = auth.uid()) OR ( SELECT has_permission('students.manage'::text) AS has_permission) OR ( SELECT has_permission('settings.manage'::text) AS has_permission)));
create policy "portal_kv_read" on "public"."portal_kv" for select to "authenticated"
  using ((NOT (((key ~~ 'finance-%'::text) OR (key ~~ 'cohort-plan:%'::text)) AND (EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = 'Student'::text)))))));
create policy "portal_kv_write_academic" on "public"."portal_kv" for all to "authenticated"
  using (((key ~~ 'academic-%'::text) AND (EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = ANY (ARRAY['Super Admin'::text, 'School Admin'::text, 'Registrar'::text, 'Teacher'::text, 'Director of Education'::text])))))))
  with check (((key ~~ 'academic-%'::text) AND (EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = ANY (ARRAY['Super Admin'::text, 'School Admin'::text, 'Registrar'::text, 'Teacher'::text, 'Director of Education'::text])))))));
create policy "portal_kv_write_broadcasts" on "public"."portal_kv" for all to "authenticated"
  using (((key = 'broadcasts'::text) AND (EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = ANY (ARRAY['Super Admin'::text, 'School Admin'::text])))))))
  with check (((key = 'broadcasts'::text) AND (EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = ANY (ARRAY['Super Admin'::text, 'School Admin'::text])))))));
create policy "portal_kv_write_chat_bg" on "public"."portal_kv" for all to "authenticated"
  using (((key ~~ 'chat-bg-dm:%'::text) AND (POSITION(((auth.uid())::text) IN (key)) > 0)))
  with check (((key ~~ 'chat-bg-dm:%'::text) AND (POSITION(((auth.uid())::text) IN (key)) > 0)));
create policy "portal_kv_write_cohort_config" on "public"."portal_kv" for all to "authenticated"
  using (((key ~~ 'academic-cohort-config:%'::text) AND (EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = ANY (ARRAY['Super Admin'::text, 'School Admin'::text, 'Registrar'::text, 'Director of Education'::text])))))))
  with check (((key ~~ 'academic-cohort-config:%'::text) AND (EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = ANY (ARRAY['Super Admin'::text, 'School Admin'::text, 'Registrar'::text, 'Director of Education'::text])))))));
create policy "portal_kv_write_cohort_plan_own" on "public"."portal_kv" for all to "authenticated"
  using (((key ~~ 'cohort-plan:%'::text) AND (POSITION(((auth.uid())::text) IN (key)) > 0) AND (COALESCE((value ->> 'approved'::text), 'false'::text) <> 'true'::text)))
  with check (((key ~~ 'cohort-plan:%'::text) AND (POSITION(((auth.uid())::text) IN (key)) > 0) AND (COALESCE((value ->> 'approved'::text), 'false'::text) = 'false'::text)));
create policy "portal_kv_write_cohort_plan_staff" on "public"."portal_kv" for all to "authenticated"
  using (((key ~~ 'cohort-plan:%'::text) AND (EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = ANY (ARRAY['Super Admin'::text, 'School Admin'::text, 'Registrar'::text, 'Director of Education'::text])))))))
  with check (((key ~~ 'cohort-plan:%'::text) AND (EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = ANY (ARRAY['Super Admin'::text, 'School Admin'::text, 'Registrar'::text, 'Director of Education'::text])))))));
create policy "portal_kv_write_finance" on "public"."portal_kv" for all to "authenticated"
  using (((key ~~ 'finance-%'::text) AND (EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = ANY (ARRAY['Super Admin'::text, 'School Admin'::text, 'Finance Officer'::text, 'Registrar'::text])))))))
  with check (((key ~~ 'finance-%'::text) AND (EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = ANY (ARRAY['Super Admin'::text, 'School Admin'::text, 'Finance Officer'::text, 'Registrar'::text])))))));
create policy "profiles_delete" on "public"."profiles" for delete to "authenticated"
  using (( SELECT has_permission('staff.manage'::text) AS has_permission));
create policy "profiles_insert" on "public"."profiles" for insert to "authenticated"
  with check ((((id = auth.uid()) AND (role = 'Student'::text) AND (status = 'Pending Approval'::text)) OR ( SELECT has_permission('staff.manage'::text) AS has_permission) OR ( SELECT has_permission('students.manage'::text) AS has_permission)));
create policy "profiles_select" on "public"."profiles" for select to "authenticated"
  using (( SELECT can_read_profile(profiles.id) AS can_read_profile));
create policy "profiles_update" on "public"."profiles" for update to "authenticated"
  using (((id = auth.uid()) OR ( SELECT has_permission('staff.manage'::text) AS has_permission) OR (( SELECT has_permission('students.manage'::text) AS has_permission) AND (role = 'Student'::text))))
  with check (((id = auth.uid()) OR ( SELECT has_permission('staff.manage'::text) AS has_permission) OR (( SELECT has_permission('students.manage'::text) AS has_permission) AND (role = 'Student'::text))));
create policy "Admins manage applications" on "public"."program_applications" for update to "authenticated"
  using (( SELECT has_permission('students.manage'::text) AS has_permission))
  with check (( SELECT has_permission('students.manage'::text) AS has_permission));
create policy "Applicants create own applications" on "public"."program_applications" for insert to "authenticated"
  with check ((( SELECT auth.uid() AS uid) = applicant_id));
create policy "Applicants view own applications" on "public"."program_applications" for select to "authenticated"
  using (((( SELECT auth.uid() AS uid) = applicant_id) OR ( SELECT has_permission('students.manage'::text) AS has_permission)));
create policy "program_modules_read" on "public"."program_modules" for select to public
  using (true);
create policy "program_modules_write" on "public"."program_modules" for all to public
  using (( SELECT has_permission('programs.manage'::text) AS has_permission))
  with check (( SELECT has_permission('programs.manage'::text) AS has_permission));
create policy "programs_read" on "public"."programs" for select to public
  using (true);
create policy "programs_write" on "public"."programs" for all to public
  using (( SELECT has_permission('programs.manage'::text) AS has_permission))
  with check (( SELECT has_permission('programs.manage'::text) AS has_permission));
create policy "push_subscriptions_own" on "public"."push_subscriptions" for all to "authenticated"
  using ((user_id = auth.uid()))
  with check ((user_id = auth.uid()));
create policy "quiz_attempts_select" on "public"."quiz_attempts" for select to "authenticated"
  using (((student_id = auth.uid()) OR can_manage_quiz(quiz_id) OR (( SELECT has_permission('quizzes.view_results'::text) AS has_permission) AND can_view_quiz_results(quiz_id))));
create policy "quiz_questions_all" on "public"."quiz_questions" for all to "authenticated"
  using ((can_manage_quiz(quiz_id) AND (NOT (EXISTS ( SELECT 1
   FROM (quizzes q
     JOIN learning_units u ON ((u.id = q.learning_unit_id)))
  WHERE ((q.id = quiz_questions.quiz_id) AND (u.status = 'approved'::text)))))))
  with check ((can_manage_quiz(quiz_id) AND (NOT (EXISTS ( SELECT 1
   FROM (quizzes q
     JOIN learning_units u ON ((u.id = q.learning_unit_id)))
  WHERE ((q.id = quiz_questions.quiz_id) AND (u.status = 'approved'::text)))))));
create policy "quizzes_delete" on "public"."quizzes" for delete to "authenticated"
  using ((can_manage_quiz(id) AND ((learning_unit_id IS NULL) OR (NOT (EXISTS ( SELECT 1
   FROM learning_units u
  WHERE ((u.id = quizzes.learning_unit_id) AND (u.status = 'approved'::text))))))));
create policy "quizzes_insert" on "public"."quizzes" for insert to "authenticated"
  with check ((( SELECT has_permission('quizzes.manage'::text) AS has_permission) AND can_manage_quiz_scope(program_id, cohort_id)));
create policy "quizzes_select" on "public"."quizzes" for select to "authenticated"
  using ((can_manage_quiz(id) OR can_view_quiz_results(id) OR (( SELECT has_permission('quizzes.take'::text) AS has_permission) AND quiz_visible_to_me(id))));
create policy "quizzes_update" on "public"."quizzes" for update to "authenticated"
  using ((can_manage_quiz(id) AND ((learning_unit_id IS NULL) OR (NOT (EXISTS ( SELECT 1
   FROM learning_units u
  WHERE ((u.id = quizzes.learning_unit_id) AND (u.status = 'approved'::text))))))))
  with check (can_manage_quiz_scope(program_id, cohort_id));
create policy "reminder_items_own" on "public"."reminder_items" for all to "authenticated"
  using ((user_id = auth.uid()))
  with check ((user_id = auth.uid()));
create policy "reminder_settings_own" on "public"."reminder_settings" for all to "authenticated"
  using ((user_id = auth.uid()))
  with check ((user_id = auth.uid()));
create policy "role_permissions_read" on "public"."role_permissions" for select to "authenticated"
  using (true);
create policy "role_permissions_write" on "public"."role_permissions" for all to "authenticated"
  using (( SELECT is_super_admin() AS is_super_admin))
  with check (( SELECT is_super_admin() AS is_super_admin));
create policy "roles_read" on "public"."roles" for select to "authenticated"
  using (true);
create policy "roles_write" on "public"."roles" for all to "authenticated"
  using (( SELECT is_super_admin() AS is_super_admin))
  with check (( SELECT is_super_admin() AS is_super_admin));
create policy "school_policies_read" on "public"."school_policies" for select to public
  using (((is_published = true) OR ( SELECT has_permission('settings.manage'::text) AS has_permission) OR ( SELECT has_permission('cms.manage'::text) AS has_permission)));
create policy "school_policies_write" on "public"."school_policies" for all to "authenticated"
  using ((( SELECT has_permission('settings.manage'::text) AS has_permission) OR ( SELECT has_permission('cms.manage'::text) AS has_permission)))
  with check ((( SELECT has_permission('settings.manage'::text) AS has_permission) OR ( SELECT has_permission('cms.manage'::text) AS has_permission)));
create policy "sp_activities_read" on "public"."self_paced_activities" for select to "authenticated"
  using (((published = true) OR is_staff()));
create policy "sp_activities_staff_delete" on "public"."self_paced_activities" for delete to "authenticated"
  using (is_staff());
create policy "sp_activities_staff_update" on "public"."self_paced_activities" for update to "authenticated"
  using (is_staff())
  with check (is_staff());
create policy "sp_activities_staff_write" on "public"."self_paced_activities" for insert to "authenticated"
  with check (is_staff());
create policy "sp_lessons_read" on "public"."self_paced_lessons" for select to "authenticated"
  using (((published = true) OR is_staff()));
create policy "sp_lessons_staff_delete" on "public"."self_paced_lessons" for delete to "authenticated"
  using (is_staff());
create policy "sp_lessons_staff_update" on "public"."self_paced_lessons" for update to "authenticated"
  using (is_staff())
  with check (is_staff());
create policy "sp_lessons_staff_write" on "public"."self_paced_lessons" for insert to "authenticated"
  with check (is_staff());
create policy "sp_part_own_delete" on "public"."self_paced_participations" for delete to "authenticated"
  using (((auth.uid() = user_id) OR is_staff()));
create policy "sp_part_own_read" on "public"."self_paced_participations" for select to "authenticated"
  using (((auth.uid() = user_id) OR is_staff()));
create policy "sp_part_own_update" on "public"."self_paced_participations" for update to "authenticated"
  using (((auth.uid() = user_id) OR is_staff()))
  with check (((auth.uid() = user_id) OR is_staff()));
create policy "sp_part_own_write" on "public"."self_paced_participations" for insert to "authenticated"
  with check ((auth.uid() = user_id));
create policy "spp_own" on "public"."self_paced_plans" for all to "authenticated"
  using ((user_id = auth.uid()))
  with check ((user_id = auth.uid()));
create policy "sp_progress_own" on "public"."self_paced_progress" for all to "authenticated"
  using ((auth.uid() = user_id))
  with check ((auth.uid() = user_id));
create policy "sp_progress_staff_read" on "public"."self_paced_progress" for select to "authenticated"
  using (is_staff());
create policy "sp_progress_staff_update" on "public"."self_paced_progress" for update to "authenticated"
  using (is_staff())
  with check (is_staff());
create policy "sp_resources_read" on "public"."self_paced_resources" for select to "authenticated"
  using (((published = true) OR is_staff()));
create policy "sp_resources_staff_delete" on "public"."self_paced_resources" for delete to "authenticated"
  using (is_staff());
create policy "sp_resources_staff_update" on "public"."self_paced_resources" for update to "authenticated"
  using (is_staff())
  with check (is_staff());
create policy "sp_resources_staff_write" on "public"."self_paced_resources" for insert to "authenticated"
  with check (is_staff());
create policy "sp_submissions_own_read" on "public"."self_paced_submissions" for select to "authenticated"
  using (((auth.uid() = user_id) OR is_staff()));
create policy "sp_submissions_own_update" on "public"."self_paced_submissions" for update to "authenticated"
  using ((auth.uid() = user_id))
  with check ((auth.uid() = user_id));
create policy "sp_submissions_own_write" on "public"."self_paced_submissions" for insert to "authenticated"
  with check ((auth.uid() = user_id));
create policy "sp_submissions_staff_delete" on "public"."self_paced_submissions" for delete to "authenticated"
  using (is_staff());
create policy "sp_submissions_staff_update" on "public"."self_paced_submissions" for update to "authenticated"
  using (is_staff())
  with check (is_staff());
create policy "sp_weeks_read" on "public"."self_paced_weeks" for select to "authenticated"
  using (((published = true) OR is_staff()));
create policy "sp_weeks_staff_delete" on "public"."self_paced_weeks" for delete to "authenticated"
  using (is_staff());
create policy "sp_weeks_staff_update" on "public"."self_paced_weeks" for update to "authenticated"
  using (is_staff())
  with check (is_staff());
create policy "sp_weeks_staff_write" on "public"."self_paced_weeks" for insert to "authenticated"
  with check (is_staff());
create policy "staff_vacancies_public_open" on "public"."staff_vacancies" for select to "anon", "authenticated"
  using ((is_open = true));
create policy "staff_vacancies_staff_all" on "public"."staff_vacancies" for all to "authenticated"
  using (has_permission('cms.manage'::text))
  with check (has_permission('cms.manage'::text));
create policy "student_learning_progress_read" on "public"."student_learning_progress" for select to "authenticated"
  using (((student_id = auth.uid()) OR is_cohort_teacher(cohort_id) OR is_academic_reviewer()));
create policy "student_learning_progress_staff_write" on "public"."student_learning_progress" for all to "authenticated"
  using ((is_cohort_teacher(cohort_id) OR is_academic_reviewer()))
  with check ((is_cohort_teacher(cohort_id) OR is_academic_reviewer()));
create policy "student_learning_progress_student_update" on "public"."student_learning_progress" for update to "authenticated"
  using ((student_id = auth.uid()))
  with check (((student_id = auth.uid()) AND (status = ANY (ARRAY['not_started'::text, 'in_progress'::text]))));
create policy "student_learning_progress_student_write" on "public"."student_learning_progress" for insert to "authenticated"
  with check (((student_id = auth.uid()) AND is_cohort_member(cohort_id) AND (status = ANY (ARRAY['not_started'::text, 'in_progress'::text]))));
create policy "sm_manage_admin" on "public"."study_materials" for all to "authenticated"
  using ((is_portal_admin() OR has_permission('students.manage'::text)))
  with check ((is_portal_admin() OR has_permission('students.manage'::text)));
create policy "sm_select_all" on "public"."study_materials" for select to "authenticated"
  using (((published = true) OR is_portal_admin() OR has_permission('students.manage'::text)));
create policy "study plans public insert" on "public"."study_plans" for insert to "anon", "authenticated"
  with check (true);
create policy "study plans staff read" on "public"."study_plans" for select to "authenticated"
  using ((is_portal_admin() OR (EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = ANY (ARRAY['Super Admin'::text, 'School Admin'::text, 'Registrar'::text, 'Finance Officer'::text])))))));
create policy "study plans staff update" on "public"."study_plans" for update to "authenticated"
  using ((is_portal_admin() OR (EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = ANY (ARRAY['Super Admin'::text, 'School Admin'::text, 'Registrar'::text, 'Finance Officer'::text])))))))
  with check (true);
create policy "submissions_read" on "public"."submissions" for select to "authenticated"
  using (((student_id = auth.uid()) OR ( SELECT has_permission('assignments.manage'::text) AS has_permission) OR (EXISTS ( SELECT 1
   FROM assignments a
  WHERE ((a.id = submissions.assignment_id) AND ( SELECT is_cohort_teacher(a.cohort_id) AS is_cohort_teacher))))));
create policy "submissions_write" on "public"."submissions" for all to "authenticated"
  using ((( SELECT has_permission('assignments.manage'::text) AS has_permission) OR (( SELECT has_permission('assignments.own'::text) AS has_permission) AND (EXISTS ( SELECT 1
   FROM assignments a
  WHERE ((a.id = submissions.assignment_id) AND ( SELECT is_cohort_teacher(a.cohort_id) AS is_cohort_teacher)))))))
  with check ((( SELECT has_permission('assignments.manage'::text) AS has_permission) OR (( SELECT has_permission('assignments.own'::text) AS has_permission) AND (EXISTS ( SELECT 1
   FROM assignments a
  WHERE ((a.id = submissions.assignment_id) AND ( SELECT is_cohort_teacher(a.cohort_id) AS is_cohort_teacher)))))));
create policy "support pledges public insert" on "public"."support_pledges" for insert to "anon", "authenticated"
  with check (true);
create policy "support pledges staff read" on "public"."support_pledges" for select to "authenticated"
  using ((is_portal_admin() OR (EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = ANY (ARRAY['Super Admin'::text, 'School Admin'::text, 'Registrar'::text, 'Finance Officer'::text])))))));
create policy "support pledges staff update" on "public"."support_pledges" for update to "authenticated"
  using ((is_portal_admin() OR (EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = ANY (ARRAY['Super Admin'::text, 'School Admin'::text, 'Registrar'::text, 'Finance Officer'::text])))))))
  with check (true);
create policy "system_settings_insert" on "public"."system_settings" for insert to "authenticated"
  with check (has_permission('settings.manage'::text));
create policy "system_settings_read" on "public"."system_settings" for select to public
  using (true);
create policy "system_settings_update" on "public"."system_settings" for update to public
  using ((( SELECT has_permission('settings.manage'::text) AS has_permission) OR ( SELECT has_permission('cms.manage'::text) AS has_permission)))
  with check ((( SELECT has_permission('settings.manage'::text) AS has_permission) OR ( SELECT has_permission('cms.manage'::text) AS has_permission)));
create policy "teacher_course_plans_read" on "public"."teacher_course_plans" for select to "authenticated"
  using (((teacher_id = auth.uid()) OR is_academic_reviewer()));
create policy "teacher_course_plans_write" on "public"."teacher_course_plans" for all to "authenticated"
  using (((status <> 'approved'::text) AND ((teacher_id = auth.uid()) OR is_academic_reviewer())))
  with check (((is_academic_reviewer() AND (status = ANY (ARRAY['draft'::text, 'submitted'::text, 'rejected'::text, 'revision_requested'::text]))) OR ((teacher_id = auth.uid()) AND can_manage_cohort_plan(cohort_id) AND (status = ANY (ARRAY['draft'::text, 'submitted'::text, 'rejected'::text, 'revision_requested'::text])))));
create policy "term_report_comments_read_all" on "public"."term_report_comments" for select to public
  using (true);
create policy "term_report_comments_write_staff" on "public"."term_report_comments" for all to public
  using ((EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = ANY (ARRAY['School Admin'::text, 'Registrar'::text, 'Teacher'::text, 'Director of Education'::text, 'Executive Assistant'::text, 'Super Admin'::text]))))))
  with check ((EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = ANY (ARRAY['School Admin'::text, 'Registrar'::text, 'Teacher'::text, 'Director of Education'::text, 'Executive Assistant'::text, 'Super Admin'::text]))))));
create policy "training_materials_read" on "public"."training_materials" for select to "authenticated"
  using ((((status = 'approved'::text) AND (cohort_id IS NOT NULL) AND is_cohort_member(cohort_id)) OR (created_by = auth.uid()) OR ((cohort_id IS NOT NULL) AND is_cohort_teacher(cohort_id)) OR has_permission('materials.approve'::text)));
create policy "training_materials_write" on "public"."training_materials" for all to "authenticated"
  using (((status <> 'approved'::text) AND ((created_by = auth.uid()) OR (has_permission('materials.manage'::text) AND (cohort_id IS NOT NULL) AND is_cohort_teacher(cohort_id)) OR has_permission('materials.approve'::text))))
  with check (((has_permission('materials.manage'::text) AND (cohort_id IS NOT NULL) AND is_cohort_teacher(cohort_id) AND (status = ANY (ARRAY['draft'::text, 'submitted'::text, 'rejected'::text, 'revision_requested'::text]))) OR has_permission('materials.approve'::text)));
create policy "transparency_insert" on "public"."transparency_reports" for insert to "authenticated"
  with check (has_permission('cms.manage'::text));
create policy "transparency_read" on "public"."transparency_reports" for select to "anon", "authenticated"
  using ((published OR has_permission('cms.manage'::text)));
create policy "transparency_update" on "public"."transparency_reports" for update to "authenticated"
  using (has_permission('cms.manage'::text))
  with check (has_permission('cms.manage'::text));
create policy "vacancy_apps_public_insert" on "public"."vacancy_applications" for insert to "anon", "authenticated"
  with check ((((length(btrim(name)) >= 2) AND (length(btrim(name)) <= 120)) AND ((length(btrim(role_title)) >= 1) AND (length(btrim(role_title)) <= 160)) AND ((length(btrim(contact)) >= 3) AND (length(btrim(contact)) <= 180)) AND ((length(btrim(cover_note)) >= 1) AND (length(btrim(cover_note)) <= 5000)) AND (status = 'new'::text) AND (cv_url IS NULL) AND ((vacancy_id IS NULL) OR (EXISTS ( SELECT 1
   FROM staff_vacancies v
  WHERE ((v.id = vacancy_applications.vacancy_id) AND (v.is_open = true)))))));
create policy "vacancy_apps_staff_all" on "public"."vacancy_applications" for all to "authenticated"
  using (has_permission('cms.manage'::text))
  with check (has_permission('cms.manage'::text));
create policy "website_enquiries_public_insert" on "public"."website_enquiries" for insert to "anon", "authenticated"
  with check ((((length(btrim(name)) >= 2) AND (length(btrim(name)) <= 100)) AND ((length(btrim(contact)) >= 5) AND (length(btrim(contact)) <= 120)) AND (length(program) <= 120) AND ((length(btrim(message)) >= 1) AND (length(btrim(message)) <= 2000)) AND (source = ANY (ARRAY['contact'::text, 'faq'::text, 'whatsapp'::text])) AND (replied = false)));
create policy "website_enquiries_staff_all" on "public"."website_enquiries" for all to "authenticated"
  using ((has_permission('students.manage'::text) OR has_permission('fees.manage'::text)))
  with check ((has_permission('students.manage'::text) OR has_permission('fees.manage'::text)));
create policy "welcome_templates_read" on "public"."welcome_email_templates" for select to "authenticated"
  using (true);
create policy "welcome_templates_write" on "public"."welcome_email_templates" for all to "authenticated"
  using ((EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.status = 'Active'::text) AND (p.role = ANY (ARRAY['Super Admin'::text, 'School Admin'::text]))))))
  with check ((EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.status = 'Active'::text) AND (p.role = ANY (ARRAY['Super Admin'::text, 'School Admin'::text]))))));
create policy "yearbook public read approved" on "public"."yearbook_entries" for select to public
  using ((is_approved = true));
create policy "yearbook public submit" on "public"."yearbook_entries" for insert to public
  with check (true);
create policy "yearbook staff manage" on "public"."yearbook_entries" for all to "authenticated"
  using (has_permission('cms.manage'::text))
  with check (has_permission('cms.manage'::text));

-- ---------------------------------------------------------------------------
-- Table, sequence and function grants
-- ---------------------------------------------------------------------------
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."academic_approval_queue" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."academic_approval_queue" to service_role;
grant select on table "public"."alumni_businesses" to anon;
grant delete, insert, select, update on table "public"."alumni_businesses" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."alumni_businesses" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."announcements" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."announcements" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."announcements" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."app_integration_events" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."app_integration_events" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."app_integration_events" to service_role;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."app_integration_usage" to service_role;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."app_integration_watch" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."app_integrations" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."app_integrations" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."app_integrations" to service_role;
grant delete, insert, select, update on table "public"."application_drafts" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."application_drafts" to service_role;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."approval_events" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."approval_events" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."aptitude_control_settings" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."aptitude_control_settings" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."aptitude_control_settings" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."aptitude_preparations" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."aptitude_preparations" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."aptitude_preparations" to service_role;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."aptitude_test_results" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."aptitude_test_results" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."aptitude_test_results" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."assignments" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."assignments" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."assignments" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."assistant_research_resources" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."assistant_research_resources" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."assistant_research_resources" to service_role;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."assistant_usage" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."attendance" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."attendance" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."attendance" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."blog_posts" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."blog_posts" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."blog_posts" to service_role;
grant select on table "public"."certificate_audit" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."certificate_audit" to service_role;
grant select, update, usage on sequence "public"."certificate_serial_sequence" to service_role;
grant maintain, references, trigger, truncate on table "public"."certificates" to anon;
grant maintain, references, select, trigger, truncate on table "public"."certificates" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."certificates" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."chat_drafts" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."chat_drafts" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."chat_drafts" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."chat_group_invites" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."chat_group_invites" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."chat_group_invites" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."chat_group_join_requests" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."chat_group_join_requests" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."chat_group_join_requests" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."chat_group_members" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."chat_group_members" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."chat_group_members" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."chat_groups" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."chat_groups" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."chat_groups" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."chat_poll_votes" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."chat_poll_votes" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."chat_poll_votes" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."chat_polls" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."chat_polls" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."chat_polls" to service_role;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."class_sessions" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."class_sessions" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."cohort_students" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."cohort_students" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."cohort_students" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."cohort_timetable_slots" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."cohort_timetable_slots" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."cohort_timetable_slots" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."cohorts" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."cohorts" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."cohorts" to service_role;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."course_completions" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."course_completions" to service_role;
grant select on table "public"."course_enrollments" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."course_enrollments" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."crash_course_attempts" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."crash_course_attempts" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."crash_course_attempts" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."crash_course_enrollments" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."crash_course_enrollments" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."crash_course_enrollments" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."crash_course_lessons" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."crash_course_lessons" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."crash_course_lessons" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."crash_courses" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."crash_courses" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."crash_courses" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."crash_programs" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."crash_programs" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."crash_programs" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."data_migrations" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."data_migrations" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."data_migrations" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."direct_messages" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."direct_messages" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."direct_messages" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."discussion_replies" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."discussion_replies" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."discussion_replies" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."discussion_threads" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."discussion_threads" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."discussion_threads" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."email_outbox" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."email_outbox" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."email_outbox" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."email_templates" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."email_templates" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."email_templates" to service_role;
grant select on table "public"."enrollment_arrangement_history" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."enrollment_arrangement_history" to service_role;
grant select on table "public"."entrance_settings" to anon;
grant select, update on table "public"."entrance_settings" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."entrance_settings" to service_role;
grant insert, select on table "public"."entrance_test_results" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."entrance_test_results" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."fee_transactions" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."fee_transactions" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."fee_transactions" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."file_submissions" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."file_submissions" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."file_submissions" to service_role;
grant select on table "public"."grade_appeals" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."grade_appeals" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."grade_assessments" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."grade_assessments" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."grade_assessments" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."grade_evaluation_settings" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."grade_evaluation_settings" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."grade_evaluation_settings" to service_role;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."gradebook_settings" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."gradebook_settings" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."gradebook_settings" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."group_messages" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."group_messages" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."group_messages" to service_role;
grant select on table "public"."helpdesk_messages" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."helpdesk_messages" to service_role;
grant select on table "public"."helpdesk_tickets" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."helpdesk_tickets" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."knock_notification_events" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."knock_notification_events" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."knock_notification_events" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."learning_memory" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."learning_memory" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."learning_memory" to service_role;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."learning_units" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."learning_units" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."message_reactions" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."message_reactions" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."message_reactions" to service_role;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."module_responsibilities" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."module_responsibilities" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."newsletter_campaigns" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."newsletter_campaigns" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."newsletter_campaigns" to service_role;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."newsletter_signup_limits" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."newsletter_subscribers" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."newsletter_subscribers" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."newsletter_subscribers" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."notification_outbox" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."notification_outbox" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."notification_outbox" to service_role;
grant delete, insert, maintain, references, select, trigger, truncate on table "public"."notifications" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."notifications" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."onesignal_devices" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."onesignal_devices" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."onesignal_devices" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."payment_channels" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."payment_channels" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."payment_channels" to service_role;
grant select, update, usage on sequence "public"."payment_receipt_seq" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."payment_submissions" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."payment_submissions" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."payment_submissions" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."permissions" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."permissions" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."permissions" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."policy_acceptances" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."policy_acceptances" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."policy_acceptances" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."portal_kv" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."portal_kv" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."portal_kv" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."profiles" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."profiles" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."profiles" to service_role;
grant select, update, usage on sequence "public"."profiles_account_number_seq" to anon;
grant select, update, usage on sequence "public"."profiles_account_number_seq" to authenticated;
grant select, update, usage on sequence "public"."profiles_account_number_seq" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."program_applications" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."program_applications" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."program_applications" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."program_modules" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."program_modules" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."program_modules" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."programs" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."programs" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."programs" to service_role;
grant select, update, usage on sequence "public"."programs_course_number_seq" to anon;
grant select, update, usage on sequence "public"."programs_course_number_seq" to authenticated;
grant select, update, usage on sequence "public"."programs_course_number_seq" to service_role;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."push_dispatch_token" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."push_subscriptions" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."push_subscriptions" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."push_subscriptions" to service_role;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."quiz_attempts" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."quiz_attempts" to service_role;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."quiz_questions" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."quiz_questions" to service_role;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."quizzes" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."quizzes" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."reminder_items" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."reminder_items" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."reminder_items" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."reminder_settings" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."reminder_settings" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."reminder_settings" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."role_permissions" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."role_permissions" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."role_permissions" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."roles" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."roles" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."roles" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."school_policies" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."school_policies" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."school_policies" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."self_paced_activities" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."self_paced_activities" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."self_paced_activities" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."self_paced_lessons" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."self_paced_lessons" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."self_paced_lessons" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."self_paced_participations" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."self_paced_participations" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."self_paced_participations" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."self_paced_plans" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."self_paced_plans" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."self_paced_plans" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."self_paced_progress" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."self_paced_progress" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."self_paced_progress" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."self_paced_resources" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."self_paced_resources" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."self_paced_resources" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."self_paced_submissions" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."self_paced_submissions" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."self_paced_submissions" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."self_paced_weeks" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."self_paced_weeks" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."self_paced_weeks" to service_role;
grant select on table "public"."staff_vacancies" to anon;
grant delete, insert, select, update on table "public"."staff_vacancies" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."staff_vacancies" to service_role;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."student_learning_progress" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."student_learning_progress" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."study_materials" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."study_materials" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."study_materials" to service_role;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."study_plans" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."study_plans" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."study_plans" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."submissions" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."submissions" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."submissions" to service_role;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."support_pledges" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."support_pledges" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."support_pledges" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."system_settings" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."system_settings" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."system_settings" to service_role;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."teacher_course_plans" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."teacher_course_plans" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."term_report_comments" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."term_report_comments" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."term_report_comments" to service_role;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."training_materials" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."training_materials" to service_role;
grant select on table "public"."transparency_reports" to anon;
grant insert, select on table "public"."transparency_reports" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."transparency_reports" to service_role;
grant delete, insert, select, update on table "public"."vacancy_applications" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."vacancy_applications" to service_role;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."website_enquiries" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."website_enquiries" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."website_enquiries" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."welcome_email_templates" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."welcome_email_templates" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."welcome_email_templates" to service_role;
grant maintain, references, select, trigger, truncate on table "public"."yearbook_entries" to anon;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."yearbook_entries" to authenticated;
grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."yearbook_entries" to service_role;
grant execute on function "public"."_approved_enrollment_to_roster"() to service_role;
grant execute on function "public"."_attempt_payload"(p_attempt_id uuid) to service_role;
grant execute on function "public"."_attendance_standing"(p_student_id uuid, p_cohort_id uuid) to service_role;
grant execute on function "public"."_blog_payments_touch"() to service_role;
grant execute on function "public"."_claim_push_rows"(p_limit integer) to service_role;
grant execute on function "public"."_confirmed_account_congratulations_trigger"() to service_role;
grant execute on function "public"."_course_enrollment_preview"(p_student_id uuid, p_cohort_id uuid, p_check_window boolean) to service_role;
grant execute on function "public"."_cron_dispatch_push"() to service_role;
grant execute on function "public"."_cron_dispatch_send_email"() to service_role;
grant execute on function "public"."_dispatch_knock_for_notification"() to anon;
grant execute on function "public"."_dispatch_knock_for_notification"() to authenticated;
grant execute on function "public"."_dispatch_knock_for_notification"() to public;
grant execute on function "public"."_dispatch_knock_for_notification"() to service_role;
grant execute on function "public"."_enqueue_notification_email"() to service_role;
grant execute on function "public"."_grade_quiz_attempt"(p_attempt_id uuid, p_new_status text, p_force boolean) to service_role;
grant execute on function "public"."_normalize_training_material_status"() to service_role;
grant execute on function "public"."_notify_academic_status"() to service_role;
grant execute on function "public"."_notify_attendance"() to service_role;
grant execute on function "public"."_notify_direct_message"() to service_role;
grant execute on function "public"."_notify_group_message"() to anon;
grant execute on function "public"."_notify_group_message"() to authenticated;
grant execute on function "public"."_notify_group_message"() to public;
grant execute on function "public"."_notify_group_message"() to service_role;
grant execute on function "public"."_notify_schedule_updated"() to service_role;
grant execute on function "public"."_profile_congratulations_trigger"() to service_role;
grant execute on function "public"."_queue_account_congratulations"(p_user_id uuid) to service_role;
grant execute on function "public"."_queue_push_for_notification"() to service_role;
grant execute on function "public"."_quiz_questions_totals"() to service_role;
grant execute on function "public"."_quiz_questions_validate"() to service_role;
grant execute on function "public"."_quizzes_touch"() to service_role;
grant execute on function "public"."_recompute_cohort_progress"(p_cohort_id uuid) to service_role;
grant execute on function "public"."_recompute_course_progress"() to service_role;
grant execute on function "public"."_recompute_enrollment_progress"(p_enrollment_id uuid) to service_role;
grant execute on function "public"."_recompute_progress_on_unit_change"() to service_role;
grant execute on function "public"."_record_approval_event"() to service_role;
grant execute on function "public"."_touch_academic_row"() to service_role;
grant execute on function "public"."_touch_updated_at"() to anon;
grant execute on function "public"."_touch_updated_at"() to authenticated;
grant execute on function "public"."_touch_updated_at"() to public;
grant execute on function "public"."_touch_updated_at"() to service_role;
grant execute on function "public"."_validate_class_session"() to service_role;
grant execute on function "public"."_validate_learning_unit_approval"() to service_role;
grant execute on function "public"."_validate_learning_unit_component"() to service_role;
grant execute on function "public"."_validate_student_learning_progress"() to service_role;
grant execute on function "public"."adjust_quiz_answer_points"(p_attempt_id uuid, p_question_id uuid, p_points numeric) to authenticated;
grant execute on function "public"."adjust_quiz_answer_points"(p_attempt_id uuid, p_question_id uuid, p_points numeric) to service_role;
grant execute on function "public"."announcement_visible_to_me"(p_announcement_id uuid) to anon;
grant execute on function "public"."announcement_visible_to_me"(p_announcement_id uuid) to authenticated;
grant execute on function "public"."announcement_visible_to_me"(p_announcement_id uuid) to service_role;
grant execute on function "public"."app_integration_resolve"(p_app_slug text, p_manifest_id text) to service_role;
grant execute on function "public"."app_integration_take"(p_manifest_id text, p_person text, p_anon boolean, p_app_slug text) to service_role;
grant execute on function "public"."app_integration_watch_add"(p_manifest_id text, p_op text, p_rule text) to service_role;
grant execute on function "public"."assistant_add_tokens"(p_bucket text, p_window_seconds integer, p_tokens integer) to service_role;
grant execute on function "public"."assistant_admin_stats"() to authenticated;
grant execute on function "public"."assistant_admin_stats"() to service_role;
grant execute on function "public"."assistant_consume"(p_bucket text, p_window_seconds integer, p_max_requests integer) to service_role;
grant execute on function "public"."blob_authorize"(p_action text, p_bucket text, p_key text) to anon;
grant execute on function "public"."blob_authorize"(p_action text, p_bucket text, p_key text) to authenticated;
grant execute on function "public"."blob_authorize"(p_action text, p_bucket text, p_key text) to service_role;
grant execute on function "public"."can_manage_cohort_plan"(p_cohort_id uuid) to anon;
grant execute on function "public"."can_manage_cohort_plan"(p_cohort_id uuid) to authenticated;
grant execute on function "public"."can_manage_cohort_plan"(p_cohort_id uuid) to service_role;
grant execute on function "public"."can_manage_helpdesk"() to anon;
grant execute on function "public"."can_manage_helpdesk"() to authenticated;
grant execute on function "public"."can_manage_helpdesk"() to service_role;
grant execute on function "public"."can_manage_learning_unit"(p_unit_id uuid) to anon;
grant execute on function "public"."can_manage_learning_unit"(p_unit_id uuid) to authenticated;
grant execute on function "public"."can_manage_learning_unit"(p_unit_id uuid) to service_role;
grant execute on function "public"."can_manage_quiz"(q uuid) to anon;
grant execute on function "public"."can_manage_quiz"(q uuid) to authenticated;
grant execute on function "public"."can_manage_quiz"(q uuid) to service_role;
grant execute on function "public"."can_manage_quiz_scope"(p_program uuid, p_cohort uuid) to anon;
grant execute on function "public"."can_manage_quiz_scope"(p_program uuid, p_cohort uuid) to authenticated;
grant execute on function "public"."can_manage_quiz_scope"(p_program uuid, p_cohort uuid) to service_role;
grant execute on function "public"."can_manage_training_material_folder"(p_folder text) to anon;
grant execute on function "public"."can_manage_training_material_folder"(p_folder text) to authenticated;
grant execute on function "public"."can_manage_training_material_folder"(p_folder text) to service_role;
grant execute on function "public"."can_read_discussion"(c uuid) to anon;
grant execute on function "public"."can_read_discussion"(c uuid) to authenticated;
grant execute on function "public"."can_read_discussion"(c uuid) to service_role;
grant execute on function "public"."can_read_profile"(p uuid) to anon;
grant execute on function "public"."can_read_profile"(p uuid) to authenticated;
grant execute on function "public"."can_read_profile"(p uuid) to service_role;
grant execute on function "public"."can_review_grade_appeals"() to anon;
grant execute on function "public"."can_review_grade_appeals"() to authenticated;
grant execute on function "public"."can_review_grade_appeals"() to service_role;
grant execute on function "public"."can_view_quiz_results"(q uuid) to anon;
grant execute on function "public"."can_view_quiz_results"(q uuid) to authenticated;
grant execute on function "public"."can_view_quiz_results"(q uuid) to service_role;
grant execute on function "public"."close_expired_course_windows"() to service_role;
grant execute on function "public"."course_grade_summary"(p_student_id uuid, p_cohort_id uuid) to authenticated;
grant execute on function "public"."course_grade_summary"(p_student_id uuid, p_cohort_id uuid) to service_role;
grant execute on function "public"."create_academic_lesson_bundle"(p_program_id uuid, p_cohort_id uuid, p_course_plan_id uuid, p_title text, p_summary text, p_unit_type text, p_position integer, p_due_at timestamp with time zone, p_classwork_minutes integer, p_classwork_weight numeric, p_quiz_minutes integer, p_quiz_weight numeric, p_available_from timestamp with time zone) to authenticated;
grant execute on function "public"."create_academic_lesson_bundle"(p_program_id uuid, p_cohort_id uuid, p_course_plan_id uuid, p_title text, p_summary text, p_unit_type text, p_position integer, p_due_at timestamp with time zone, p_classwork_minutes integer, p_classwork_weight numeric, p_quiz_minutes integer, p_quiz_weight numeric, p_available_from timestamp with time zone) to service_role;
grant execute on function "public"."create_grade_appeal"(p_id uuid, p_kind text, p_ref uuid, p_reason text) to anon;
grant execute on function "public"."create_grade_appeal"(p_id uuid, p_kind text, p_ref uuid, p_reason text) to authenticated;
grant execute on function "public"."create_grade_appeal"(p_id uuid, p_kind text, p_ref uuid, p_reason text) to service_role;
grant execute on function "public"."create_helpdesk_ticket"(p_id uuid, p_subject text, p_category text, p_body text) to anon;
grant execute on function "public"."create_helpdesk_ticket"(p_id uuid, p_subject text, p_category text, p_body text) to authenticated;
grant execute on function "public"."create_helpdesk_ticket"(p_id uuid, p_subject text, p_category text, p_body text) to service_role;
grant execute on function "public"."decide_grade_appeal"(p_appeal uuid, p_decision text, p_score numeric, p_note text) to anon;
grant execute on function "public"."decide_grade_appeal"(p_appeal uuid, p_decision text, p_score numeric, p_note text) to authenticated;
grant execute on function "public"."decide_grade_appeal"(p_appeal uuid, p_decision text, p_score numeric, p_note text) to service_role;
grant execute on function "public"."discussion_guard"() to anon;
grant execute on function "public"."discussion_guard"() to authenticated;
grant execute on function "public"."discussion_guard"() to service_role;
grant execute on function "public"."enqueue_email"(p_to_email text, p_to_name text, p_template text, p_subject text, p_payload jsonb, p_related_user_id uuid, p_dedupe_key text, p_send_after timestamp with time zone) to service_role;
grant execute on function "public"."finalize_expired_quiz_attempts"(p_quiz_id uuid) to anon;
grant execute on function "public"."finalize_expired_quiz_attempts"(p_quiz_id uuid) to authenticated;
grant execute on function "public"."finalize_expired_quiz_attempts"(p_quiz_id uuid) to service_role;
grant execute on function "public"."get_quiz_review"(p_attempt_id uuid) to anon;
grant execute on function "public"."get_quiz_review"(p_attempt_id uuid) to authenticated;
grant execute on function "public"."get_quiz_review"(p_attempt_id uuid) to service_role;
grant execute on function "public"."guard_administrator_profile_changes"() to anon;
grant execute on function "public"."guard_administrator_profile_changes"() to authenticated;
grant execute on function "public"."guard_administrator_profile_changes"() to service_role;
grant execute on function "public"."guard_transparency_file"() to anon;
grant execute on function "public"."guard_transparency_file"() to authenticated;
grant execute on function "public"."guard_transparency_file"() to service_role;
grant execute on function "public"."handle_new_user"() to service_role;
grant execute on function "public"."has_permission"(perm text) to anon;
grant execute on function "public"."has_permission"(perm text) to authenticated;
grant execute on function "public"."has_permission"(perm text) to service_role;
grant execute on function "public"."is_academic_reviewer"() to anon;
grant execute on function "public"."is_academic_reviewer"() to authenticated;
grant execute on function "public"."is_academic_reviewer"() to service_role;
grant execute on function "public"."is_admin"() to anon;
grant execute on function "public"."is_admin"() to authenticated;
grant execute on function "public"."is_admin"() to public;
grant execute on function "public"."is_admin"() to service_role;
grant execute on function "public"."is_chat_group_admin"(gid uuid) to anon;
grant execute on function "public"."is_chat_group_admin"(gid uuid) to authenticated;
grant execute on function "public"."is_chat_group_admin"(gid uuid) to public;
grant execute on function "public"."is_chat_group_admin"(gid uuid) to service_role;
grant execute on function "public"."is_chat_group_member"(gid uuid) to anon;
grant execute on function "public"."is_chat_group_member"(gid uuid) to authenticated;
grant execute on function "public"."is_chat_group_member"(gid uuid) to public;
grant execute on function "public"."is_chat_group_member"(gid uuid) to service_role;
grant execute on function "public"."is_cohort_member"(c uuid) to anon;
grant execute on function "public"."is_cohort_member"(c uuid) to authenticated;
grant execute on function "public"."is_cohort_member"(c uuid) to service_role;
grant execute on function "public"."is_cohort_teacher"(c uuid) to anon;
grant execute on function "public"."is_cohort_teacher"(c uuid) to authenticated;
grant execute on function "public"."is_cohort_teacher"(c uuid) to service_role;
grant execute on function "public"."is_portal_admin"() to anon;
grant execute on function "public"."is_portal_admin"() to authenticated;
grant execute on function "public"."is_portal_admin"() to service_role;
grant execute on function "public"."is_staff"() to anon;
grant execute on function "public"."is_staff"() to authenticated;
grant execute on function "public"."is_staff"() to public;
grant execute on function "public"."is_staff"() to service_role;
grant execute on function "public"."is_super_admin"() to anon;
grant execute on function "public"."is_super_admin"() to authenticated;
grant execute on function "public"."is_super_admin"() to service_role;
grant execute on function "public"."issue_certificate"(p_student_id uuid, p_program_id uuid, p_honors text, p_certificate_type text, p_completion_date date) to authenticated;
grant execute on function "public"."issue_certificate"(p_student_id uuid, p_program_id uuid, p_honors text, p_certificate_type text, p_completion_date date) to service_role;
grant execute on function "public"."list_appealable_work"() to anon;
grant execute on function "public"."list_appealable_work"() to authenticated;
grant execute on function "public"."list_appealable_work"() to service_role;
grant execute on function "public"."log_certificate_event"() to anon;
grant execute on function "public"."log_certificate_event"() to authenticated;
grant execute on function "public"."log_certificate_event"() to service_role;
grant execute on function "public"."my_course_status"() to authenticated;
grant execute on function "public"."my_course_status"() to service_role;
grant execute on function "public"."next_certificate_serial"() to service_role;
grant execute on function "public"."notifications_sync_read_state"() to service_role;
grant execute on function "public"."preview_course_enrollment"(p_cohort_id uuid) to authenticated;
grant execute on function "public"."preview_course_enrollment"(p_cohort_id uuid) to service_role;
grant execute on function "public"."programs_ensure_code"() to anon;
grant execute on function "public"."programs_ensure_code"() to authenticated;
grant execute on function "public"."programs_ensure_code"() to public;
grant execute on function "public"."programs_ensure_code"() to service_role;
grant execute on function "public"."programs_sync_title_name"() to anon;
grant execute on function "public"."programs_sync_title_name"() to authenticated;
grant execute on function "public"."programs_sync_title_name"() to public;
grant execute on function "public"."programs_sync_title_name"() to service_role;
grant execute on function "public"."protect_certificate_identity"() to anon;
grant execute on function "public"."protect_certificate_identity"() to authenticated;
grant execute on function "public"."protect_certificate_identity"() to service_role;
grant execute on function "public"."protect_profile_privileges"() to anon;
grant execute on function "public"."protect_profile_privileges"() to authenticated;
grant execute on function "public"."protect_profile_privileges"() to service_role;
grant execute on function "public"."protect_record_number"() to anon;
grant execute on function "public"."protect_record_number"() to authenticated;
grant execute on function "public"."protect_record_number"() to service_role;
grant execute on function "public"."protect_system_settings"() to anon;
grant execute on function "public"."protect_system_settings"() to authenticated;
grant execute on function "public"."protect_system_settings"() to service_role;
grant execute on function "public"."queue_account_congratulations"(p_user_id uuid) to authenticated;
grant execute on function "public"."queue_account_congratulations"(p_user_id uuid) to service_role;
grant execute on function "public"."queue_newsletter_campaign"(p_template_id uuid, p_campaign_id uuid) to authenticated;
grant execute on function "public"."queue_newsletter_campaign"(p_template_id uuid, p_campaign_id uuid) to service_role;
grant execute on function "public"."quiz_visible_to_me"(q uuid) to anon;
grant execute on function "public"."quiz_visible_to_me"(q uuid) to authenticated;
grant execute on function "public"."quiz_visible_to_me"(q uuid) to service_role;
grant execute on function "public"."record_learning_progress"(p_unit_id uuid, p_status text) to authenticated;
grant execute on function "public"."record_learning_progress"(p_unit_id uuid, p_status text) to service_role;
grant execute on function "public"."register_push_subscription"(p_endpoint text, p_p256dh text, p_auth text, p_user_agent text) to authenticated;
grant execute on function "public"."register_push_subscription"(p_endpoint text, p_p256dh text, p_auth text, p_user_agent text) to service_role;
grant execute on function "public"."regrade_quiz"(p_quiz_id uuid) to authenticated;
grant execute on function "public"."regrade_quiz"(p_quiz_id uuid) to service_role;
grant execute on function "public"."reply_helpdesk_ticket"(p_id uuid, p_ticket uuid, p_body text) to anon;
grant execute on function "public"."reply_helpdesk_ticket"(p_id uuid, p_ticket uuid, p_body text) to authenticated;
grant execute on function "public"."reply_helpdesk_ticket"(p_id uuid, p_ticket uuid, p_body text) to service_role;
grant execute on function "public"."request_newsletter_signup"(p_email text, p_name text, p_consent text, p_hash text, p_link text, p_bucket text) to service_role;
grant execute on function "public"."retry_failed_emails"() to authenticated;
grant execute on function "public"."retry_failed_emails"() to service_role;
grant execute on function "public"."review_academic_submission"(p_entity_type text, p_entity_id uuid, p_decision text, p_note text) to authenticated;
grant execute on function "public"."review_academic_submission"(p_entity_type text, p_entity_id uuid, p_decision text, p_note text) to service_role;
grant execute on function "public"."review_payment"(p_submission_id uuid, p_decision text, p_note text, p_ledger_amount_usd numeric) to authenticated;
grant execute on function "public"."review_payment"(p_submission_id uuid, p_decision text, p_note text, p_ledger_amount_usd numeric) to service_role;
grant execute on function "public"."revoke_certificate"(p_certificate_id uuid, p_reason text) to authenticated;
grant execute on function "public"."revoke_certificate"(p_certificate_id uuid, p_reason text) to service_role;
grant execute on function "public"."save_quiz_answer"(p_attempt_id uuid, p_question_id uuid, p_answer jsonb) to anon;
grant execute on function "public"."save_quiz_answer"(p_attempt_id uuid, p_question_id uuid, p_answer jsonb) to authenticated;
grant execute on function "public"."save_quiz_answer"(p_attempt_id uuid, p_question_id uuid, p_answer jsonb) to service_role;
grant execute on function "public"."set_helpdesk_status"(p_ticket uuid, p_status text, p_reason text) to anon;
grant execute on function "public"."set_helpdesk_status"(p_ticket uuid, p_status text, p_reason text) to authenticated;
grant execute on function "public"."set_helpdesk_status"(p_ticket uuid, p_status text, p_reason text) to service_role;
grant execute on function "public"."start_classwork"(p_assignment_id uuid) to authenticated;
grant execute on function "public"."start_classwork"(p_assignment_id uuid) to service_role;
grant execute on function "public"."start_quiz_attempt"(p_quiz_id uuid) to anon;
grant execute on function "public"."start_quiz_attempt"(p_quiz_id uuid) to authenticated;
grant execute on function "public"."start_quiz_attempt"(p_quiz_id uuid) to service_role;
grant execute on function "public"."submit_academic_item"(p_entity_type text, p_entity_id uuid) to authenticated;
grant execute on function "public"."submit_academic_item"(p_entity_type text, p_entity_id uuid) to service_role;
grant execute on function "public"."submit_classwork"(p_assignment_id uuid, p_response_text text, p_attachment_path text) to authenticated;
grant execute on function "public"."submit_classwork"(p_assignment_id uuid, p_response_text text, p_attachment_path text) to service_role;
grant execute on function "public"."submit_course_enrollment"(p_cohort_id uuid) to authenticated;
grant execute on function "public"."submit_course_enrollment"(p_cohort_id uuid) to service_role;
grant execute on function "public"."submit_course_enrollment_with_arrangement"(p_cohort_id uuid, p_arrangement text) to authenticated;
grant execute on function "public"."submit_course_enrollment_with_arrangement"(p_cohort_id uuid, p_arrangement text) to service_role;
grant execute on function "public"."submit_payment"(p_channel_id uuid, p_amount numeric, p_currency text, p_category text, p_payer_phone text, p_transaction_reference text, p_paid_on date, p_note text) to authenticated;
grant execute on function "public"."submit_payment"(p_channel_id uuid, p_amount numeric, p_currency text, p_category text, p_payer_phone text, p_transaction_reference text, p_paid_on date, p_note text) to service_role;
grant execute on function "public"."submit_quiz_attempt"(p_attempt_id uuid, p_answers jsonb) to anon;
grant execute on function "public"."submit_quiz_attempt"(p_attempt_id uuid, p_answers jsonb) to authenticated;
grant execute on function "public"."submit_quiz_attempt"(p_attempt_id uuid, p_answers jsonb) to service_role;
grant execute on function "public"."sync_aptitude_to_entrance"() to anon;
grant execute on function "public"."sync_aptitude_to_entrance"() to authenticated;
grant execute on function "public"."sync_aptitude_to_entrance"() to public;
grant execute on function "public"."sync_aptitude_to_entrance"() to service_role;
grant execute on function "public"."teaches_student"(s uuid) to anon;
grant execute on function "public"."teaches_student"(s uuid) to authenticated;
grant execute on function "public"."teaches_student"(s uuid) to service_role;
grant execute on function "public"."update_helpdesk_ticket_status"(p_ticket_id uuid, p_status text) to authenticated;
grant execute on function "public"."update_helpdesk_ticket_status"(p_ticket_id uuid, p_status text) to service_role;
grant execute on function "public"."verify_public_certificate"(p_serial text) to anon;
grant execute on function "public"."verify_public_certificate"(p_serial text) to authenticated;
grant execute on function "public"."verify_public_certificate"(p_serial text) to service_role;

-- ---------------------------------------------------------------------------
-- Storage buckets and policies
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', true, 5242880, array['image/jpeg', 'image/png', 'image/webp', 'image/gif'])
on conflict (id) do update set public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('blog-covers', 'blog-covers', true, 5242880, array['image/jpeg', 'image/png', 'image/webp', 'image/gif'])
on conflict (id) do update set public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('business-logos', 'business-logos', true, 5242880, array['image/jpeg', 'image/png', 'image/webp', 'image/gif'])
on conflict (id) do update set public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('certificates', 'certificates', false, 10485760, array['application/pdf', 'image/jpeg', 'image/png'])
on conflict (id) do update set public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('chat-attachments', 'chat-attachments', false, 26214400, array['application/pdf', 'text/plain', 'application/zip', 'application/x-zip-compressed', 'image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/heic', 'video/mp4', 'video/webm', 'video/quicktime', 'audio/mpeg', 'audio/wav', 'audio/ogg', 'audio/mp4', 'audio/x-m4a', 'application/msword', 'application/vnd.ms-powerpoint', 'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'application/vnd.openxmlformats-officedocument.presentationml.presentation', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'])
on conflict (id) do update set public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('classwork-submissions', 'classwork-submissions', false, 26214400, array['application/pdf', 'text/plain', 'application/zip', 'application/x-zip-compressed', 'image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/svg+xml', 'image/heic', 'video/mp4', 'video/webm', 'video/quicktime', 'audio/mpeg', 'audio/wav', 'audio/ogg', 'audio/mp4', 'audio/x-m4a', 'application/msword', 'application/vnd.ms-powerpoint', 'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'application/vnd.openxmlformats-officedocument.presentationml.presentation', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'])
on conflict (id) do update set public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('documents', 'documents', false, 10485760, array['application/pdf', 'image/jpeg', 'image/png', 'image/webp', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'])
on conflict (id) do update set public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('program-images', 'program-images', true, 5242880, array['image/jpeg', 'image/png', 'image/webp', 'image/gif'])
on conflict (id) do update set public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('site-assets', 'site-assets', true, 5242880, array['image/jpeg', 'image/png', 'image/webp', 'image/gif'])
on conflict (id) do update set public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('site-videos', 'site-videos', true, 52428800, array['video/mp4', 'video/webm', 'video/quicktime'])
on conflict (id) do update set public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('training-materials', 'training-materials', false, 26214400, array['application/pdf', 'text/plain', 'application/zip', 'application/x-zip-compressed', 'image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/svg+xml', 'image/heic', 'video/mp4', 'video/webm', 'video/quicktime', 'audio/mpeg', 'audio/wav', 'audio/ogg', 'audio/mp4', 'audio/x-m4a', 'application/msword', 'application/vnd.ms-powerpoint', 'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'application/vnd.openxmlformats-officedocument.presentationml.presentation', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'])
on conflict (id) do update set public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('transparency-reports', 'transparency-reports', false, 10485760, array['application/pdf'])
on conflict (id) do update set public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;
create policy "avatars_owner_all" on storage.objects for all to "authenticated"
  using (((bucket_id = 'avatars'::text) AND ((storage.foldername(name))[1] = (auth.uid())::text)))
  with check (((bucket_id = 'avatars'::text) AND ((storage.foldername(name))[1] = (auth.uid())::text)));
create policy "avatars_public_read" on storage.objects for select to public
  using ((bucket_id = 'avatars'::text));
create policy "blog_covers_manage_all" on storage.objects for all to "authenticated"
  using (((bucket_id = 'blog-covers'::text) AND ( SELECT has_permission('blog.manage'::text) AS has_permission)))
  with check (((bucket_id = 'blog-covers'::text) AND ( SELECT has_permission('blog.manage'::text) AS has_permission)));
create policy "business_logos_public_read" on storage.objects for select to public
  using ((bucket_id = 'business-logos'::text));
create policy "business_logos_public_submit" on storage.objects for insert to "anon", "authenticated"
  with check (((bucket_id = 'business-logos'::text) AND ((storage.foldername(name))[1] = 'businesses'::text) AND (array_length(storage.foldername(name), 1) = 1) AND (lower(storage.filename(name)) ~ '\.(jpe?g|png|webp|gif)$'::text)));
create policy "business_logos_staff_manage" on storage.objects for all to "authenticated"
  using (((bucket_id = 'business-logos'::text) AND has_permission('cms.manage'::text)))
  with check (((bucket_id = 'business-logos'::text) AND has_permission('cms.manage'::text)));
create policy "certificates_manage_all" on storage.objects for all to "authenticated"
  using (((bucket_id = 'certificates'::text) AND ( SELECT has_permission('certificates.manage'::text) AS has_permission)))
  with check (((bucket_id = 'certificates'::text) AND ( SELECT has_permission('certificates.manage'::text) AS has_permission)));
create policy "chat attachments delete" on storage.objects for delete to "authenticated"
  using (((bucket_id = 'chat-attachments'::text) AND ((((storage.foldername(name))[1] = 'dm'::text) AND ((storage.foldername(name))[2] = (auth.uid())::text)) OR (((storage.foldername(name))[1] = 'group'::text) AND (EXISTS ( SELECT 1
   FROM chat_group_members m
  WHERE ((m.group_id = ((storage.foldername(objects.name))[2])::uuid) AND (m.user_id = auth.uid()))))))));
create policy "chat attachments read" on storage.objects for select to public
  using (((bucket_id = 'chat-attachments'::text) AND ((((storage.foldername(name))[1] = 'dm'::text) AND ((storage.foldername(name))[2] = (auth.uid())::text)) OR (((storage.foldername(name))[1] = 'dm'::text) AND ((storage.foldername(name))[3] = (auth.uid())::text)) OR (((storage.foldername(name))[1] = 'group'::text) AND is_chat_group_member(((storage.foldername(name))[2])::uuid)))));
create policy "chat attachments write" on storage.objects for insert to "authenticated"
  with check (((bucket_id = 'chat-attachments'::text) AND ((((storage.foldername(name))[1] = 'dm'::text) AND ((storage.foldername(name))[2] = (auth.uid())::text)) OR (((storage.foldername(name))[1] = 'group'::text) AND (EXISTS ( SELECT 1
   FROM chat_group_members m
  WHERE ((m.group_id = ((storage.foldername(objects.name))[2])::uuid) AND (m.user_id = auth.uid()))))))));
create policy "classwork_submissions_insert" on storage.objects for insert to "authenticated"
  with check (((bucket_id = 'classwork-submissions'::text) AND ((storage.foldername(name))[2] = (auth.uid())::text) AND (EXISTS ( SELECT 1
   FROM assignments a
  WHERE (((a.id)::text = (storage.foldername(objects.name))[1]) AND is_cohort_member(a.cohort_id))))));
create policy "classwork_submissions_select" on storage.objects for select to "authenticated"
  using (((bucket_id = 'classwork-submissions'::text) AND (((storage.foldername(name))[2] = (auth.uid())::text) OR (EXISTS ( SELECT 1
   FROM assignments a
  WHERE (((a.id)::text = (storage.foldername(objects.name))[1]) AND (is_cohort_teacher(a.cohort_id) OR has_permission('assignments.manage'::text))))))));
create policy "documents_admin_all" on storage.objects for all to "authenticated"
  using (((bucket_id = 'documents'::text) AND (has_permission('students.manage'::text) OR has_permission('staff.manage'::text))))
  with check (((bucket_id = 'documents'::text) AND (has_permission('students.manage'::text) OR has_permission('staff.manage'::text))));
create policy "documents_admin_read" on storage.objects for select to "authenticated"
  using (((bucket_id = 'documents'::text) AND (( SELECT has_permission('people.view'::text) AS has_permission) OR ( SELECT has_permission('students.manage'::text) AS has_permission) OR ( SELECT has_permission('staff.manage'::text) AS has_permission))));
create policy "documents_admin_write" on storage.objects for all to "authenticated"
  using (((bucket_id = 'documents'::text) AND (( SELECT has_permission('students.manage'::text) AS has_permission) OR ( SELECT has_permission('staff.manage'::text) AS has_permission))))
  with check (((bucket_id = 'documents'::text) AND (( SELECT has_permission('students.manage'::text) AS has_permission) OR ( SELECT has_permission('staff.manage'::text) AS has_permission))));
create policy "documents_owner_all" on storage.objects for all to "authenticated"
  using (((bucket_id = 'documents'::text) AND ((storage.foldername(name))[1] = 'profiles'::text) AND ((storage.foldername(name))[2] = (auth.uid())::text)))
  with check (((bucket_id = 'documents'::text) AND ((storage.foldername(name))[1] = 'profiles'::text) AND ((storage.foldername(name))[2] = (auth.uid())::text)));
create policy "program_images_admin_all" on storage.objects for all to "authenticated"
  using (((bucket_id = 'program-images'::text) AND is_portal_admin()))
  with check (((bucket_id = 'program-images'::text) AND is_portal_admin()));
create policy "program_images_manage_all" on storage.objects for all to "authenticated"
  using (((bucket_id = 'program-images'::text) AND ( SELECT has_permission('programs.manage'::text) AS has_permission)))
  with check (((bucket_id = 'program-images'::text) AND ( SELECT has_permission('programs.manage'::text) AS has_permission)));
create policy "program_images_public_read" on storage.objects for select to public
  using ((bucket_id = 'program-images'::text));
create policy "site_assets_admin_all" on storage.objects for all to "authenticated"
  using (((bucket_id = 'site-assets'::text) AND is_portal_admin()))
  with check (((bucket_id = 'site-assets'::text) AND is_portal_admin()));
create policy "site_assets_chat_backgrounds_insert" on storage.objects for insert to "authenticated"
  with check (((bucket_id = 'site-assets'::text) AND ((storage.foldername(name))[1] = (auth.uid())::text) AND (array_length(storage.foldername(name), 1) = 1) AND (lower(storage.filename(name)) ~~ 'chat-bg-%'::text) AND (lower(storage.filename(name)) ~ '\.(jpe?g|png|webp|gif)$'::text)));
create policy "site_assets_manage_all" on storage.objects for all to "authenticated"
  using (((bucket_id = 'site-assets'::text) AND ( SELECT has_permission('cms.manage'::text) AS has_permission)))
  with check (((bucket_id = 'site-assets'::text) AND ( SELECT has_permission('cms.manage'::text) AS has_permission)));
create policy "site_assets_public_read" on storage.objects for select to public
  using ((bucket_id = 'site-assets'::text));
create policy "site_videos_admin_all" on storage.objects for all to "authenticated"
  using (((bucket_id = 'site-videos'::text) AND has_permission('cms.manage'::text)))
  with check (((bucket_id = 'site-videos'::text) AND has_permission('cms.manage'::text)));
create policy "site_videos_manage_all" on storage.objects for all to "authenticated"
  using (((bucket_id = 'site-videos'::text) AND has_permission('cms.manage'::text)))
  with check (((bucket_id = 'site-videos'::text) AND has_permission('cms.manage'::text)));
create policy "site_videos_public_read" on storage.objects for select to public
  using ((bucket_id = 'site-videos'::text));
create policy "training_materials_private_delete" on storage.objects for delete to "authenticated"
  using (((bucket_id = 'training-materials'::text) AND can_manage_training_material_folder((storage.foldername(name))[1]) AND (has_permission('materials.approve'::text) OR (NOT (EXISTS ( SELECT 1
   FROM training_materials m
  WHERE ((m.file_path = objects.name) AND (m.status = 'approved'::text))))))));
create policy "training_materials_private_insert" on storage.objects for insert to "authenticated"
  with check (((bucket_id = 'training-materials'::text) AND can_manage_training_material_folder((storage.foldername(name))[1])));
create policy "training_materials_private_read" on storage.objects for select to "authenticated"
  using (((bucket_id = 'training-materials'::text) AND (EXISTS ( SELECT 1
   FROM training_materials m
  WHERE ((m.file_path = objects.name) AND (((m.status = 'approved'::text) AND is_cohort_member(m.cohort_id)) OR (has_permission('materials.manage'::text) AND (m.cohort_id IS NOT NULL) AND is_cohort_teacher(m.cohort_id)) OR has_permission('materials.approve'::text)))))));
create policy "training_materials_private_update" on storage.objects for update to "authenticated"
  using (((bucket_id = 'training-materials'::text) AND can_manage_training_material_folder((storage.foldername(name))[1]) AND (has_permission('materials.approve'::text) OR (NOT (EXISTS ( SELECT 1
   FROM training_materials m
  WHERE ((m.file_path = objects.name) AND (m.status = 'approved'::text))))))))
  with check (((bucket_id = 'training-materials'::text) AND can_manage_training_material_folder((storage.foldername(name))[1])));
create policy "transparency_file_read" on storage.objects for select to "anon", "authenticated"
  using (((bucket_id = 'transparency-reports'::text) AND (has_permission('cms.manage'::text) OR (EXISTS ( SELECT 1
   FROM transparency_reports r
  WHERE ((r.file_path = objects.name) AND r.published))))));
create policy "transparency_file_upload" on storage.objects for insert to "authenticated"
  with check (((bucket_id = 'transparency-reports'::text) AND has_permission('cms.manage'::text) AND (name ~ '^[0-9a-f-]{36}\\.pdf$'::text)));
create policy "transparency_orphan_cleanup" on storage.objects for delete to "authenticated"
  using (((bucket_id = 'transparency-reports'::text) AND has_permission('cms.manage'::text) AND (NOT (EXISTS ( SELECT 1
   FROM transparency_reports r
  WHERE (r.file_path = objects.name))))));

-- ---------------------------------------------------------------------------
-- Realtime publication
-- ---------------------------------------------------------------------------
alter publication supabase_realtime add table "public"."alumni_businesses";
alter publication supabase_realtime add table "public"."announcements";
alter publication supabase_realtime add table "public"."assignments";
alter publication supabase_realtime add table "public"."attendance";
alter publication supabase_realtime add table "public"."blog_posts";
alter publication supabase_realtime add table "public"."certificates";
alter publication supabase_realtime add table "public"."chat_group_join_requests";
alter publication supabase_realtime add table "public"."chat_group_members";
alter publication supabase_realtime add table "public"."chat_groups";
alter publication supabase_realtime add table "public"."chat_poll_votes";
alter publication supabase_realtime add table "public"."chat_polls";
alter publication supabase_realtime add table "public"."class_sessions";
alter publication supabase_realtime add table "public"."cohort_students";
alter publication supabase_realtime add table "public"."cohort_timetable_slots";
alter publication supabase_realtime add table "public"."cohorts";
alter publication supabase_realtime add table "public"."course_enrollments";
alter publication supabase_realtime add table "public"."crash_programs";
alter publication supabase_realtime add table "public"."direct_messages";
alter publication supabase_realtime add table "public"."discussion_replies";
alter publication supabase_realtime add table "public"."discussion_threads";
alter publication supabase_realtime add table "public"."email_outbox";
alter publication supabase_realtime add table "public"."entrance_test_results";
alter publication supabase_realtime add table "public"."fee_transactions";
alter publication supabase_realtime add table "public"."grade_appeals";
alter publication supabase_realtime add table "public"."group_messages";
alter publication supabase_realtime add table "public"."helpdesk_messages";
alter publication supabase_realtime add table "public"."helpdesk_tickets";
alter publication supabase_realtime add table "public"."learning_units";
alter publication supabase_realtime add table "public"."message_reactions";
alter publication supabase_realtime add table "public"."notifications";
alter publication supabase_realtime add table "public"."payment_channels";
alter publication supabase_realtime add table "public"."payment_submissions";
alter publication supabase_realtime add table "public"."policy_acceptances";
alter publication supabase_realtime add table "public"."profiles";
alter publication supabase_realtime add table "public"."program_applications";
alter publication supabase_realtime add table "public"."program_modules";
alter publication supabase_realtime add table "public"."programs";
alter publication supabase_realtime add table "public"."quiz_attempts";
alter publication supabase_realtime add table "public"."quizzes";
alter publication supabase_realtime add table "public"."role_permissions";
alter publication supabase_realtime add table "public"."school_policies";
alter publication supabase_realtime add table "public"."self_paced_activities";
alter publication supabase_realtime add table "public"."self_paced_lessons";
alter publication supabase_realtime add table "public"."self_paced_participations";
alter publication supabase_realtime add table "public"."self_paced_progress";
alter publication supabase_realtime add table "public"."self_paced_submissions";
alter publication supabase_realtime add table "public"."self_paced_weeks";
alter publication supabase_realtime add table "public"."staff_vacancies";
alter publication supabase_realtime add table "public"."study_plans";
alter publication supabase_realtime add table "public"."submissions";
alter publication supabase_realtime add table "public"."support_pledges";
alter publication supabase_realtime add table "public"."system_settings";
alter publication supabase_realtime add table "public"."teacher_course_plans";
alter publication supabase_realtime add table "public"."training_materials";
alter publication supabase_realtime add table "public"."transparency_reports";
alter publication supabase_realtime add table "public"."vacancy_applications";
alter publication supabase_realtime add table "public"."website_enquiries";
alter publication supabase_realtime add table "public"."yearbook_entries";

-- ---------------------------------------------------------------------------
-- Applied migration history
-- ---------------------------------------------------------------------------
-- 20260101000000  profiles
-- 20260102000000  live_backend_config
-- 20261014000000  profile_uploads_program_images
-- 20261014010000  roles_permissions_cms
-- 20261014020000  quizzes_assistant
-- 20261014030000  academic_planning_enrollment
-- 20261014040000  blog_email_payments
-- 20261014050000  backend_hardening
-- 20261014060000  payments_email_hardening
-- 20261014070000  payment_ledger_guard
-- 20261014080000  learning_path_attendance
-- 20261014090000  learning_path_attendance_fixes
-- 20261014100000  learning_progress_locking
-- 20261017000000  purge_non_admin_accounts
-- 20261017010000  portal_theme_settings
-- 20261018000000  school_policies
-- 20261018010000  confirm_gatnz_live
-- 20261018020000  aoh_2026_wiring
-- 20261018020100  storage_buckets
-- 20261018030000  storage_buckets
-- 20261020000000  support_study_plans
-- 20261021000000  catalogue_duration_fee_update
-- 20261022000000  seed_programmes_catalogue
-- 20261023000000  programs_title_alignment
-- 20261024000000  admission_officer_support
-- 20261024010000  cohort_discussions
-- 20261024020000  newsletter_templates
-- 20261024220137  align_certificate_status_values
-- 20261025000000  account_congratulations
-- 20261026000000  learning_memory
-- 20261028000000  push_reminders
-- 20261029000000  unique_identifiers
-- 20261029010000  certificate_controls
-- 20261029225617  crash_programs_applications
-- 20261029225714  inspect_push_tables
-- 20261029225719  inspect_push_tables_again
-- 20261029225739  notifications_user_id_fix
-- 20261029225747  verify_backend_deploy
-- 20261029225753  verify_backend_deploy_final
-- 20261029225758  verify_backend_columns_final
-- 20261029225805  final_function_inventory
-- 20261030000000  production_access_hardening
-- 20261031115129  crash_programs_applications
-- 20261031130419  learning_arrangements
-- 20261031131611  self_paced_attendance
-- 20261105000000  certificate_types_audit
-- 20261105110428  student_helpdesk
-- 20261105110514  transparency_reports_repair
-- 20261105110523  transparency_indexes_v2
-- 20261105110532  security_hardening_v2
-- 20261106000000  transparency_reports
-- 20261106003209  ensure_brand_asset_storage
-- 20261106010000  student_helpdesk
-- 20261107000000  assistant_research_resources
-- 20261107010000  module_responsibilities
-- 20261107042047  harden_function_search_paths
-- 20261107042152  restrict_security_definer_rpcs
-- 20261107054348  add_assignment_notification_preference
-- 20261110180757  onesignal_push_backend
-- 20261110180817  onesignal_push_backend
-- 20261110180825  onesignal_push_backend
-- 20261110180833  onesignal_push_backend
-- 20261110180842  onesignal_push_backend
-- 20261110180855  onesignal_push_backend
-- 20261110180904  onesignal_push_backend
-- 20261110180911  onesignal_push_backend
-- 20261110180918  verify_storage_realtime
-- 20261110181020  entrance_tests
-- 20261110181048  entrance_control_hardening
-- 20261110181057  verify_storage_realtime
-- 20261110181118  verify_edge_function_state
-- 20261110181123  verify_edge_function_state
-- 20261110181130  verify_edge_function_state
-- 20261110181135  verify_edge_function_state
-- 20261111022139  yearbook_wall
-- 20261111023738  production_storage_yearbook
-- 20261111024304  public_enquiries_backend
-- 20261111024323  public_enquiries_backend
-- 20261111025637  website_enquiries_backend
-- 20261111031251  website_enquiries_role_access
-- 20261111113337  opportunity_boards
-- 20261111114514  cleanup_opportunity_boards_duplicate
-- 20261114112826  program_blog_link
-- 20261114112852  backend_reconciliation_safe
-- 20261114115713  realtime_remaining_portal_tables
-- 20261117131125  direct_messages
-- 20261117131127  grade_evaluation_aptitude_control
-- 20261117131128  report_cards_timetable
-- 20261117131140  views_security_invoker
-- 20261118053234  20261118010000_programs_code_autofill
-- 20261118060901  welcome_emails_notification_integrity
-- 20261118065248  20261118090000_push_all_notifications
-- 20261118070557  push_instant_and_retries
-- 20261123022608  20261121000000_chat_groups_voice_attachments
-- 20261123022631  20261122120000_discussion_and_aptitude_write_paths
-- 20261123022642  20261123000000_cohort_avatar_and_school_policy_acceptance
-- 20261123022724  20261123010000_self_paced_learning_retry
-- 20261123022728  20261123020000_self_paced_gating
-- 20261123030440  20261124100000_chat_group_background
-- 20261123030518  20261124000000_self_paced_rls_media_publish
-- 20261123030622  20261124110000_notifications_insert_policy
-- 20261123031844  20261124120000_chat_rls_production
-- 20261123031904  20261124121000_chat_storage_policies
-- 20261123032919  20261124122000_polls_access_tighten
-- 20261123034926  20261124123000_chat_group_settings
-- 20261123071813  chat_use_all_roles
-- 20261123073143  seed_missing_permissions_all_roles
-- 20261124153859  messaging_rebuild
-- 20261124171803  knock_notification_audit
-- 20261124171815  fix_function_search_paths
-- 20261124173339  chat_upload_limit_and_welcome_unique
-- 20261127024609  fix_broken_upload_paths_20261127

-- ---------------------------------------------------------------------------
-- Objects captured: 6 extensions, 2 sequences, 105 tables, 467 constraints, 170 indexes, 105 rls_enabled, 116 functions, 56 triggers, 3 views, 239 policies, 300 grants, 249 function_grants, 12 buckets, 33 storage_policies, 58 realtime_tables, 112 migrations
