-- ══════════════════════════════════════════════════
-- DIRETRIZ AFINADA · Supabase Setup
-- Run this in: Supabase Dashboard → SQL Editor
-- ══════════════════════════════════════════════════

-- 1. CARS TABLE
CREATE TABLE IF NOT EXISTS public.cars (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  brand       text NOT NULL,
  model       text NOT NULL,
  year        text,
  km          text,
  price       text,
  category    text DEFAULT 'sedan',
  sub         text,
  cv          text,
  acc         text,
  fuel        text DEFAULT 'Gasolina',
  gear        text DEFAULT 'Automático',
  url         text,
  status      text DEFAULT 'active' CHECK (status IN ('active','reserved','sold')),
  img_url     text,
  created_at  timestamptz DEFAULT now(),
  updated_at  timestamptz DEFAULT now()
);

-- 2. ROW LEVEL SECURITY
ALTER TABLE public.cars ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read"   ON public.cars;
DROP POLICY IF EXISTS "Public insert" ON public.cars;
DROP POLICY IF EXISTS "Public update" ON public.cars;
DROP POLICY IF EXISTS "Public delete" ON public.cars;

CREATE POLICY "Public read"   ON public.cars FOR SELECT USING (true);
CREATE POLICY "Public insert" ON public.cars FOR INSERT WITH CHECK (true);
CREATE POLICY "Public update" ON public.cars FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "Public delete" ON public.cars FOR DELETE USING (true);

-- 3. AUTO UPDATE timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_updated_at ON public.cars;
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON public.cars
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 4. STORAGE BUCKET
INSERT INTO storage.buckets (id, name, public)
VALUES ('car-images', 'car-images', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Public read images"   ON storage.objects;
DROP POLICY IF EXISTS "Anyone upload images" ON storage.objects;
DROP POLICY IF EXISTS "Anyone update images" ON storage.objects;
DROP POLICY IF EXISTS "Anyone delete images" ON storage.objects;

CREATE POLICY "Public read images"   ON storage.objects FOR SELECT USING (bucket_id = 'car-images');
CREATE POLICY "Anyone upload images" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'car-images');
CREATE POLICY "Anyone update images" ON storage.objects FOR UPDATE USING (bucket_id = 'car-images');
CREATE POLICY "Anyone delete images" ON storage.objects FOR DELETE USING (bucket_id = 'car-images');

-- ══════════════════════════════════════════════════
-- Tabela criada e pronta.
-- Adicione veículos através do painel admin:
-- Aceda ao site → URL#admin → adminafinada / diretrizviana
-- ══════════════════════════════════════════════════
