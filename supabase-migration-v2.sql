-- ============================================
-- GestFin v2 - Migration: Auth, Planos, Multi-user
-- Execute no SQL Editor do Supabase Dashboard
-- ============================================

-- 1. Tabela de Perfis (vinculada ao auth.users)
CREATE TABLE IF NOT EXISTS perfis (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nome TEXT,
  email TEXT,
  telefone TEXT,
  empresa TEXT,
  plano TEXT DEFAULT 'gratis' CHECK (plano IN ('gratis','basico','profissional','empresarial')),
  plano_status TEXT DEFAULT 'ativo' CHECK (plano_status IN ('ativo','cancelado','pendente')),
  max_contratos INTEGER DEFAULT 4,
  criado_em TIMESTAMPTZ DEFAULT NOW(),
  atualizado_em TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE perfis ENABLE ROW LEVEL SECURITY;
CREATE POLICY "users_own_profile" ON perfis
  FOR ALL USING (id = auth.uid()) WITH CHECK (id = auth.uid());

-- 2. Tabela de Assinaturas
CREATE TABLE IF NOT EXISTS assinaturas (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  plano TEXT NOT NULL,
  status TEXT DEFAULT 'pendente' CHECK (status IN ('ativo','cancelado','pendente','expirado')),
  mp_subscription_id TEXT,
  mp_payment_id TEXT,
  valor NUMERIC,
  inicio TIMESTAMPTZ DEFAULT NOW(),
  fim TIMESTAMPTZ,
  criado_em TIMESTAMPTZ DEFAULT NOW(),
  atualizado_em TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE assinaturas ENABLE ROW LEVEL SECURITY;
CREATE POLICY "user_own_subscriptions" ON assinaturas
  FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- 3. Adicionar user_id em todas as tabelas de dados
ALTER TABLE gerentes ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE cobradores ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE clientes ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE emprestimos ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE parcelas ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE pagamentos ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE cheques ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE despesas ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- 4. Remover politicas antigas e criar novas com isolamento por usuario
-- Gerentes
DROP POLICY IF EXISTS "allow_all" ON gerentes;
CREATE POLICY "user_isolation" ON gerentes FOR ALL
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Cobradores
DROP POLICY IF EXISTS "allow_all" ON cobradores;
CREATE POLICY "user_isolation" ON cobradores FOR ALL
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Clientes
DROP POLICY IF EXISTS "allow_all" ON clientes;
CREATE POLICY "user_isolation" ON clientes FOR ALL
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Emprestimos
DROP POLICY IF EXISTS "allow_all" ON emprestimos;
CREATE POLICY "user_isolation" ON emprestimos FOR ALL
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Parcelas
DROP POLICY IF EXISTS "allow_all" ON parcelas;
CREATE POLICY "user_isolation" ON parcelas FOR ALL
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Pagamentos
DROP POLICY IF EXISTS "allow_all" ON pagamentos;
CREATE POLICY "user_isolation" ON pagamentos FOR ALL
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Cheques
DROP POLICY IF EXISTS "allow_all" ON cheques;
CREATE POLICY "user_isolation" ON cheques FOR ALL
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Despesas
DROP POLICY IF EXISTS "allow_all" ON despesas;
CREATE POLICY "user_isolation" ON despesas FOR ALL
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Config permanece com acesso por user_id tambem
DROP POLICY IF EXISTS "allow_all" ON config;
ALTER TABLE config ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
-- Config precisa de politica especial: permite leitura publica para defaults
CREATE POLICY "user_config" ON config FOR ALL
  USING (user_id = auth.uid() OR user_id IS NULL) WITH CHECK (user_id = auth.uid());

-- 5. Trigger para criar perfil automaticamente ao cadastrar
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.perfis (id, nome, email, plano, max_contratos)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'nome', NEW.raw_user_meta_data->>'full_name', ''),
    NEW.email,
    'gratis',
    4
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 6. Indices para performance
CREATE INDEX IF NOT EXISTS idx_clientes_user_id ON clientes(user_id);
CREATE INDEX IF NOT EXISTS idx_emprestimos_user_id ON emprestimos(user_id);
CREATE INDEX IF NOT EXISTS idx_parcelas_user_id ON parcelas(user_id);
CREATE INDEX IF NOT EXISTS idx_pagamentos_user_id ON pagamentos(user_id);
CREATE INDEX IF NOT EXISTS idx_cheques_user_id ON cheques(user_id);
CREATE INDEX IF NOT EXISTS idx_despesas_user_id ON despesas(user_id);
CREATE INDEX IF NOT EXISTS idx_cobradores_user_id ON cobradores(user_id);
CREATE INDEX IF NOT EXISTS idx_assinaturas_user_id ON assinaturas(user_id);
