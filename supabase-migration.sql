-- ============================================
-- GestFin - Supabase Migration
-- Execute no SQL Editor do Supabase Dashboard
-- ============================================

-- Gerentes (criar primeiro por causa das FK)
CREATE TABLE IF NOT EXISTS gerentes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nome TEXT NOT NULL,
  telefone TEXT,
  email TEXT,
  obs TEXT,
  criado_em DATE DEFAULT CURRENT_DATE
);

-- Cobradores
CREATE TABLE IF NOT EXISTS cobradores (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nome TEXT NOT NULL,
  telefone TEXT,
  email TEXT,
  comissao NUMERIC DEFAULT 10,
  obs TEXT,
  criado_em DATE DEFAULT CURRENT_DATE
);

-- Clientes
CREATE TABLE IF NOT EXISTS clientes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nome TEXT NOT NULL,
  cpf TEXT,
  telefone TEXT,
  email TEXT,
  endereco TEXT,
  cobrador_id UUID REFERENCES cobradores(id) ON DELETE SET NULL,
  gerente_id UUID REFERENCES gerentes(id) ON DELETE SET NULL,
  obs TEXT,
  criado_em DATE DEFAULT CURRENT_DATE
);

-- Emprestimos (Contratos)
CREATE TABLE IF NOT EXISTS emprestimos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  pessoa_id UUID REFERENCES clientes(id) ON DELETE CASCADE,
  valor NUMERIC NOT NULL,
  taxa_juros NUMERIC NOT NULL,
  tipo_juros TEXT DEFAULT 'composto',
  sistema TEXT NOT NULL CHECK (sistema IN ('price', 'sac')),
  num_parcelas INTEGER NOT NULL,
  data_inicio DATE NOT NULL,
  dia_vencimento INTEGER NOT NULL CHECK (dia_vencimento BETWEEN 1 AND 28),
  status TEXT DEFAULT 'ativo' CHECK (status IN ('ativo', 'quitado', 'atrasado', 'renegociado')),
  obs TEXT,
  criado_em DATE DEFAULT CURRENT_DATE,
  renegociado_de UUID REFERENCES emprestimos(id) ON DELETE SET NULL
);

-- Parcelas
CREATE TABLE IF NOT EXISTS parcelas (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  emprestimo_id UUID REFERENCES emprestimos(id) ON DELETE CASCADE,
  numero INTEGER NOT NULL,
  valor_principal NUMERIC NOT NULL,
  valor_juros NUMERIC NOT NULL,
  valor_total NUMERIC NOT NULL,
  data_vencimento DATE NOT NULL,
  status TEXT DEFAULT 'pendente' CHECK (status IN ('pendente', 'paga')),
  data_pagamento DATE,
  valor_pago NUMERIC DEFAULT 0,
  juros_mora NUMERIC DEFAULT 0
);

-- Pagamentos
CREATE TABLE IF NOT EXISTS pagamentos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  parcela_id UUID REFERENCES parcelas(id) ON DELETE SET NULL,
  emprestimo_id UUID REFERENCES emprestimos(id) ON DELETE CASCADE,
  valor NUMERIC NOT NULL,
  data DATE NOT NULL,
  tipo TEXT DEFAULT 'total',
  obs TEXT
);

-- Cheques
CREATE TABLE IF NOT EXISTS cheques (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  cliente_id UUID REFERENCES clientes(id) ON DELETE CASCADE,
  contrato_id UUID REFERENCES emprestimos(id) ON DELETE SET NULL,
  numero TEXT NOT NULL,
  banco TEXT,
  agencia TEXT,
  valor NUMERIC NOT NULL,
  emissao DATE,
  bom_para DATE NOT NULL,
  status TEXT DEFAULT 'pendente' CHECK (status IN ('pendente', 'compensado', 'devolvido')),
  obs TEXT,
  criado_em DATE DEFAULT CURRENT_DATE
);

-- Despesas
CREATE TABLE IF NOT EXISTS despesas (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  descricao TEXT NOT NULL,
  categoria TEXT DEFAULT 'operacional',
  valor NUMERIC NOT NULL,
  data DATE NOT NULL,
  obs TEXT,
  criado_em DATE DEFAULT CURRENT_DATE
);

-- Config (key-value store)
CREATE TABLE IF NOT EXISTS config (
  chave TEXT PRIMARY KEY,
  valor TEXT
);

-- Inserir configs padrao
INSERT INTO config (chave, valor) VALUES
  ('jurosMoraPadrao', '0.033'),
  ('moeda', 'BRL'),
  ('apiKey', ''),
  ('modelo', 'claude-sonnet-4-6')
ON CONFLICT (chave) DO NOTHING;

-- ============================================
-- Desabilitar RLS para acesso publico (anon key)
-- Depois adicione auth se necessario
-- ============================================
ALTER TABLE gerentes ENABLE ROW LEVEL SECURITY;
ALTER TABLE cobradores ENABLE ROW LEVEL SECURITY;
ALTER TABLE clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE emprestimos ENABLE ROW LEVEL SECURITY;
ALTER TABLE parcelas ENABLE ROW LEVEL SECURITY;
ALTER TABLE pagamentos ENABLE ROW LEVEL SECURITY;
ALTER TABLE cheques ENABLE ROW LEVEL SECURITY;
ALTER TABLE despesas ENABLE ROW LEVEL SECURITY;
ALTER TABLE config ENABLE ROW LEVEL SECURITY;

-- Politicas de acesso publico (anon)
CREATE POLICY "allow_all" ON gerentes FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all" ON cobradores FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all" ON clientes FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all" ON emprestimos FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all" ON parcelas FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all" ON pagamentos FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all" ON cheques FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all" ON despesas FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all" ON config FOR ALL USING (true) WITH CHECK (true);
