# JR Auto Parts, Brief Operacional (rascunho)

## Onde e o que é
- Sede: Cuiabá, MT (Brasil)
- Modelo: operação híbrida de **autopeças + oficina + relacionamento/atendimento (WhatsApp) + portal do cliente**
- Objetivo V1: gerar caixa, reduzir perda operacional, acelerar atendimento e organizar fluxo interno

## Núcleo do sistema (entidades)
- Client, Vehicle, Product, Service
- ServiceOrder (OS), SoItem, SoStatusLog
- PreventiveMaintenance
- WhatsappMessage
- Extras: CompanyAsset, DigitalAccount

## Produtos (autopeças)
- Catálogo com: nome, descrição, categoria, preço, foto, unidade, estoque, ativo
- Bot consulta catálogo para responder com contexto (código, preço, estoque)

## Serviços (oficina)
- Exemplos seed: troca de óleo/filtro, alinhamento/balanceamento, revisão geral, correia dentada, diagnóstico eletrônico, pastilhas de freio, higienização A/C, amortecedores
- Campos: preço, tempo estimado

## Ordens de Serviço (OS)
- Centro da operação
- Regras planejadas: **km obrigatório** na abertura; histórico de mudanças (usuário + data/hora)
- Status (fluxo): QUOTE, APPROVED, STARTED, IN_PROGRESS, WAITING_PART, THIRD_PARTY, RETIFICA, FINISHING, DONE, DELIVERED

## Manutenção preventiva
- Vence por km ou por tempo (o que chegar primeiro)
- Estados: EM_DIA, ATENCAO_PROXIMA, VENCIDO, VENCIDO_CRITICO
- Campos: intervalos km/meses, última data/km, próxima data/km

## Atendimento (WhatsApp)
- Canal principal
- Bot com sessão por telefone, carrega contexto (cliente, veículos, últimas OS), identifica intenção, busca peças e pode escalar para humano via marcador **[HANDOFF]**

## Interfaces
- Gestão interna: dashboard, OS, clientes, veículos, produtos, serviços, manutenção, mensagens
- Portal do cliente: login, veículos, alertas de manutenção, histórico/status de OS

## Stack
- Frontend: React + Vite
- Backend: Node.js + Express
- ORM: Prisma
- DB: PostgreSQL (Supabase)
- Deploy: Render (backend), Vercel (frontend)
- Imagens: Cloudinary
- Email: Resend
- WhatsApp: BotConversa

## Segurança
- JWT, bcrypt, rate limit (global + login + bot)
- lockout após tentativas inválidas
- senha forte, troca obrigatória no primeiro uso

## Escopo V1 (sim) vs fora (não)
- V1: OS (km + histórico + notificação WhatsApp), preventiva, portal, usuários/perfis, cadastros base, financeiro básico ligado à OS
- Fora: guincho com mapa, locação completa, e-commerce completo (3.000 itens), integração completa com Olist ERP
