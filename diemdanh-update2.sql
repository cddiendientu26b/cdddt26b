-- CẬP NHẬT 2: (1) chỉ tài khoản QUẢN TRỊ được duyệt mới ghi/đọc dữ liệu quản lý (2) lưu lịch sử mã đăng ký.
-- Chạy 1 lần trong Supabase > SQL Editor. Kết quả cuối cùng sẽ hiện email của admin.

-- 1. Danh sách admin (tự thêm tài khoản được tạo đầu tiên trong Authentication > Users)
create table if not exists admins (user_id uuid primary key references auth.users(id) on delete cascade);
alter table admins enable row level security;
insert into admins (user_id) select id from auth.users order by created_at asc limit 1 on conflict do nothing;
create or replace function is_admin() returns boolean language sql stable security definer set search_path = public as
$$ select exists (select 1 from admins where user_id = auth.uid()) $$;
revoke execute on function is_admin() from public, anon;
grant execute on function is_admin() to authenticated;

-- 2. Siết quyền: không còn "ai đăng nhập cũng là admin"
drop policy if exists "cc_update" on class_config;
create policy "cc_update" on class_config for update to authenticated using (is_admin()) with check (is_admin());
drop policy if exists "st_all" on students;
create policy "st_all" on students for all to authenticated using (is_admin()) with check (is_admin());
drop policy if exists "at_read" on attendance; drop policy if exists "at_insert" on attendance; drop policy if exists "at_delete" on attendance;
create policy "at_read" on attendance for select to authenticated using (is_admin());
create policy "at_insert" on attendance for insert to authenticated with check (is_admin());
create policy "at_delete" on attendance for delete to authenticated using (is_admin());
-- web lớp + quỹ + ảnh
drop policy if exists "Admin được sửa" on settings;
create policy "Admin được sửa" on settings for update to authenticated using (is_admin()) with check (is_admin());
drop policy if exists "Admin thêm quỹ" on fund_entries; drop policy if exists "Admin sửa quỹ" on fund_entries; drop policy if exists "Admin xóa quỹ" on fund_entries;
create policy "Admin thêm quỹ" on fund_entries for insert to authenticated with check (is_admin());
create policy "Admin sửa quỹ" on fund_entries for update to authenticated using (is_admin()) with check (is_admin());
create policy "Admin xóa quỹ" on fund_entries for delete to authenticated using (is_admin());
drop policy if exists "Admin tải ảnh" on storage.objects; drop policy if exists "Admin xóa ảnh" on storage.objects;
create policy "Admin tải ảnh" on storage.objects for insert to authenticated with check (bucket_id = 'timetable' and is_admin());
create policy "Admin xóa ảnh" on storage.objects for delete to authenticated using (bucket_id = 'timetable' and is_admin());

-- 3. Lịch sử mã đăng ký
create table if not exists activation_codes (
  id bigint generated always as identity primary key,
  mssv text not null references students(mssv) on delete cascade,
  code text not null,
  created_at timestamptz not null default now(),
  status text not null default 'active' check (status in ('active', 'used', 'cancelled')),
  status_at timestamptz
);
alter table activation_codes enable row level security;
drop policy if exists "ac_all" on activation_codes;
create policy "ac_all" on activation_codes for all to authenticated using (is_admin()) with check (is_admin());

create or replace function session_code() returns jsonb language plpgsql security definer set search_path = public as $$
declare w bigint := floor(extract(epoch from now()) / 60)::bigint;
begin
  if not is_admin() then raise exception 'Không có quyền'; end if;
  return jsonb_build_object('code', _code_at(w), 'seconds_left', 60 - (extract(epoch from now())::bigint % 60));
end $$;

drop function if exists issue_codes(text);
create or replace function issue_codes(p_mssv text default null, p_all boolean default false)
returns table (out_mssv text, out_name text, out_code text) language plpgsql security definer set search_path = public as $$
declare r record; c text;
begin
  if not is_admin() then raise exception 'Không có quyền'; end if;
  for r in select st.mssv, st.full_name from students st
           where (p_mssv is not null and st.mssv = p_mssv)
              or (p_mssv is null and p_all and st.device_hash is null)
              or (p_mssv is null and not p_all and st.code_hash is null and st.device_hash is null)
           order by st.mssv loop
    c := upper(substr(md5(random()::text || clock_timestamp()::text || r.mssv), 1, 6));
    update activation_codes set status = 'cancelled', status_at = now() where mssv = r.mssv and status = 'active';
    update students set code_hash = _sha(c), fail_count = 0,
      device_hash = case when p_mssv is not null then null else device_hash end,
      activated_at = case when p_mssv is not null then null else activated_at end
    where students.mssv = r.mssv;
    insert into activation_codes (mssv, code) values (r.mssv, c);
    out_mssv := r.mssv; out_name := r.full_name; out_code := c; return next;
  end loop;
