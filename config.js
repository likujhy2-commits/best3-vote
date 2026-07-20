// Supabase 접속 정보 (타자게임 프로젝트 재사용)
const SUPABASE_URL = 'https://sqreqoewqfusppayoiqw.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNxcmVxb2V3cWZ1c3BwYXlvaXF3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM1NzUxMjgsImV4cCI6MjA5OTE1MTEyOH0.7C7qq_vtr_BBAEcHGHN2dMT_O9BBQtuMAtD8Ew_eydo';

const SB_HEADERS = {
  apikey: SUPABASE_ANON_KEY,
  Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
  'Content-Type': 'application/json',
};

async function sbGet(path) {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${path}`, { headers: SB_HEADERS });
  if (!res.ok) throw Object.assign(new Error('request failed'), { status: res.status, body: await res.text() });
  return res.json();
}

async function sbPost(path, body) {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
    method: 'POST',
    headers: SB_HEADERS,
    body: JSON.stringify(body),
  });
  const text = await res.text();
  if (!res.ok) throw Object.assign(new Error('request failed'), { status: res.status, body: text });
  return text ? JSON.parse(text) : null;
}
