// Edge Function: webhook-mp
// Colar no Supabase Dashboard > Edge Functions > New Function
// Nome: webhook-mp
// IMPORTANTE: Desabilitar "Enforce JWT Verification" nas settings desta function

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const MP_ACCESS_TOKEN = Deno.env.get('MP_ACCESS_TOKEN')!
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

const PLANOS_MAX: Record<string, number> = {
  basico: 40,
  profissional: 100,
  empresarial: 99999,
}

serve(async (req) => {
  // CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'content-type',
      },
    })
  }

  try {
    const body = await req.json()
    console.log('Webhook received:', JSON.stringify(body))

    // Mercado Pago envia notificações com type e data.id
    if (body.type !== 'payment' && body.action !== 'payment.created' && body.action !== 'payment.updated') {
      return new Response('OK', { status: 200 })
    }

    const paymentId = body.data?.id
    if (!paymentId) {
      return new Response('No payment ID', { status: 200 })
    }

    // Buscar detalhes do pagamento no Mercado Pago
    const mpResponse = await fetch(`https://api.mercadopago.com/v1/payments/${paymentId}`, {
      headers: { 'Authorization': `Bearer ${MP_ACCESS_TOKEN}` },
    })
    const payment = await mpResponse.json()
    console.log('Payment status:', payment.status, 'external_reference:', payment.external_reference)

    if (payment.status !== 'approved') {
      return new Response('Payment not approved', { status: 200 })
    }

    // Extrair dados do external_reference
    let userId: string, plano: string
    try {
      const ref = JSON.parse(payment.external_reference)
      userId = ref.userId
      plano = ref.plano
    } catch {
      console.error('Invalid external_reference:', payment.external_reference)
      return new Response('Invalid reference', { status: 200 })
    }

    if (!userId || !plano || !PLANOS_MAX[plano]) {
      return new Response('Invalid data', { status: 200 })
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    // Atualizar perfil do usuário com novo plano
    const { error: profileError } = await supabase
      .from('perfis')
      .update({
        plano: plano,
        max_contratos: PLANOS_MAX[plano],
      })
      .eq('id', userId)

    if (profileError) {
      console.error('Profile update error:', profileError)
    }

    // Registrar/atualizar assinatura
    const expiraEm = new Date()
    expiraEm.setMonth(expiraEm.getMonth() + 1)

    await supabase.from('assinaturas').upsert({
      user_id: userId,
      plano: plano,
      mp_payment_id: String(paymentId),
      status: 'active',
      valor: payment.transaction_amount,
      expira_em: expiraEm.toISOString(),
    }, { onConflict: 'user_id' })

    console.log(`Plan updated: user=${userId} plano=${plano}`)
    return new Response('OK', { status: 200 })

  } catch (e) {
    console.error('Webhook error:', e)
    return new Response('Error', { status: 500 })
  }
})
