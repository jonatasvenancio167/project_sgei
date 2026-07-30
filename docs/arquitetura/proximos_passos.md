# Ekklesia — Próximos Passos de Desenvolvimento

> **Versão 1.0 · Julho 2026**
> Gerado a partir do cruzamento entre `docs/Ekklesia/perfis/*.md`, `docs/arquitetura/arquitetura.md`, `docs/arquitetura/modelagem.md` e o estado real do código (`app/`, `db/schema.rb`, `config/routes.rb`).
> Documento interno — uso restrito à equipe de engenharia

---

## 1. Metodologia

Este documento audita, perfil por perfil, o que os documentos de regras de negócio em `docs/Ekklesia/perfis/` descrevem versus o que existe hoje implementado no código. Cada item foi verificado diretamente no schema, nos models, nas policies e nas rotas — não apenas nos documentos de arquitetura, que em alguns pontos também descrevem estado futuro como se fosse atual.

Legenda de status:

| Status | Significado |
|---|---|
| ✅ Implementado | Existe no código, funcional |
| 🟡 Parcial | Existe parte da estrutura, mas fluxo/regra incompleto |
| ❌ Não implementado | Nada existe no código — só no documento |

---

## 2. Resumo Executivo

| Perfil / Módulo | Documento | Estado no código |
|---|---|---|
| Membro / Usuário (base) | `membros.md` | 🟡 Parcial — cadastro básico existe, campos eclesiásticos e ciclo de vida completo faltam |
| Administrador (Pastor) | `pastor.md` | 🟡 Parcial — é hoje o mesmo role `admin` genérico, sem regras específicas de pastor |
| Co-Pastor | `pastor.md` §12 | ❌ Não implementado — não existe em nenhum lugar do código |
| Secretário (Local/Sede) | `secretario.md` | ❌ Não implementado como perfil — coberto pelo role `admin` genérico, sem distinção sede/local |
| Tesoureiro / Financeiro | `tesoureiro.md` | ❌ Não implementado — nenhum model, tabela ou rota |
| Líder de Departamento | `lider_departamento.md` | 🟡 Parcial — vínculo líder↔departamento existe; convites, notificações de campo e caixa de departamento faltam |
| Recepção / Acolhimento | `recepcao.md` | 🟡 Parcial — `welcome_records` existe e funciona; não é um role próprio, e faltam pedidos de oração e vínculo com evento |
| Zelador / Almoxarifado | `zelador.md` | ❌ Não implementado — nenhum model, tabela ou rota |
| T.I. (staff interno) | `ti.md` | ❌ Não implementado — nenhum model, tabela ou rota |
| Multi-tenant / hierarquia sede-filha | `arquitetura.md` | ✅ Implementado — `Church#accessible_church_ids`, `BaseEntity`, `within_hierarchy?`/`same_church?` no Pundit |
| Compartilhamento de escala/evento (sede→filhas) | `arquitetura.md` §5 | ❌ Não implementado — nenhuma tabela de compartilhamento |

**Conclusão central:** o sistema hoje tem **apenas 3 roles reais** (`admin`, `leader`, `member` — `app/models/user.rb:21`). Todos os demais perfis descritos nos documentos (`co_pastor`, `secretary`/`secretario_sede`/`secretario_local`, `treasurer`, `reception`, `warehouse`, `ti`) existem **somente como documentação**, sem nenhum código correspondente. O módulo Financeiro e o módulo Almoxarifado não têm nenhuma linha de código — são construções inteiramente novas.

---

## 3. O que já está sólido (não precisa de retrabalho)

- **Isolamento multi-tenant por `church_id`**: `BaseEntity` concern aplicado nos models de domínio, `Church#accessible_church_ids` resolve a hierarquia sede→filhas, `ApplicationPolicy#same_church?`/`#within_hierarchy?` já existem e são usados nas policies (`app/policies/application_policy.rb`).
- **Módulo Membros (CRUD básico)**: `User` cobre cadastro, edição, inativação (`status: inactive`), busca — sem exclusão física.
- **Módulo Departamentos + vínculo líder↔membro**: `Departament`/`Memberchip` (nomes com typo, mas funcionais).
- **Módulo Eventos (CRUD básico)**: existe, mas sem fluxo de aprovação.
- **Módulo Escalas**: schema genérico (`schedules` → `schedule_columns`/`schedule_entries`/`schedule_assignments`) totalmente funcional, incluindo `ScheduleReminderJob` rodando via `config/recurring.yml` (lembretes D-7/D-3/D-1 reais, não só schema).
- **Módulo Formulários**: CRUD, builder, respostas públicas via slug — funcional.
- **Módulo Acolhimento**: `WelcomeRecord` funcional, com policy e rotas próprias (`painel/acolhimento`).
- **`RolePermission`**: matriz de permissão por módulo e role configurável sem deploy — já existe e é a peça central de autorização hoje (`RolePermission.allowed?`).
- **Notificações de escala**: pipeline real (job + `Notification`/`UserNotification`), não é só documentação.

