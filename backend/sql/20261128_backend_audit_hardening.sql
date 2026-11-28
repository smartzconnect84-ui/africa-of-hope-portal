-- Backend audit hardening — 2026-11-28
--
-- Applied to production project gatnzfjpuokopqyksqoy. Kept in the repo so the
-- changes are reviewable and reproducible; the rest of the schema still needs a
-- `supabase db pull` to be captured under version control.

-- ---------------------------------------------------------------------------
-- 1. Certificate register is not public reading material.
--    The blanket policy OR-ed with certificates_private_register and let every
--    signed-in account read all grades, honours and revocation reasons.
-- ---------------------------------------------------------------------------
drop policy if exists certificates_read on public.certificates;

-- ---------------------------------------------------------------------------
-- 2. portal_kv: keep shared reads, but students must not see finance/plan keys.
-- ---------------------------------------------------------------------------
drop policy if exists portal_kv_read on public.portal_kv;
create policy portal_kv_read on public.portal_kv
  for select to authenticated
  using (
    not (
      (key like 'finance-%' or key like 'cohort-plan:%')
      and exists (
        select 1 from public.profiles p
        where p.id = auth.uid() and p.role = 'Student'
      )
    )
  );

-- ---------------------------------------------------------------------------
-- 3. Staff notifications: self, administrators anyone, teachers students only.
--    Previously any Teacher could insert a notification for any profile.
-- ---------------------------------------------------------------------------
drop policy if exists notifications_insert_staff on public.notifications;
create policy notifications_insert_staff on public.notifications
  for insert to authenticated
  with check (
    public.is_staff()
    and (
      recipient_id = auth.uid()
      or public.has_permission('announcements.manage')
      or exists (
        select 1 from public.profiles p
        where p.id = notifications.recipient_id and p.role = 'Student'
      )
      or exists (
        select 1
        from public.cohort_students cs
        join public.cohorts c on c.id = cs.cohort_id
        where cs.student_id = notifications.recipient_id
          and coalesce(cs.active, true)
          and (c.teacher_id = auth.uid() or public.is_cohort_teacher(c.id))
      )
    )
  );

-- ---------------------------------------------------------------------------
-- 4. Settings rows may only be created by someone who can manage settings.
-- ---------------------------------------------------------------------------
drop policy if exists system_settings_insert on public.system_settings;
create policy system_settings_insert on public.system_settings
  for insert to authenticated
  with check (public.has_permission('settings.manage'));

-- ---------------------------------------------------------------------------
-- 5. Storage: destructive admin policies now require an actual permission
--    (is_portal_admin() was only people.view), and the misleading {public}
--    role labels on site-videos are corrected.
-- ---------------------------------------------------------------------------
drop policy if exists documents_admin_all on storage.objects;
create policy documents_admin_all on storage.objects
  for all to authenticated
  using (bucket_id = 'documents' and (public.has_permission('students.manage') or public.has_permission('staff.manage')))
  with check (bucket_id = 'documents' and (public.has_permission('students.manage') or public.has_permission('staff.manage')));

drop policy if exists site_videos_admin_all on storage.objects;
create policy site_videos_admin_all on storage.objects
  for all to authenticated
  using (bucket_id = 'site-videos' and public.has_permission('cms.manage'))
  with check (bucket_id = 'site-videos' and public.has_permission('cms.manage'));

drop policy if exists site_videos_manage_all on storage.objects;
create policy site_videos_manage_all on storage.objects
  for all to authenticated
  using (bucket_id = 'site-videos' and public.has_permission('cms.manage'))
  with check (bucket_id = 'site-videos' and public.has_permission('cms.manage'));

-- Chat attachments may no longer hold HTML/SVG, at the bucket layer as well as
-- in the Worker.
update storage.buckets
set allowed_mime_types = array[
  'application/pdf', 'text/plain', 'application/zip', 'application/x-zip-compressed',
  'image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/heic',
  'video/mp4', 'video/webm', 'video/quicktime',
  'audio/mpeg', 'audio/wav', 'audio/ogg', 'audio/mp4', 'audio/x-m4a',
  'application/msword', 'application/vnd.ms-powerpoint', 'application/vnd.ms-excel',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
]
where id = 'chat-attachments';

-- ---------------------------------------------------------------------------
-- 6. Unauthenticated callers cannot execute staff/quiz/helpdesk write RPCs.
--    (PUBLIC is revoked so anon loses the inherited grant; authenticated is
--    re-granted explicitly.)
-- ---------------------------------------------------------------------------
revoke execute on function public.adjust_quiz_answer_points(uuid, uuid, numeric) from public, anon;
revoke execute on function public.regrade_quiz(uuid) from public, anon;
revoke execute on function public.update_helpdesk_ticket_status(uuid, text) from public, anon;
revoke execute on function public.submit_course_enrollment_with_arrangement(uuid, text) from public, anon;
revoke execute on function public.register_push_subscription(text, text, text, text) from public, anon;
revoke execute on function public.assistant_admin_stats() from public, anon;

grant execute on function public.adjust_quiz_answer_points(uuid, uuid, numeric) to authenticated;
grant execute on function public.regrade_quiz(uuid) to authenticated;
grant execute on function public.update_helpdesk_ticket_status(uuid, text) to authenticated;
grant execute on function public.submit_course_enrollment_with_arrangement(uuid, text) to authenticated;
grant execute on function public.register_push_subscription(text, text, text, text) to authenticated;
grant execute on function public.assistant_admin_stats() to authenticated;

-- ---------------------------------------------------------------------------
-- 7. anon never needs write access, except the deliberately public forms.
-- ---------------------------------------------------------------------------
do $$
declare
  r record;
begin
  for r in
    select c.relname
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relkind = 'r'
      and c.relname not in (
        'alumni_businesses',
        'study_plans',
        'support_pledges',
        'vacancy_applications',
        'website_enquiries'
      )
  loop
    execute format('revoke insert, update, delete on public.%I from anon', r.relname);
  end loop;
end $$;
