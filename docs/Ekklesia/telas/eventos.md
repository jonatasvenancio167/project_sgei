# Ekklesia — Regras de Negócio
## Módulo Eventos

> **Versão 1.0 · Julho 2026**
> Documento interno — uso restrito à equipe de produto

---

## Sumário

1. [Visão Geral](#1-visão-geral)
2. [Estados de um Evento](#2-estados-de-um-evento)
3. [Permissões por Perfil](#3-permissões-por-perfil)
4. [Página de Listagem](#4-página-de-listagem-panelevents)
5. [Formulário de Evento](#5-formulário-de-evento)
6. [Fluxo de Aprovação](#6-fluxo-de-aprovação)
7. [Ação de Compartilhar](#7-ação-de-compartilhar)
8. [Integração com Calendário](#8-integração-com-calendário)
9. [Regras de Integridade](#9-regras-de-integridade)
10. [Modelagem Rails](#10-modelagem-rails)
11. [Glossário](#11-glossário)

---

## 1. Visão Geral

O módulo de **Eventos** centraliza a criação, aprovação e divulgação de cultos, reuniões e demais atividades da congregação. Todo evento passa por um fluxo de aprovação antes de ser publicado no calendário da igreja, garantindo que o secretário tenha controle sobre a programação e evitando conflitos de datas.

**Rota principal:** `panel/events`

**Responsabilidades do módulo:**
- Registrar e gerenciar eventos da própria congregação
- Controlar o fluxo de aprovação entre líderes/pastor e secretário
- Gerenciar inscrições de membros e convidados
- Compartilhar eventos via link público, WhatsApp/e-mail e entre congregações
- Alimentar o módulo de Calendário com eventos aprovados

**O módulo NÃO faz:**
- Controlar presença durante o evento — funcionalidade futura
- Gerenciar financeiro de eventos — responsabilidade do módulo Financeiro
- Criar escalas para o evento — responsabilidade do módulo Escalas

---

## 2. Estados de um Evento

Todo evento possui um ciclo de vida definido pelos seguintes estados:

```
rascunho → aguardando_aprovacao → aprovado
                               ↘ recusado → rascunho (líder edita e reenvia)

aprovado → arquivado (após a data de término)
aprovado → cancelado (secretário ou admin cancela manualmente)
```

| Status | Descrição | Quem pode ver |
|---|---|---|
| `draft` | Criado pelo líder/pastor — ainda não enviado para aprovação | Apenas o criador + secretário + admin |
| `pending_approval` | Enviado para aprovação — aguardando secretário | Criador + secretário + admin |
| `approved` | Aprovado pelo secretário — visível no calendário | Conforme regra de visibilidade do evento |
| `rejected` | Recusado pelo secretário — motivo obrigatório | Criador + secretário + admin |
| `cancelled` | Cancelado manualmente após aprovação | Todos que tinham acesso ao evento |
| `archived` | Arquivado automaticamente após a data de término | Secretário + admin (somente leitura) |

> **Regra:** eventos nunca são excluídos fisicamente. A remoção pelo secretário muda o status para `cancelled` com motivo registrado no `AuditLog`.

---

## 3. Permissões por Perfil

### 3.1 Tabela de ações na listagem

| Perfil | Visualizar | Criar rascunho | Aprovar / Recusar | Editar | Cancelar | Compartilhar |
|---|---|---|---|---|---|---|
| Administrador (Pastor) | ✅ Todos | ✅ (vai p/ aprovação) | ❌ | ✅ Próprios rascunhos | ❌ | ✅ |
| Secretário | ✅ Todos | ✅ (publica direto) | ✅ | ✅ Qualquer evento | ✅ | ✅ |
| Líder de departamento | ✅ Aprovados + próprios rascunhos | ✅ (vai p/ aprovação) | ❌ | ✅ Próprios rascunhos | ❌ | ✅ Aprovados |
| Regente | ✅ Aprovados | ❌ | ❌ | ❌ | ❌ | ✅ Aprovados |
| Tesoureiro | ❌ Sem acesso* | — | — | — | — | — |
| Acolhimento | ✅ Aprovados | ❌ | ❌ | ❌ | ❌ | ❌ |
| Zelador | ❌ Sem acesso* | — | — | — | — | — |
| Membro com cargo | ✅ Aprovados (conforme visibilidade) | ❌ | ❌ | ❌ | ❌ | ❌ |
| Membro sem cargo | ❌ Sem acesso ao módulo | — | — | — | — | — |

> **\* Acesso condicional — Tesoureiro e Zelador:** por padrão, esses perfis **não têm acesso** ao módulo de Eventos. O Secretário ou o Administrador (Pastor) podem liberar o acesso individualmente nas **Configurações → Perfis e Permissões**. Quando liberado, o acesso é sempre somente leitura (apenas visualizar eventos aprovados) — nunca criar, editar ou aprovar.

### 3.2 Regra especial do Secretário

O secretário **publica eventos diretamente** sem passar pelo fluxo de aprovação — ele é o próprio aprovador. Se o secretário criar um evento, o status vai direto para `approved`.

### 3.3 Regra de edição

- Líder/pastor só podem editar eventos com status `draft` ou `rejected` (próprios)
- Após o envio para aprovação (`pending_approval`), o evento fica bloqueado para edição até ser aprovado ou recusado
- O secretário pode editar qualquer evento em qualquer status

---

## 4. Página de Listagem (`panel/events`)

### 4.1 Barra de filtros

**Busca textual** — campo único que pesquisa simultaneamente em:
- Título
- Local
- Descrição

**Filtro rápido por período** — botões de seleção única:
- Todos (default)
- Hoje
- Próximos 7 dias
- Próximos 30 dias

**Filtros adicionais** — dropdowns:
- Departamento (lista os departamentos da church + opção "Todos")
- Visibilidade (Pública / Membros / Privada / Todas)
- Status (Aprovado / Aguardando aprovação / Rascunho / Recusado / Cancelado / Todos)
- Date range picker: data de início e data de fim

**Botão "Limpar filtros"** — visível apenas quando algum filtro diferente do default estiver ativo. Restaura todos os filtros para o estado inicial.

### 4.2 Tabela de eventos

Colunas exibidas:

| Coluna | Conteúdo |
|---|---|
| **Quando** | Data e hora de início formatada (ex: "Sab, 07 Jun · 19h00") |
| **Evento** | Título + badge de status (ver 4.3) |
| **Local** | Local do evento |
| **Departamento** | Nome do departamento vinculado |
| **Visibilidade** | Badge: Pública / Membros / Privada |
| **Inscritos** | Contador de inscrições (ex: "32 inscritos") — exibir "—" se inscrições desativadas |
| **Ações** | Ícones de ação conforme permissão do perfil logado |

**Ordenação padrão:** data de início ascendente (próximos eventos primeiro).

**Paginação:** 15 itens por página. Exibir paginação **apenas** quando houver registros. Se não houver nenhum evento correspondente aos filtros ativos, exibir:

```
[ícone de calendário vazio]
Nenhum evento encontrado.
Tente ajustar os filtros ou crie um novo evento.
```

### 4.3 Badges de status na tabela

| Status | Badge | Cor |
|---|---|---|
| `approved` | Aprovado | Verde |
| `pending_approval` | Aguardando aprovação | Âmbar |
| `draft` | Rascunho | Cinza |
| `rejected` | Recusado | Vermelho |
| `cancelled` | Cancelado | Vermelho escuro |
| `archived` | Encerrado | Cinza escuro |

### 4.4 Coluna de ações

Ícones exibidos conforme o perfil logado e o status do evento:

| Ação | Ícone | Quem vê |
|---|---|---|
| Visualizar | `Eye` | Todos com acesso ao evento |
| Editar | `Pencil` | Secretário (sempre) / Líder+Pastor (só `draft` e `rejected` próprios) |
| Aprovar | `CheckCircle` | Secretário — apenas em `pending_approval` |
| Recusar | `XCircle` | Secretário — apenas em `pending_approval` |
| Compartilhar | `Share2` | Secretário, Admin, Líder, Regente — apenas `approved` |
| Cancelar | `Ban` | Secretário — apenas `approved` |

### 4.5 Botão "+ Novo Evento"

Posicionado no canto superior direito da página. Visível para: Administrador, Secretário, Líder de departamento.

---

## 5. Formulário de Evento

### 5.1 Campos

| Campo | Tipo | Obrigatório | Observação |
|---|---|---|---|
| `title` | Input texto | ✅ | Mín. 3 caracteres |
| `slug` | Input texto (somente leitura) | — | Gerado automaticamente pelo título. Ex: "Culto de Domingo" → `culto-de-domingo`. Exibido abaixo do título como referência |
| `description` | Textarea com editor rich text | ❌ | Suporta negrito, itálico, listas e links |
| `thumbnail` | Upload de imagem OU URL externa | ❌ | Ver regras em 5.2 |
| `location` | Input texto | ✅ | Ex: "Templo sede", "Salão principal" |
| `start_date` + `start_time` | Date picker + Time picker | ✅ | Data e hora de início |
| `end_date` + `end_time` | Date picker + Time picker | ✅ | Data e hora de término |
| `departament_id` | Select | ✅ | Default: "Geral" (todos os departamentos) |
| `visibility` | Select | ✅ | Default: "Privada" |
| `registration_enabled` | Toggle | ❌ | Habilita inscrições para o evento. Default: desativado |
| `registration_limit` | Input numérico | ❌ | Visível apenas se `registration_enabled = true`. Limite de inscrições (0 = ilimitado) |

### 5.2 Campo de imagem — regras

O campo aceita **upload de arquivo** OU **URL externa** — alternados por tabs:

**Tab "Upload":**
- Área de drag-and-drop
- Formatos aceitos: JPG, PNG, WebP
- Tamanho máximo: 5 MB
- Preview após seleção com opção de remover

**Tab "URL externa":**
- Input de texto com validação de URL
- Preview da imagem ao perder o foco (blur) se a URL for válida

### 5.3 Campo de visibilidade — opções

| Valor | Descrição |
|---|---|
| `private` | Apenas membros do departamento vinculado ao evento veem. **Default.** |
| `members` | Todos os membros ativos da church veem, independente de departamento |
| `public` | Qualquer pessoa com o link pode ver (página pública sem login) |

> **Atenção ao default:** o departamento padrão é "Geral" (todos os departamentos) e a visibilidade padrão é "Privada" (só o departamento). Quando o departamento é "Geral" e a visibilidade é "Privada", **todos os membros ativos da church** podem ver o evento — pois "Geral" não é um departamento real, é um agrupador que representa toda a congregation.

### 5.4 Geração do slug

- Gerado automaticamente ao sair do campo `title` (evento `blur`)
- Formato: minúsculas, sem acentos, espaços substituídos por hífens
- Sufixo numérico se já existir slug igual na church (ex: `culto-de-domingo-2`)
- Exibido abaixo do campo de título como somente leitura: `panel/events/culto-de-domingo`
- Não editável pelo usuário

### 5.5 Validações do formulário

- `end_date` + `end_time` deve ser posterior a `start_date` + `start_time`
- `registration_limit` deve ser maior que zero se preenchido
- Se `registration_enabled = true` e o evento for salvo como `approved`, o sistema cria automaticamente o formulário de inscrição vinculado
- Alerta visual (não bloqueante) se houver outro evento aprovado no mesmo departamento no mesmo intervalo de datas — ver seção 5.6

### 5.6 Verificação de conflito de datas

Ao preencher `start_date` / `end_date`, o sistema verifica em background se existe algum evento com status `approved` no mesmo departamento com datas sobrepostas.

Se houver conflito:
- Exibir aviso âmbar abaixo do campo de data: `⚠ Já existe um evento aprovado neste departamento neste período: "[Título do evento]" (07/06 às 19h00)`
- O usuário **pode** continuar mesmo assim — não bloqueante
- O conflito fica registrado e visível na listagem para o secretário

### 5.7 Comportamento do botão de submit por perfil

| Perfil | Label do botão | Ação |
|---|---|---|
| Secretário | "Publicar evento" | Salva com status `approved` diretamente |
| Admin (Pastor) | "Enviar para aprovação" | Salva com status `pending_approval` |
| Líder de departamento | "Enviar para aprovação" | Salva com status `pending_approval` |

Todos os perfis têm também o botão secundário **"Salvar rascunho"** que salva com status `draft` sem enviar para aprovação.

---

## 6. Fluxo de Aprovação

### 6.1 Fluxo completo

```
Líder ou Pastor preenche o formulário
          │
          ▼
"Salvar rascunho" → status: draft (pode editar)
          │
          ▼
"Enviar para aprovação" → status: pending_approval
          │
          ▼
Secretário recebe badge numérico no sino da navbar
          │
          ▼
Secretário acessa panel/events e vê o evento com badge "Aguardando aprovação"
Na coluna Ações aparecem os botões: ✓ Aprovar | ✗ Recusar
          │
     ┌────┴────┐
     ▼         ▼
  APROVAR    RECUSAR
     │         │
     ▼         ▼
status:     Modal pede
approved    motivo da recusa
     │      (obrigatório)
     ▼         │
Criador        ▼
recebe     status: rejected
notificação    │
"Evento        ▼
aprovado"  Criador recebe
           notificação
           "Evento recusado"
           com o motivo
           │
           ▼
       Criador acessa
       o rascunho,
       edita e reenvia
       ("Enviar para aprovação")
```

### 6.2 Notificações do fluxo

| Gatilho | Destinatário | Mensagem |
|---|---|---|
| Evento enviado para aprovação | Secretário | "Novo evento aguardando aprovação: [Título]" |
| Evento aprovado | Criador | "Seu evento '[Título]' foi aprovado e está no calendário." |
| Evento recusado | Criador | "Seu evento '[Título]' foi recusado. Motivo: [motivo]. Você pode editar e reenviar." |
| Evento cancelado | Inscritos no evento | "O evento '[Título]' foi cancelado." |

### 6.3 Indicadores visuais para o Secretário

Na listagem `panel/events`, eventos com `status: pending_approval` recebem:
- Badge âmbar "Aguardando aprovação" ao lado do título
- Botões `✓ Aprovar` e `✗ Recusar` na coluna Ações (substituem os demais)
- Linha com fundo levemente destacado para facilitar identificação

### 6.4 Reenvio após recusa

- O criador pode editar **qualquer campo** do evento recusado
- Ao reenviar, o status muda de `rejected` para `pending_approval`
- O secretário recebe nova notificação
- O histórico de recusas anteriores fica registrado no `AuditLog` (motivo + data + secretário)
- Não há limite de reenvios

---

## 7. Ação de Compartilhar

O botão "Compartilhar" está disponível apenas para eventos com `status: approved`. Ao clicar, abre um modal com três opções:

### 7.1 Copiar link público

- Gera e copia para o clipboard a URL pública do evento:
  `https://ekklesia.com.br/eventos/[slug]`
- Disponível apenas se `visibility: public`
- Se `visibility: members` ou `private`: exibe aviso "Este evento não é público. Altere a visibilidade para gerar um link público."

### 7.2 Compartilhar via WhatsApp / E-mail

- **WhatsApp:** abre `https://wa.me/?text=` com título, data, local e link do evento pré-formatados
- **E-mail:** abre o cliente de e-mail padrão com `mailto:` pré-preenchido com subject e body

### 7.3 Enviar para congregações do campo (Secretário Sede)

Exclusivo para o **Secretário Sede**:
- Checklist das congregações filhas do campo
- Ao confirmar, as congregações selecionadas recebem o evento como notificação
- O evento aparece no calendário das filhas como somente leitura com badge "Compartilhado pela sede"

---

## 8. Integração com Calendário

- Todo evento com `status: approved` aparece automaticamente no módulo Calendário (`panel/calendar`)
- Eventos `draft`, `pending_approval` e `rejected` **não aparecem** no calendário
- Eventos `cancelled` são removidos do calendário imediatamente
- Eventos `archived` permanecem no calendário como somente leitura com estilo visual diferenciado (opaco)
- A cor do evento no calendário segue a cor do departamento vinculado

---

## 9. Regras de Integridade

### 9.1 Soft delete — nunca excluir fisicamente

A ação "Deletar/Cancelar" de um evento **nunca remove o registro do banco**. Ela:
- Muda o status para `cancelled`
- Registra no `AuditLog`: quem cancelou, motivo e timestamp
- Notifica os inscritos no evento
- Remove o evento do calendário

### 9.2 Auditoria

Toda ação relevante é registrada no `AuditLog`:

| Ação | Registrado |
|---|---|
| Evento criado (rascunho) | ✅ |
| Evento enviado para aprovação | ✅ |
| Evento aprovado | ✅ com `approved_by_id` |
| Evento recusado | ✅ com motivo |
| Evento editado | ✅ com snapshot antes/depois |
| Evento cancelado | ✅ com motivo |
| Evento compartilhado | ✅ com canal e destinatário |

### 9.3 Isolamento multi-tenant

- Eventos pertencem à church do usuário logado (`church_id`)
- `church_id` é preenchido automaticamente — nunca exposto como campo editável
- Usuário de uma church nunca vê eventos de outra church
- Exceção: evento compartilhado pelo secretário sede aparece nas filhas como somente leitura

---

## 10. Modelagem Rails

### 10.1 Migration — campos adicionais ao schema existente

O schema já possui a tabela `events`. Adicionar os campos faltantes:

```ruby
class AddMissingFieldsToEvents < ActiveRecord::Migration[8.0]
  def change
    # Status do fluxo de aprovação
    add_column :events, :status,          :integer, null: false, default: 0
    add_column :events, :approved_by_id,  :bigint
    add_column :events, :approved_at,     :datetime
    add_column :events, :rejection_reason, :string
    add_column :events, :cancelled_at,    :datetime
    add_column :events, :cancelled_by_id, :bigint
    add_column :events, :cancel_reason,   :string

    # Horários (o schema tem date — adicionar time)
    add_column :events, :start_time,      :time
    add_column :events, :end_time,        :time

    # Imagem como URL (upload tratado via Active Storage separadamente)
    add_column :events, :thumbnail_url,   :string

    # Inscrições
    add_column :events, :registration_enabled, :boolean, null: false, default: false
    add_column :events, :registration_limit,   :integer, default: 0

    add_index :events, :status
    add_index :events, :approved_by_id
    add_index :events, [:church_id, :status],
              name: "index_events_on_church_and_status"
    add_index :events, [:departament_id, :start_date, :end_date],
              name: "index_events_on_dept_and_dates"

    add_foreign_key :events, :users, column: :approved_by_id
    add_foreign_key :events, :users, column: :cancelled_by_id
  end
end
```

### 10.2 Model `Event`

```ruby
# app/models/event.rb
class Event < ApplicationRecord
  belongs_to :church
  belongs_to :departament
  belongs_to :created_by,   class_name: "User"
  belongs_to :approved_by,  class_name: "User", optional: true
  belongs_to :cancelled_by, class_name: "User", optional: true
  has_many   :event_attendees, dependent: :destroy

  enum :status, {
    draft:            0,
    pending_approval: 1,
    approved:         2,
    rejected:         3,
    cancelled:        4,
    archived:         5
  }

  enum :visibility, {
    private_event: 0,
    members:       1,
    public_event:  2
  }

  # Scopes
  scope :do_church,   ->(church_id) { where(church_id: church_id) }
  scope :upcoming,    -> { where("start_date >= ?", Date.current).order(:start_date) }
  scope :this_week,   -> { where(start_date: Date.current..7.days.from_now) }
  scope :this_month,  -> { where(start_date: Date.current..30.days.from_now) }
  scope :visible_to,  ->(user) { approved.where(church_id: user.church_id) }
  scope :pending,     -> { where(status: :pending_approval) }

  # Validações
  validates :title,    presence: true, length: { minimum: 3 }
  validates :location, presence: true
  validates :start_date, :end_date, presence: true
  validates :departament_id, :visibility, presence: true
  validates :registration_limit,
            numericality: { greater_than: 0 },
            allow_nil: true,
            if: :registration_enabled?

  validate :end_must_be_after_start
  before_validation :generate_slug, if: -> { slug.blank? && title.present? }

  # Transições de estado semânticas
  def submit_for_approval!(by:)
    update!(status: :pending_approval)
    Events::NotifyApprovalPendingJob.perform_later(id, by.id)
  end

  def approve!(by:)
    update!(status: :approved, approved_by: by, approved_at: Time.current)
    Events::NotifyApprovedJob.perform_later(id)
  end

  def reject!(by:, reason:)
    update!(status: :rejected, rejection_reason: reason)
    Events::NotifyRejectedJob.perform_later(id, reason)
  end

  def cancel!(by:, reason:)
    update!(
      status:          :cancelled,
      cancelled_by:    by,
      cancelled_at:    Time.current,
      cancel_reason:   reason
    )
    Events::NotifyCancelledJob.perform_later(id)
  end

  private

  def generate_slug
    base = title.parameterize
    candidate = base
    counter = 2
    while Event.where(church_id: church_id).exists?(slug: candidate)
      candidate = "#{base}-#{counter}"
      counter += 1
    end
    self.slug = candidate
  end

  def end_must_be_after_start
    return unless start_date.present? && end_date.present?
    if end_date < start_date ||
       (end_date == start_date && end_time.present? && start_time.present? && end_time <= start_time)
      errors.add(:end_date, "deve ser posterior à data e hora de início")
    end
  end
end
```

---

## 11. Glossário

| Termo | Definição |
|---|---|
| **Rascunho** (`draft`) | Estado inicial de um evento — visível apenas para o criador e secretário |
| **Aguardando aprovação** (`pending_approval`) | Evento enviado pelo líder/pastor — aguarda decisão do secretário |
| **Aprovado** (`approved`) | Evento publicado no calendário da church |
| **Recusado** (`rejected`) | Evento reprovado pelo secretário — criador pode editar e reenviar |
| **Cancelado** (`cancelled`) | Evento aprovado que foi cancelado manualmente — inscritos são notificados |
| **Arquivado** (`archived`) | Evento que passou da data de término — somente leitura |
| **Visibilidade Privada** | Apenas membros do departamento vinculado ao evento veem |
| **Visibilidade Membros** | Todos os membros ativos da church veem |
| **Visibilidade Pública** | Qualquer pessoa com o link pode acessar sem login |
| **Slug** | Identificador único de URL gerado pelo título (ex: `culto-de-domingo`) |
| **Soft delete** | Remoção lógica — o registro permanece no banco com status `cancelled` |
| **Conflito de datas** | Sobreposição de período com outro evento aprovado no mesmo departamento |
| **Compartilhar para o campo** | Envio do evento pelo secretário sede para congregações filhas — somente leitura |
| **Acesso condicional** | Acesso a um módulo que não está habilitado por padrão para um perfil — liberado explicitamente pelo Secretário ou Pastor nas Configurações |
| **AuditLog** | Tabela de rastreabilidade de todas as ações executadas no sistema |

---

*Ekklesia — Documento interno · Versão 1.0 · Julho 2026*