---

## 4. Gaps por Perfil — Próximos Passos

### 4.1 Membros (`docs/Ekklesia/perfis/membros.md`)

O maior bloco de trabalho pendente, porque quase todos os outros perfis dependem da expansão do `role` de `User`.

| Item | Prioridade | Descrição |
|---|---|---|
| Expandir `enum :role` em `User` | 🔴 Alta | Hoje só `admin/leader/member`. Precisa crescer para suportar os perfis dedicados (ver seção 5.1) — é bloqueador de quase tudo abaixo |
| Campos eclesiásticos em `users` | 🔴 Alta | `gender`, `marital_status`, `baptized`, `baptism_date`, `joined_at`, `position`, `origin_church`, `presented`, `presented_at`, `pastoral_notes`, campos de inativação (`inactivation_reason`, `inactivated_by_id`, `inactivated_at`) — nenhum existe hoje |
| `church_memberships` (role por church) | 🟡 Média | Hoje um usuário tem um único role global; não suporta ser admin na sede e membro na filha ao mesmo tempo |
| `member_transfers` (transferência entre congregações) | 🟡 Média | Tabela e fluxo completo ainda não existem |
| `recommendation_letters` (carta de recomendação) | 🟡 Média | Tabela e fluxo (emissão, PDF, número de registro) não existem |
| `department_budgets` (caixa de departamento) | 🟢 Baixa | Depende do módulo financeiro existir primeiro (ver 4.3) |
| Renomear `departaments`→`departments`, `memberchips`→`memberships` | 🟢 Baixa | Débito técnico confirmado — planejar sprint dedicada, alto impacto em models/controllers/i18n |

### 4.2 Administrador / Pastor & Co-Pastor (`docs/Ekklesia/perfis/pastor.md`)

| Item | Prioridade | Descrição |
|---|---|---|
| Fluxo de aprovação de eventos (`status` em `Event`) | 🔴 Alta | `events` não tem `status`, `approved_by_id`, `rejection_reason` — o fluxo rascunho→aprovado/recusado descrito para Pastor, Secretário e Líder não existe. Bloqueia as regras de todos os 3 perfis |
| Role `co_pastor` + `CoPastorPolicy` | 🟡 Média | Zero código hoje. Requer expansão do enum de role + matriz de permissões customizável (toggles por módulo) — schema novo, não reaproveita `RolePermission` como está (que é por role fixo, não por usuário individual) |
| Agenda pessoal (`Compromisso`) | 🟢 Baixa | Não existe nenhum model — hoje `calendario` é só visualização de `Event`. É funcionalidade nova, não extensão |
| Dashboard com métricas de crescimento/batismo/conversão | 🟡 Média | Depende dos campos eclesiásticos (4.1) e do módulo de Acolhimento já ter `event_id` (4.6) para cruzar dados |
| Alerta de "membro ausente" | 🟢 Baixa | Documento já marca como dependente do módulo de Presença, que também não existe — é pré-requisito |

### 4.3 Secretário — Local & Sede (`docs/Ekklesia/perfis/secretario.md`)

| Item | Prioridade | Descrição |
|---|---|---|
| Distinção `secretario_local` / `secretario_sede` | 🔴 Alta | Hoje ambos são cobertos pelo mesmo `admin` genérico, sem diferenciação de escopo (própria congregação vs. campo todo) |
| Aprovação de eventos criados por líder/pastor | 🔴 Alta | Mesmo gap do item 4.2 — depende de `Event.status` existir |
| Credenciais oficiais (`credentials`) | 🟡 Média | Tabela não existe — emissão de credencial para pastor/presbítero/diácono/auxiliar/missionário com validade e alerta de vencimento |
| Comunicação institucional (circulares sede→filhas) | 🟢 Baixa | Nenhuma estrutura hoje — precisa de tabela própria + notificação em massa |
| Compartilhamento de escala/formulário sede→filhas | 🟡 Média | Ver seção 5.2 — nenhuma tabela de compartilhamento existe (`schedules`/`forms` são escopados só por `church_id` próprio) |

### 4.4 Tesoureiro / Financeiro (`docs/Ekklesia/perfis/tesoureiro.md`)

**Módulo inteiramente inexistente — nenhuma linha de código.** É o maior módulo novo do roadmap.

