-- ============================================
-- GestFin v3 - Função para migrar dados órfãos
-- Execute no SQL Editor do Supabase Dashboard
-- ============================================

-- Função RPC que migra dados sem user_id para o usuário especificado
-- Usa SECURITY DEFINER para bypassar RLS
CREATE OR REPLACE FUNCTION public.migrar_dados_orfaos(p_user_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE public.gerentes SET user_id = p_user_id WHERE user_id IS NULL;
  UPDATE public.cobradores SET user_id = p_user_id WHERE user_id IS NULL;
  UPDATE public.clientes SET user_id = p_user_id WHERE user_id IS NULL;
  UPDATE public.emprestimos SET user_id = p_user_id WHERE user_id IS NULL;
  UPDATE public.parcelas SET user_id = p_user_id WHERE user_id IS NULL;
  UPDATE public.pagamentos SET user_id = p_user_id WHERE user_id IS NULL;
  UPDATE public.cheques SET user_id = p_user_id WHERE user_id IS NULL;
  UPDATE public.despesas SET user_id = p_user_id WHERE user_id IS NULL;
  UPDATE public.config SET user_id = p_user_id WHERE user_id IS NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Permitir que usuários autenticados chamem a função
GRANT EXECUTE ON FUNCTION public.migrar_dados_orfaos(UUID) TO authenticated;
