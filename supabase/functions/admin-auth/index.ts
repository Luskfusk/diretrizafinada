// admin-auth: verifies admin credentials server-side and returns a signed session token.
// Secrets (set with `supabase secrets set`):
//   ADMIN_USERNAME        - admin login username
//   ADMIN_PASSWORD        - admin login password (store a NEW password, the old one was exposed publicly)
//   ADMIN_SESSION_SECRET  - random secret used to sign session tokens

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

function timingSafeEqual(a: string, b: string): boolean {
  const enc = new TextEncoder();
  const ba = enc.encode(a);
  const bb = enc.encode(b);
  if (ba.length !== bb.length) return false;
  let diff = 0;
  for (let i = 0; i < ba.length; i++) diff |= ba[i] ^ bb[i];
  return diff === 0;
}

async function hmacSha256(secret: string, message: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const sig = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(message));
  return btoa(String.fromCharCode(...new Uint8Array(sig)));
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return jsonResponse({ error: 'Method not allowed' }, 405);

  const expectedUser = Deno.env.get('ADMIN_USERNAME') ?? '';
  const expectedPass = Deno.env.get('ADMIN_PASSWORD') ?? '';
  const sessionSecret = Deno.env.get('ADMIN_SESSION_SECRET') ?? '';
  if (!expectedUser || !expectedPass || !sessionSecret) {
    return jsonResponse({ error: 'Admin auth is not configured' }, 500);
  }

  let body: { username?: string; password?: string } = {};
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: 'Invalid request' }, 400);
  }

  const ok =
    timingSafeEqual(String(body.username ?? ''), expectedUser) &&
    timingSafeEqual(String(body.password ?? ''), expectedPass);
  if (!ok) {
    return jsonResponse({ error: 'Invalid credentials' }, 401);
  }

  const expiry = Date.now() + 12 * 60 * 60 * 1000; // 12-hour session
  const signature = await hmacSha256(sessionSecret, String(expiry));
  return jsonResponse({ token: `${expiry}.${signature}` }, 200);
});