| Item | Prioridade | Descrição |
|---|---|---|
| Role `treasurer` | 🔴 Alta | Não existe no enum |
| Tabelas de lançamento financeiro (entradas/saídas, contas, comprovantes) | 🔴 Alta | Nada existe — precisa suportar dízimo nominal vs. anônimo, categorização, forma de pagamento |
| Dupla custódia (aprovação do pastor acima de valor configurável) | 🔴 Alta | Regra de negócio central do módulo — depende do módulo financeiro base existir primeiro |
| Estorno (nunca deletar lançamento) | 🔴 Alta | Mesmo padrão já usado em `Schedule`/`WelcomeRecord` (soft delete/inativação) — replicar o princípio |
| `TesoureiroPolicy` + acesso leitura a Membros/Eventos | 🟡 Média | Depende do role existir |
| Isolamento nominal (só tesoureiro+pastor veem dízimo nominal) | 🟡 Média | Regra de visibilidade de campo sensível — precisa de política de campo, não só de registro |

> Recomendação: tratar como **módulo greenfield** em uma spec própria antes de codificar — o documento `tesoureiro.md` já tem as regras de negócio, mas falta uma modelagem de dados no mesmo nível de detalhe que `modelagem.md` tem para os outros módulos.

### 4.5 Líder de Departamento (`docs/Ekklesia/perfis/lider_departamento.md`)

| Item | Prioridade | Descrição |
|---|---|---|
| Fluxo de convite de membro ao departamento (`department_invites`) | 🟡 Média | Hoje a vinculação a departamento é direta (via `Memberchip`); não existe fluxo de convite com aprovação do pastor e expiração em 30 dias |
| Notificações de campo (líder sede → líderes filhas) | 🟢 Baixa | Tabelas `field_notifications`/`field_notification_responses` não existem — depende de `Event` de campo existir primeiro |
| Caixa do departamento | 🟢 Baixa | Depende do módulo financeiro (4.4) e de `department_budgets` (4.1) |
| Dashboard do líder | 🟢 Baixa | Nenhuma tela dedicada hoje — hoje o líder usa as mesmas telas do admin filtradas por `RolePermission` |

### 4.6 Recepção / Acolhimento (`docs/Ekklesia/perfis/recepcao.md`)

Módulo mais próximo de estar completo entre os "novos" — schema já existe e funciona.

| Item | Prioridade | Descrição |
|---|---|---|
| Role dedicado `reception` | 🟡 Média | Hoje o acesso a `welcome_records` é dado via `RolePermission` module key `"welcome"` para qualquer role, não um role próprio — funciona, mas não segue exatamente o desenho do documento |
| `welcome_records.event_id` (vínculo com culto real) | 🔴 Alta | Hoje `service` é string livre — impede relatórios cruzados entre acolhimento e cultos, e o filtro "cultos do dia" descrito no documento não pode ser implementado como especificado |
| `PedidoOracao` (pedidos de oração) | 🟡 Média | Não existe — hoje só há o campo livre `notes` em `WelcomeRecord`, sem fluxo de encaminhamento/status |
| Janela de edição de 30 minutos | 🟢 Baixa | Regra de negócio simples de policy, não implementada ainda (`WelcomeRecordPolicy` atual não tem essa checagem) |

### 4.7 Zelador / Almoxarifado (`docs/Ekklesia/perfis/zelador.md`)

**Módulo inteiramente inexistente — nenhuma linha de código.**

| Item | Prioridade | Descrição |
|---|---|---|
| Role `warehouse` | 🟢 Baixa | Não existe |
| `stock_items` + `stock_movements` | 🟢 Baixa | Nenhuma tabela — módulo de estoque completo a construir |
| `purchase_requests` + fluxo de aprovação pelo tesoureiro | 🟢 Baixa | Depende do módulo financeiro (4.4) existir, já que quem aprova é o tesoureiro |

> Prioridade baixa porque depende do módulo Financeiro estar pronto primeiro (aprovação de compra passa pelo tesoureiro).

### 4.8 T.I. — Acesso interno de staff (`docs/Ekklesia/perfis/ti.md`)

**Não é um perfil de produto — é infraestrutura de suporte interno da equipe. Inexistente no código.**

| Item | Prioridade | Descrição |
|---|---|---|
| Role `ti` (nunca exposto via UI) | 🟢 Baixa | Não existe |
| Painel Global de Igrejas | 🟢 Baixa | Nenhuma tela hoje lista todas as churches de todos os tenants — hoje não há sequer um conceito de "tenant" separado de `church` sede no código, só a hierarquia `parent_church_id` |
| Campos extras em `AuditLog` (`performed_by_ti`, `simulated_role`, etc.) | 🟢 Baixa | `AuditLog` hoje só tem `church_id, user_id, module_key, action, detail` |
| Menu de simulação de perfis | 🟢 Baixa | Não existe |
| Rake task de provisionamento (`ti:create`) | 🟢 Baixa | Não existe |

