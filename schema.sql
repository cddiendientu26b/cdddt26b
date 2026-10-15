-- Chạy toàn bộ file này trong Supabase > SQL Editor (README, Bước 3)
create table if not exists settings (
  id int primary key default 1 check (id = 1),
  class_name text not null default 'Lớp (dữ liệu minh họa)',
  start_date date not null default current_date,
  rule text not null default 'weekdays' check (rule in ('weekdays','all')),
  students jsonb not null default '[]',
  pairs jsonb not null default '[]',
  room jsonb not null default '{"name":"","floor":"","wing":"","note":""}',
  timetable_url text,
  updated_at timestamptz not null default now()
);
insert into settings (id, class_name, students, pairs, room) values (
  1, 'Lớp 10A1 (dữ liệu minh họa)',
  '["Bạn A (minh họa)","Bạn B (minh họa)","Bạn C (minh họa)","Bạn D (minh họa)"]',
  '[["Bạn A (minh họa)","Bạn B (minh họa)"],["Bạn C (minh họa)","Bạn D (minh họa)"]]',
  '{"name":"Phòng 101 (minh họa)","floor":"Tầng 1","wing":"Dãy A","note":"Dữ liệu minh họa, hãy sửa trong trang quản trị"}'
) on conflict (id) do nothing;

alter table settings enable row level security;
drop policy if exists "Ai cũng xem được" on settings;
drop policy if exists "Admin được sửa" on settings;
create policy "Ai cũng xem được" on settings for select using (true);
create policy "Admin được sửa" on settings for update to authenticated using (true) with check (true);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('timetable','timetable',true,5242880,array['image/jpeg','image/png','image/webp'])
on conflict (id) do nothing;
drop policy if exists "Ai cũng xem ảnh" on storage.objects;
drop policy if exists "Admin tải ảnh" on storage.objects;
drop policy if exists "Admin xóa ảnh" on storage.objects;
create policy "Ai cũng xem ảnh" on storage.objects for select using (bucket_id = 'timetable');
create policy "Admin tải ảnh" on storage.objects for insert to authenticated with check (bucket_id = 'timetable');
create policy "Admin xóa ảnh" on storage.objects for delete to authenticated using (bucket_id = 'timetable');
