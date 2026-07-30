# Ekklesia — Regras de Negócio
## Perfil Líder de Departamento · Sede & Local

> **Versão 1.0 · Julho 2026**
> Documento interno — uso restrito à equipe de produto

---

## Sumário

1. [Visão Geral](#1-visão-geral)
2. [Perfis e Hierarquia](#2-perfis-e-hierarquia)
3. [Nomeação e Registro](#3-nomeação-e-registro)
4. [Permissões por Módulo](#4-permissões-por-módulo)
5. [Módulo Membros do Departamento](#5-módulo-membros-do-departamento)
6. [Módulo Eventos](#6-módulo-eventos)
7. [Módulo Escalas](#7-módulo-escalas)
8. [Módulo Formulários](#8-módulo-formulários)
9. [Módulo Caixa do Departamento](#9-módulo-caixa-do-departamento)
10. [Módulo Aniversariantes](#10-módulo-aniversariantes)
11. [Notificações de Campo (Líder Sede)](#11-notificações-de-campo-líder-sede)
12. [Dashboard do Líder](#12-dashboard-do-líder)
13. [Regras de Segurança e Integridade](#13-regras-de-segurança-e-integridade)
14. [Modelagem Rails](#14-modelagem-rails)
15. [Funcionalidades Futuras](#15-funcionalidades-futuras)
16. [Glossário](#16-glossário)

---

## 1. Visão Geral

O **Líder de Departamento** é o responsável pela gestão pastoral e operacional de um departamento específico da igreja (ex: Mídia, Louvor, Juventude, Evangelismo). Ele atua como o elo entre o pastor e os membros do departamento.

**O Líder é responsável por:**
- Gerir os membros vinculados ao seu departamento
- Acompanhar a presença e evolução espiritual dos liderados
- Criar e gerenciar escalas do departamento
- Solicitar eventos (submetidos à aprovação do secretário)
- Gerenciar formulários de inscrição internos e externos
- Gerenciar o caixa do próprio departamento
- Receber alertas de aniversariantes dos liderados

**O Líder NÃO é responsável por:**
- Criar ou editar departamentos — responsabilidade do secretário/administrador
- Aprovar eventos — responsabilidade do secretário
- Gerenciar membros fora do próprio departamento
- Acessar financeiro geral da instituição
- Acessar configurações do sistema

---

## 2. Perfis e Hierarquia

O sistema distingue dois escopos do perfil líder com atuações diferentes:

| Característica | Líder Local | Líder Sede |
|---|---|---|
| Role no sistema | `leader` | `leader` (mesmo role) |
| Escopo de membros | Apenas próprio departamento na própria congregação | Idem — apenas própria congregação |
| Eventos locais | ✅ Cria como rascunho | ✅ Cria como rascunho |
| Eventos a nível campo | ❌ | ✅ Cria como rascunho (secretário sede aprova) |
| Notifica líderes das filhas | ❌ | ✅ Para eventos de campo aprovados |
| Acompanha líderes das filhas | ❌ | ✅ Visualiza lista de líderes do mesmo departamento no campo |
| Caixa do departamento | ✅ Próprio departamento | ✅ Próprio departamento |
| Visibilidade de membros das filhas | ❌ | ❌ |

> **Decisão de arquitetura:** o líder sede e o líder local compartilham o mesmo `role: leader` no sistema. A diferença de escopo é resolvida pela posição da `church` do usuário na hierarquia (`parent_church_id IS NULL` = sede). Não há role separado para os dois.

---

## 3. Nomeação e Registro

### 3.1 Fluxo de nomeação

```
Pastor decide nomear um membro como líder do departamento
        │
        ▼
Secretário registra a nomeação no sistema
(altera role do usuário para leader + vincula ao departamento)
        │
        ▼
Sistema notifica o membro nomeado
        │
        ▼
AuditLog registra: quem nomeou, quem registrou, data
```

### 3.2 Regras de nomeação

- Quem **decide** a nomeação: Administrador (Pastor)
- Quem **registra** no sistema: Secretário
- Um membro pode ser líder de **múltiplos departamentos** na mesma congregação (ex: líder da Mídia e líder do Louvor simultaneamente)
- Se o membro já for líder de outro departamento, o sistema exibe um **aviso informativo** antes de confirmar — não bloqueante
- O aviso garante que a nomeação seja intencional, evitando erros, mas não impede a ação
- A nomeação altera o `role` do usuário para `leader` e cria o vínculo em `memberchips` com `role: leader`
- Toda nomeação é registrada no `AuditLog`

### 3.3 Remoção do líder

- Executada pelo Secretário ou Administrador
- O membro perde o `role: leader` do departamento mas **continua como membro** da congregação
- O membro recebe notificação da alteração
- O departamento fica sem líder até nova nomeação — o sistema alerta o secretário e o pastor

---

## 4. Permissões por Módulo

| Módulo | Líder Local | Líder Sede |
|---|---|---|
| Dashboard do líder | ✅ Métricas do próprio departamento | ✅ + visão dos líderes do campo |
| Calendário | ✅ Visualizar | ✅ Visualizar |
| Eventos | ✅ Criar rascunho (local) | ✅ Criar rascunho (local + campo) |
| Departamentos | ✅ Visualizar apenas o próprio | ✅ Visualizar próprio + lista de líderes do campo |
| Membros | ✅ Apenas membros do próprio departamento | ✅ Idem |
| Escalas | ✅ CRUD do próprio departamento | ✅ CRUD do próprio departamento |
| Formulários | ✅ CRUD do próprio departamento | ✅ CRUD do próprio departamento |
| Caixa do departamento | ✅ CRUD do próprio departamento | ✅ CRUD do próprio departamento |
| Aniversariantes | ✅ Apenas membros do departamento | ✅ Apenas membros do departamento |
| Acolhimento | ✅ Visualizar lista do dia | ✅ Visualizar lista do dia |
| Notificações de campo | ❌ | ✅ Criar e configurar |
| Financeiro geral | ❌ | ❌ |
| Configurações | ❌ | ❌ |
| Membros de outras congregações | ❌ | ❌ |

---

## 5. Módulo Membros do Departamento

### 5.1 Visualização

- O líder visualiza **apenas membros do próprio departamento** na própria congregação
- Campos visíveis: nome, foto/avatar, telefone, WhatsApp, cargo, data de ingresso no departamento
- Campos **ocultos** para o líder: endereço completo, notas pastorais, data de nascimento completa (vê apenas dia e mês)
- Filtros disponíveis: busca por nome, status (ativo/inativo no departamento)

### 5.2 Fluxo de convite de membro

```
Líder busca membro cadastrado na congregação
        │
        ▼
Seleciona o membro e clica em "Convidar para o departamento"
        │
        ▼
Sistema cria solicitação com status: pendente_aprovacao
        │
        ▼
Pastor recebe notificação para aprovação
        │
   ┌────┴────┐
   ▼         ▼
Aprova     Recusa (com motivo)
   │         │
   ▼         ▼
Membro     Líder é notificado
recebe     e pode revisar
convite
   │
   ▼
Membro aceita ou recusa o convite
   │
   ▼
Se aceito: membro aparece na lista do departamento
```

### 5.3 Regras do convite

- O líder só pode convidar membros **cadastrados na própria congregação**
- Não pode convidar membros de outras congregações
- Um membro pode pertencer a **múltiplos departamentos** simultaneamente
- Se o membro já pertence ao departamento, o sistema bloqueia o convite duplicado
- A aprovação do convite é **exclusiva do Administrador (Pastor)** — o secretário não aprova convites de membros para departamentos
- Convites pendentes expiram em **30 dias** — o líder pode reenviar após expiração
- Toda ação de convite é registrada no `AuditLog`

### 5.4 Remoção de membro do departamento

- O líder pode remover um membro do departamento com **motivo obrigatório**
- A remoção **não inativa o membro** da congregação — ele continua como membro da igreja
- O membro é removido de todas as escalas futuras do departamento automaticamente
- O membro recebe notificação da remoção
- A ação é registrada no `AuditLog` com: membro, líder, motivo e data
- **Não pode ser desfeita pelo líder** — apenas o secretário ou administrador pode readicionar

### 5.5 O que o líder NÃO pode fazer com membros

- Criar ou editar o cadastro de um membro
- Inativar um membro da congregação
- Ver membros de outros departamentos
- Ver membros de outras congregações
- Aprovar o próprio convite (self-approval bloqueado)

---

## 6. Módulo Eventos

### 6.1 Líder Local — Eventos locais

O líder cria eventos que impactam apenas a própria congregação.

```
Líder cria evento (status: rascunho)
        │
        ▼
Secretário local recebe notificação
        │
   ┌────┴────┐
   ▼         ▼
Aprova     Recusa (com motivo)
   │         │
   ▼         ▼
Evento     Líder é notificado
publicado  e pode revisar
```

**Tipos de evento que o líder local pode propor:**
- Evangelismo
- Oração / Culto de oração
- Pequenos grupos
- Visitas pastorais
- Retiros
- Outros eventos internos do departamento

### 6.2 Líder Sede — Eventos de campo

O líder da sede pode propor eventos que envolvem **todas as congregações do campo** do mesmo departamento.

```
Líder sede cria evento de campo (status: rascunho)
        │
        ▼
Secretário sede recebe notificação
        │
   ┌────┴────┐
   ▼         ▼
Aprova     Recusa (com motivo)
   │         │
   ▼         ▼
Todos os   Líder sede
líderes    é notificado
do campo
recebem
notificação
```

### 6.3 Regras comuns de eventos

- O líder **nunca publica** um evento diretamente — sempre passa pelo secretário
- O líder pode editar o rascunho enquanto `status = rascunho` ou `status = recusado`
- O líder visualiza todos os eventos aprovados da própria congregação (somente leitura)
- O líder visualiza o calendário geral para verificar conflitos de data antes de criar o rascunho
- O líder **não pode excluir** um evento já aprovado — deve solicitar ao secretário

---

## 7. Módulo Escalas

### 7.1 Permissões

- CRUD completo de escalas do **próprio departamento**
- Não acessa escalas de outros departamentos
- Não compartilha escala com outras congregações — responsabilidade do secretário sede

### 7.2 Criação de escala

- O líder pode criar tipos de escala com colunas personalizadas (ex: Fotos, Stories, Datashow)
- Adiciona membros do próprio departamento às colunas de cada culto/evento
- Publica a escala (muda de `rascunho` para `publicado`)
- Membros escalados recebem notificação automática com lembretes configurados

### 7.3 Regra de conflito de membros

- Um membro pode pertencer a múltiplos departamentos
- Ao escalar um membro em uma data, o sistema verifica se já está escalado em outro departamento
- Se houver conflito: exibe ⚠ `"[Nome] já está escalado em [Departamento] neste dia"`
- O líder **pode confirmar** mesmo com conflito (não bloqueante)
- O conflito fica registrado e visível no card do evento

---

## 8. Módulo Formulários

### 8.1 Permissões

- Criar, editar, publicar e arquivar formulários do próprio departamento
- Visualizar e exportar respostas
- Acompanhar métricas: total de inscritos, taxa de preenchimento, respostas por período
- **Não pode excluir** formulário com respostas — apenas arquivar

### 8.2 Tipos de uso

- Inscrições para eventos internos do departamento (retiros, encontros)
- Formulários de acompanhamento espiritual dos liderados
- Inscrições para eventos externos que envolvam o departamento

### 8.3 Formulários padronizados pela sede

- O secretário sede pode distribuir formulários-padrão para todos os departamentos do mesmo tipo no campo
- O líder visualiza e aplica esses formulários mas **não pode editar o modelo**
- O líder pode criar formulários próprios independentemente dos padrões

---

## 9. Módulo Caixa do Departamento

### 9.1 O que é

Módulo financeiro simplificado e **separado** do financeiro geral da instituição. Cada departamento tem seu próprio caixa, gerenciado pelo líder.

### 9.2 O que o líder pode fazer

- Registrar entradas: verbas recebidas da tesouraria, arrecadações do departamento
- Registrar saídas: despesas do departamento com comprovante anexado
- Visualizar extrato e saldo atual
- Solicitar verba ao tesoureiro

### 9.3 Fluxo de solicitação de verba

```
Líder cria solicitação de verba
(valor + justificativa + data necessidade)
        │
        ▼
Tesoureiro recebe notificação
        │
   ┌────┴────┐
   ▼         ▼
Aprova     Recusa (com motivo)
   │         │
   ▼         ▼
Verba      Líder é
creditada  notificado
no caixa
```

### 9.4 Regras

- Lançamentos não podem ser excluídos — apenas estornados (lançamento inverso com referência ao original)
- Toda movimentação exige comprovante (recomendado — não bloqueante)
- O administrador e secretário podem visualizar o extrato do caixa do departamento
- O líder **não acessa** o financeiro geral da instituição

---

## 10. Módulo Aniversariantes

### 10.1 Visibilidade

- O líder visualiza **apenas aniversariantes do próprio departamento**
- Visualização em duas abas: **Esta semana** e **Este mês**
- Destaque especial para aniversariantes do dia (badge "🎂 Hoje!")
- Exibe: nome, data formatada ("Hoje, 15 de julho"), foto/avatar e ícone de WhatsApp se telefone preenchido

### 10.2 Alertas automáticos

| Alerta | Gatilho |
|---|---|
| Aniversariante amanhã | D-1 em relação à data de nascimento |
| Aniversariante hoje | No dia do aniversário ao fazer login |

- Notificação aparece no sino da navbar
- O líder pode contatar diretamente pelo WhatsApp via ícone no card

### 10.3 Visão geral (Dashboard)

- No dashboard do líder, aparece um card "Próximo aniversariante" com nome, foto e quantos dias faltam
- Se houver aniversariante no dia, o card é destacado com cor e badge

---

## 11. Notificações de Campo (Líder Sede)

> Esta seção é exclusiva do **Líder de Departamento da Sede**.

### 11.1 O que é

Quando o líder sede cria um evento de campo aprovado pelo secretário sede, todos os líderes do mesmo departamento nas congregações filhas recebem uma notificação de comparecimento.

### 11.2 Configuração da notificação

O líder sede pode configurar regras para cada notificação de evento de campo:

| Configuração | Opções |
|---|---|
| Confirmação de leitura | Ativo / Inativo |
| Confirmação de presença | Ativo / Inativo |
| Prazo para resposta | Data limite para confirmar presença |
| Reenvio automático | Reenviar se não lido em X dias |

### 11.3 Fluxo de notificação de campo

```
Evento de campo aprovado pelo secretário sede
        │
        ▼
Sistema envia notificação para todos os líderes
do mesmo departamento nas congregações filhas
        │
        ▼
Líder local recebe notificação no sino
        │
        ▼
[Se confirmação de leitura ativa]
Líder marca como lido → sistema registra timestamp
        │
        ▼
[Se confirmação de presença ativa]
Líder responde: "Confirmar presença" | "Não vou comparecer"
        │
        ▼
Líder sede vê painel de confirmações:
quais líderes confirmaram, quais não responderam,
quais recusaram — com prazo de resposta
```

### 11.4 Painel de confirmações (Líder Sede)

O líder sede visualiza um painel por evento de campo com:

| Coluna | Descrição |
|---|---|
| Congregação | Nome da filha |
| Líder | Nome do líder local do departamento |
| Lido em | Timestamp de leitura (ou "Não lido") |
| Presença | Confirmado / Recusado / Pendente |
| Respondido em | Timestamp da resposta |

### 11.5 Regras

- Apenas eventos de campo **aprovados** geram notificação para líderes locais
- O líder local **não pode** criar notificações de campo — apenas o líder sede
- A confirmação de presença é opcional por configuração do líder sede
- Líderes locais sem resposta até o prazo recebem lembrete automático

---

## 12. Dashboard do Líder

### 12.1 Cards de resumo

| Card | O que exibe |
|---|---|
| Membros do departamento | Total de membros ativos no departamento |
| Próximo aniversariante | Nome, foto e dias restantes |
| Eventos do mês | Eventos aprovados do departamento no mês atual |
| Escalas publicadas | Escalas com status publicado no mês |
| Pedidos de verba | Solicitações de caixa com status pendente |
| Formulários ativos | Formulários publicados com inscrições abertas |

### 12.2 Líder Sede — Cards adicionais

| Card | O que exibe |
|---|---|
| Líderes do campo | Total de líderes do mesmo departamento nas filhas |
| Confirmações pendentes | Líderes que não responderam notificações de campo |

---

## 13. Regras de Segurança e Integridade

### 13.1 O que o líder NUNCA pode fazer

- Criar, editar ou excluir departamentos
- Inativar membros da congregação
- Acessar membros fora do próprio departamento
- Acessar membros de outras congregações
- Publicar eventos sem aprovação do secretário
- Aprovar o próprio convite de membro (self-approval bloqueado)
- Acessar o financeiro geral da instituição
- Acessar configurações do sistema

### 13.2 Auditoria

Toda ação relevante do líder é registrada no `AuditLog`:

| Ação | Registrado |
|---|---|
| Convite de membro enviado | ✅ |
| Membro removido do departamento | ✅ com motivo |
| Escala criada / publicada | ✅ |
| Evento criado como rascunho | ✅ |
| Formulário criado / arquivado | ✅ |
| Solicitação de verba enviada | ✅ |
| Lançamento no caixa do departamento | ✅ |
| Notificação de campo enviada | ✅ |

### 13.3 Isolamento multi-tenant

- O líder enxerga apenas dados da **própria congregação** (`church_id` do usuário logado)
- `church_id` é preenchido automaticamente em todos os registros criados pelo líder — nunca exposto como campo editável
- A diferença entre líder sede e local é calculada em tempo de execução pela posição da church na hierarquia

---

## 14. Modelagem Rails

### 14.1 Vínculo líder ↔ departamento (`memberchips`)

O vínculo já existe na tabela `memberchips`. O líder tem `role: 1` (leader) no departamento.

```ruby
# app/models/memberchip.rb
class Memberchip < ApplicationRecord
  belongs_to :user
  belongs_to :departament

  enum :role, { member: 0, leader: 1 }

  scope :leaders,  -> { where(role: :leader) }
  scope :members,  -> { where(role: :member) }
end
```

### 14.2 Migration — Convites de membros ao departamento

```ruby
class CreateDepartmentInvites < ActiveRecord::Migration[8.0]
  def change
    create_table :department_invites do |t|
      t.references :departament,   null: false, foreign_key: true
      t.references :user,          null: false, foreign_key: true
      t.references :invited_by,    null: false,
                   foreign_key: { to_table: :users }
      t.bigint     :approved_by_id
      t.integer    :status,        null: false, default: 0
      t.string     :rejection_reason
      t.datetime   :expires_at,    null: false
      t.datetime   :responded_at
      t.timestamps
    end

    add_index :department_invites, [:user_id, :departament_id],
              name: "index_dept_invites_on_user_and_dept"
    add_index :department_invites, :status
    add_index :department_invites, :expires_at
    add_foreign_key :department_invites, :users, column: :approved_by_id

    # enum :status, {
    #   pending_approval: 0,  -- aguardando aprovação do pastor
    #   approved:         1,  -- aprovado pelo pastor, aguardando membro aceitar
    #   accepted:         2,  -- membro aceitou
    #   rejected:         3,  -- pastor recusou
    #   declined:         4,  -- membro recusou
    #   expired:          5   -- prazo de 30 dias expirou
    # }
  end
end
```

### 14.3 Migration — Notificações de campo

```ruby
class CreateFieldNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :field_notifications do |t|
      t.references :church,        null: false, foreign_key: true
      t.references :event,         null: false, foreign_key: true
      t.references :departament,   null: false, foreign_key: true
      t.references :sent_by,       null: false,
                   foreign_key: { to_table: :users }
      t.boolean    :requires_read_confirmation,     default: false, null: false
      t.boolean    :requires_presence_confirmation, default: false, null: false
      t.datetime   :response_deadline
      t.integer    :status,        null: false, default: 0
      t.timestamps
    end

    create_table :field_notification_responses do |t|
      t.references :field_notification, null: false, foreign_key: true
      t.references :user,               null: false, foreign_key: true
      t.references :church,             null: false, foreign_key: true
      t.datetime   :read_at
      t.integer    :presence,           default: 0
      t.datetime   :responded_at
      t.timestamps
    end

    add_index :field_notification_responses,
              [:field_notification_id, :user_id], unique: true,
              name: "index_field_notif_responses_uniqueness"

    # enum :presence, { pending: 0, confirmed: 1, declined: 2 }
    # enum :status,   { active: 0, closed: 1 }
  end
end
```

### 14.4 Scope multi-tenant e helpers

```ruby
# app/models/concerns/leader_scoped.rb
module LeaderScoped
  extend ActiveSupport::Concern

  included do
    # Retorna todos os departamentos liderados pelo usuário na church atual
    # Um líder pode ser responsável por múltiplos departamentos simultaneamente
    def led_departaments
      memberchips.leader.includes(:departament).map(&:departament)
    end

    # Atalho para verificar se lidera um departamento específico
    def leads?(departament)
      memberchips.leader.exists?(departament: departament)
    end

    # Verifica se usuário é líder de sede
    def leader_at_sede?
      church.parent_church_id.nil?
    end

    # IDs de churches do mesmo campo (sede + filhas)
    def field_church_ids
      return [church_id] unless leader_at_sede?
      Church.where(parent_church_id: church_id).pluck(:id) + [church_id]
    end
  end
end
```

---

## 15. Funcionalidades Futuras

As funcionalidades abaixo foram identificadas como necessidades do perfil Líder mas estão **fora do escopo da versão atual**. Devem ser especificadas e priorizadas em sprints futuras.

| Funcionalidade | Descrição |
|---|---|
| **Grupos internos** | Líder cria subgrupos dentro do departamento (ex: grupo de oração, grupo de visitação) com membros específicos |
| **Atividades e programas** | Criação de programas recorrentes com agenda, participantes e controle de frequência |
| **Equipes** | Subdivisão dos membros em equipes com responsáveis por equipe |
| **Gamificação** | Sistema de pontos e premiações por presença, participação em atividades e cumprimento de metas |
| **Controle de presença** | Registro de frequência por atividade — base para alertas de liderados ausentes e ranking de gamificação |
| **Acompanhamento espiritual** | Ficha individual do liderado com histórico de visitas, orações e anotações pastorais do líder |
| **Módulo de Presença** | Registro de frequência nos cultos gerais — dependência para o alerta de "membros ausentes" do pastor |

---

## 16. Glossário

| Termo | Definição |
|---|---|
| **Líder Local** | Líder de departamento de uma congregação filha — escopo restrito à própria congregação |
| **Líder Sede** | Líder de departamento da congregação sede — pode criar eventos e notificações de campo |
| **Campo** | Conjunto formado pela sede + todas as congregações filhas do mesmo tenant |
| **Convite** | Solicitação do líder para adicionar um membro ao departamento — requer aprovação exclusiva do Pastor (Administrador) |
| **Remoção do departamento** | Desvincula o membro do departamento — o membro continua na congregação |
| **Rascunho** | Status inicial de eventos criados pelo líder — aguarda aprovação do secretário |
| **Caixa do departamento** | Módulo financeiro simplificado do departamento — separado do financeiro geral da instituição |
| **Notificação de campo** | Comunicado enviado pelo líder sede para todos os líderes do mesmo departamento nas filhas |
| **Confirmação de leitura** | Recurso que registra quando o líder local abriu e leu a notificação de campo |
| **Confirmação de presença** | Resposta do líder local indicando se comparecerá ao evento de campo |
| **Self-approval** | Auto-aprovação bloqueada — o líder não pode aprovar convites que ele mesmo enviou |
| **AuditLog** | Tabela de rastreabilidade de todas as ações executadas no sistema |
| **memberchips** | Tabela de vínculo N:N entre usuários e departamentos com role (member ou leader). Um usuário pode ter múltiplos vínculos de líder em departamentos diferentes da mesma congregação |

---

*Ekklesia — Documento interno · Versão 1.0 · Julho 2026*