> Recomendação: só priorizar quando o time de engenharia sentir a dor operacional de dar suporte via console/DB diretamente. Não tem urgência de produto.

---

## 5. Gaps Arquiteturais Transversais

Itens que não pertencem a um único perfil, mas afetam vários — a maioria já está mapeada em `docs/arquitetura/modelagem.md` §6, e está listada aqui só para consolidar prioridade.

### 5.1 Expansão do enum `role` em `User`

Já documentado em `modelagem.md` §6.9, mas vale destacar: **este é o item que desbloqueia mais trabalho no roadmap**. Ordem sugerida de expansão (valores sempre anexados ao final, nunca reordenados):

```ruby
enum :role, { admin: 0, leader: 1, member: 2, treasurer: 3, reception: 4, co_pastor: 5, warehouse: 6 }
```

Perfis fora deste ciclo confirmado, mas presentes nos documentos e ainda sem decisão: `secretary` (hoje coberto pelo próprio `admin`), `regente`, `ti`.

### 5.2 Compartilhamento de escala/evento (sede → filhas)

Descrito em `arquitetura.md` §5 e `modelagem.md` §6.10 — nenhuma tabela existe hoje. `SchedulePolicy`/`EventPolicy` escopam estritamente por `church_id` próprio. Esboço de solução (`schedule_shares`) já existe em `modelagem.md`.

### 5.3 Fluxo de aprovação de eventos

Sem `events.status`, três perfis (Pastor, Secretário, Líder) não conseguem operar conforme documentado — hoje qualquer evento criado já é "publicado" implicitamente. Este é provavelmente o item de maior impacto/menor esforço do roadmap: uma migration + enum + updates de policy desbloqueiam 3 documentos de uma vez.

### 5.4 `church_memberships` (role por contexto de church)

Necessário antes de qualquer perfil poder ter roles diferentes em sede vs. filha (ex: hoje João não pode ser admin na sede e membro na filha). Detalhado em `modelagem.md` §6.1.

### 5.5 Renomear tabelas com typo (`departaments`, `memberchips`)

Puramente técnico, sem impacto em regra de negócio — mas cresce em custo quanto mais o schema se expande em cima dessas tabelas. Melhor momento é antes de crescer mais o módulo de Departamentos/Líderes (4.5) e o Financeiro (que terá FK para `departaments` via `department_budgets`).

---

## 6. Priorização Sugerida (Fases)

**Fase 1 — Desbloqueios estruturais** (habilita o resto do roadmap)
1. Fluxo de aprovação de eventos (`events.status`) — seção 5.3
2. Expansão do enum `role` — seção 5.1
3. Campos eclesiásticos em `users` — seção 4.1
4. `welcome_records.event_id` — seção 4.6

**Fase 2 — Perfis administrativos completos**
5. Distinção Secretário Local/Sede + credenciais oficiais — seção 4.3
6. Co-Pastor com matriz de permissões customizável — seção 4.2
7. `church_memberships` — seção 5.4
8. Compartilhamento de escala sede→filhas — seção 5.2

**Fase 3 — Módulo Financeiro (greenfield)**
9. Modelagem completa do Financeiro/Tesoureiro — seção 4.4
10. Caixa de departamento — seção 4.1/4.5

**Fase 4 — Módulos novos de menor prioridade**
11. Zelador/Almoxarifado — seção 4.7 (depende da Fase 3)
12. Agenda pessoal do pastor — seção 4.2
13. Pedidos de oração no Acolhimento — seção 4.6
14. Notificações de campo (líder sede) — seção 4.5

**Fase 5 — Infraestrutura interna**
15. Acesso T.I. / staff — seção 4.8
16. Renomear tabelas com typo — seção 5.5 (pode ser antecipado se o custo de adiar crescer)

---

## 7. Referências

- `docs/Ekklesia/perfis/pastor.md`, `secretario.md`, `tesoureiro.md`, `membros.md`, `lider_departamento.md`, `recepcao.md`, `zelador.md`, `ti.md`
- `docs/arquitetura/arquitetura.md` — regras de multi-tenant e stack
- `docs/arquitetura/modelagem.md` — modelagem de dados e lacunas técnicas já mapeadas (schema-focused; não cobre Financeiro, Almoxarifado, Agenda, Co-Pastor, T.I. e Pedido de Oração, que são cobertos aqui)

---

*Ekklesia — Documento interno · Versão 1.0 · Julho 2026*
