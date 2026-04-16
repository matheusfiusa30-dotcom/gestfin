-- Migration: adiciona flags de dia útil em emprestimos
-- Permite configurar se parcelas podem cair em sábado, domingo ou feriado
-- Rodar no SQL Editor do Supabase

ALTER TABLE emprestimos
  ADD COLUMN IF NOT EXISTS considerar_sabado  BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS considerar_domingo BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS considerar_feriado BOOLEAN DEFAULT TRUE;