end $$;

create or replace function cancel_codes() returns int language plpgsql security definer set search_path = public as $$
declare n int;
begin
  if not is_admin() then raise exception 'Không có quyền'; end if;
  update students set code_hash = null where device_hash is null and code_hash is not null;
  update activation_codes set status = 'cancelled', status_at = now() where status = 'active';
  get diagnostics n = row_count;
  return n;
end $$;

create or replace function cancel_code(p_id bigint) returns void language plpgsql security definer set search_path = public as $$
begin
  if not is_admin() then raise exception 'Không có quyền'; end if;
  update students set code_hash = null
  where device_hash is null and mssv = (select mssv from activation_codes where id = p_id and status = 'active');
  update activation_codes set status = 'cancelled', status_at = now() where id = p_id and status = 'active';
end $$;

create or replace function clear_code_history() returns int language plpgsql security definer set search_path = public as $$
declare n int;
begin
  if not is_admin() then raise exception 'Không có quyền'; end if;
  perform cancel_codes();
  delete from activation_codes;
  get diagnostics n = row_count;
  return n;
end $$;

-- Khi SV đăng ký thành công thì đánh dấu mã "đã dùng"
create or replace function activate_student(p_mssv text, p_code text, p_device text) returns jsonb
language plpgsql security definer set search_path = public as $$
declare s students%rowtype; dh text;
begin
  if length(coalesce(p_device, '')) < 16 then return jsonb_build_object('ok', false, 'error', 'Thiết bị không hợp lệ.'); end if;
  dh := _sha(p_device);
  select * into s from students where mssv = trim(coalesce(p_mssv, '')) for update;
  if not found then return jsonb_build_object('ok', false, 'error', 'Không tìm thấy MSSV này trong danh sách.'); end if;
  if s.device_hash = dh then return jsonb_build_object('ok', true); end if;
  if s.fail_count >= 5 then return jsonb_build_object('ok', false, 'error', 'Mã bị khóa do nhập sai nhiều lần. Hãy nhờ admin cấp lại.'); end if;
  if s.code_hash is null then return jsonb_build_object('ok', false, 'error', 'MSSV này chưa được cấp mã hoặc mã đã bị hủy. Hãy nhờ admin.'); end if;
  if s.device_hash is not null then return jsonb_build_object('ok', false, 'error', 'MSSV này đã đăng ký trên một thiết bị khác. Nếu đổi máy, hãy nhờ admin cấp lại mã.'); end if;
  if exists (select 1 from students where device_hash = dh) then return jsonb_build_object('ok', false, 'error', 'Thiết bị này đã đăng ký cho một sinh viên khác.'); end if;
  if s.code_hash <> _sha(upper(trim(coalesce(p_code, '')))) then
    update students set fail_count = fail_count + 1 where mssv = s.mssv;
    return jsonb_build_object('ok', false, 'error', 'Mã không đúng. Còn ' || greatest(4 - s.fail_count, 0) || ' lần thử.');
  end if;
  update students set device_hash = dh, activated_at = now(), fail_count = 0 where mssv = s.mssv;
  update activation_codes set status = 'used', status_at = now() where mssv = s.mssv and status = 'active';
  return jsonb_build_object('ok', true);
end $$;

revoke execute on function session_code(), issue_codes(text, boolean), cancel_codes(), cancel_code(bigint), clear_code_history() from public, anon;
grant execute on function session_code(), issue_codes(text, boolean), cancel_codes(), cancel_code(bigint), clear_code_history() to authenticated;
revoke execute on function activate_student(text, text, text) from public;
grant execute on function activate_student(text, text, text) to anon, authenticated;

select u.email as email_admin from admins a join auth.users u on u.id = a.user_id;
