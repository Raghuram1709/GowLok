-- Update handle_new_user function to extract full_name from raw_user_meta_data
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, full_name)
  values (
    new.id, 
    new.email,
    -- Extract full_name from raw_user_meta_data (where Supabase Auth data payload stores it)
    new.raw_user_meta_data->>'full_name'
  );
  return new;
end;
$$ language plpgsql security definer;
