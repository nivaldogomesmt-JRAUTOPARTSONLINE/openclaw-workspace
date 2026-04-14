# Relatório: cópia/backup do sistema na VPS (OpenClaw)

Contexto: VPS Hostinger (Ubuntu 24.04) rodando OpenClaw direto no host (systemd), após migração de um ambiente Docker gerenciado.

## 1) O que precisa ser copiado (itens críticos)

**Camada OpenClaw (obrigatório para restaurar o assistente):**
- Estado/config do OpenClaw (diretório de dados do usuário do serviço):
  - `/srv/openclaw/home/.openclaw/`
- Secrets do OpenClaw (variáveis de ambiente):
  - `/etc/openclaw/openclaw.env`

**Camada do serviço (para subir rápido igual estava):**
- Unit do systemd do gateway (se existir fora do pacote):
  - normalmente em `/etc/systemd/system/openclaw-gateway.service` (ou similar)
- Qualquer override:
  - `/etc/systemd/system/openclaw-gateway.service.d/*.conf`

**Infra (opcional, mas recomendado para recuperação total):**
- Configuração de firewall (UFW/nftables), se estiver aplicada
- Logs (úteis para diagnóstico, não críticos para restore)

## 2) Situação atual (conforme documentado nas notas)

- Gateway rodando como serviço systemd `openclaw-gateway.service` com user/group `openclaw`.
- Porta usada: `47638`.
- Dados do OpenClaw foram migrados para `/srv/openclaw/home/.openclaw/`.
- Secrets centralizados em `/etc/openclaw/openclaw.env` com permissões restritas.
- Container antigo do OpenClaw ficou parado para evitar conflito.

## 3) Melhor prática recomendada (2 camadas)

1) **Snapshot/backup do provedor (Hostinger)**
   - Serve para desastre total (disco, corrupção, erro humano, atualização ruim).
   - Recomendação: manter snapshots automáticos (diário) + retenção (7–30 dias, conforme custo).

2) **Backup “aplicação” (OpenClaw) para fora da VPS (offsite)**
   - Serve para restauração rápida do OpenClaw sem depender do snapshot.
   - Recomendação: `restic` (ou `borg`) com criptografia, enviando para S3/B2/Wasabi.
   - O backup deve incluir:
     - `/srv/openclaw/home/.openclaw/`
     - `/etc/openclaw/openclaw.env`
     - unit/overrides do systemd (se customizados)

## 4) Plano de restauração (runbook)

### Cenário A: restaurar VPS inteira (snapshot)
1) Restaurar snapshot no painel do provedor.
2) Validar serviço:
   - `systemctl status openclaw-gateway.service`
   - `journalctl -u openclaw-gateway.service -n 200 --no-pager`
3) Confirmar porta/health.

### Cenário B: restaurar só o OpenClaw (mais comum)
1) Reinstalar OpenClaw no host (se necessário).
2) Restaurar arquivos:
   - `/srv/openclaw/home/.openclaw/`
   - `/etc/openclaw/openclaw.env`
3) Ajustar permissões/ownership (se necessário) para o usuário do serviço.
4) Reiniciar:
   - `systemctl daemon-reload`
   - `systemctl restart openclaw-gateway.service`
5) Validar:
   - `openclaw gateway status` (se disponível no host)

## 5) Pontos que ainda precisam ser confirmados (para o relatório ficar “fechado”)

- Backups do provedor (Hostinger) estão **ativados**? Qual a **retenção** e a **última execução bem-sucedida**?
- Existe backup offsite (restic/borg) configurado hoje? Se sim:
  - destino (S3/B2/Wasabi), retenção, horário
  - teste de restore (quando foi o último)
- Onde está definida a unit do systemd exatamente (caminho do arquivo)?

## 6) Próximo passo recomendado

Eu posso fazer uma checagem **somente leitura** na VPS para confirmar (backups, paths, serviço) e, se você quiser, eu já deixo um job de backup offsite pronto (mas só executo mudanças quando você pedir).
