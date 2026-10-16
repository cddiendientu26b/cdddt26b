-- Chạy trong Supabase > SQL Editor (một lần). Ảnh minh chứng dùng lại kho ảnh "timetable" đã tạo.
create table if not exists fund_entries (
  id bigint generated always as identity primary key,
  entry_date date not null default current_date,
  kind text not null check (kind in ('thu','chi')),
  amount bigint not null check (amount > 0),
  description text not null check (char_length(description) between 1 and 200),
  proof_url text,
  created_at timestamptz not null default now()
);
alter table fund_entries enable row level security;
drop policy if exists "Ai cũng xem quỹ" on fund_entries;
drop policy if exists "Admin thêm quỹ" on fund_entries;
drop policy if exists "Admin sửa quỹ" on fund_entries;
drop policy if exists "Admin xóa quỹ" on fund_entries;
create policy "Ai cũng xem quỹ" on fund_entries for select using (true);
create policy "Admin thêm quỹ" on fund_entries for insert to authenticated with check (true);
create policy "Admin sửa quỹ" on fund_entries for update to authenticated using (true) with check (true);
create policy "Admin xóa quỹ" on fund_entries for delete to authenticated using (true);
