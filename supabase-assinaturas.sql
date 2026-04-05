-- ============================================
-- Tabela de Assinaturas
-- Execute no SQL Editor do Supabase Dashboard
-- ============================================

CREATE TABLE IF NOT EXISTS assinaturas (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  plano TEXT NOT NULL,
  mp_payment_id TEXT,
  mp_preference_id TEXT,
  status TEXT DEFAULT 'pending',
  valor NUMERIC,
  criado_em TIMESTAMPTZ DEFAULT NOW(),
  expira_em TIMESTAMPTZ
);

-- RLS: usuário vê apenas sua assinatura, service_role pode tudo
ALTER TABLE assinaturas ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuarios veem propria assinatura" ON assinaturas
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Service role full access" ON assinaturas
  FOR ALL USING (true) WITH CHECK (true);
