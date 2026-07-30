# Ekklesia — Regras de Negócio
## Perfil Zelador (Almoxarifado)

> **Versão 1.0 · Julho 2026**
> Documento interno — uso restrito à equipe de produto

---

## Sumário

1. [Visão Geral](#1-visão-geral)
2. [Perfil e Permissões](#2-perfil-e-permissões)
3. [Módulo Estoque](#3-módulo-estoque)
4. [Módulo Solicitações de Compra](#4-módulo-solicitações-de-compra)
5. [Alertas e Notificações](#5-alertas-e-notificações)
6. [Dashboard do Zelador](#6-dashboard-do-zelador)
7. [Regras de Segurança e Integridade](#7-regras-de-segurança-e-integridade)
8. [Modelagem Rails](#8-modelagem-rails)
9. [Funcionalidades Futuras](#9-funcionalidades-futuras)
10. [Glossário](#10-glossário)

---

## 1. Visão Geral

O **Zelador** é o responsável pela gestão de materiais, suprimentos e conservação física da congregação. No sistema Ekklesia, o zelador opera um módulo próprio focado em controle de estoque e solicitações de compra — sem acesso aos demais módulos administrativos da instituição.

**O Zelador é responsável por:**
- Controlar o estoque de materiais da própria congregação (entrada, saída e saldo)
- Definir quantidade mínima de cada item e receber alertas de reposição
- Solicitar compras ao tesoureiro quando o estoque estiver baixo ou quando houver necessidade pontual
- Acompanhar o status das solicitações enviadas

**O Zelador NÃO é responsável por:**
- Aprovar suas próprias solicitações de compra
- Acessar o financeiro geral da instituição
- Gerenciar membros, departamentos, eventos ou escalas
- Ver dados de outras congregações
- Acessar configurações do sistema

---

## 2. Perfil e Permissões

### 2.1 Role

| Campo | Valor |
|---|---|
| Role | `warehouse` |
| Policy (Pundit) | `WarehousePolicy` |
| Escopo de atuação | Apenas própria congregação (`church_id`) |

### 2.2 Acesso por módulo

| Módulo | Acesso |
|---|---|
| Dashboard do Zelador | ✅ Métricas de estoque e solicitações do dia |
| Estoque | ✅ CRUD completo — apenas própria congregação |
| Solicitações de compra | ✅ Criar e acompanhar status |
| Financeiro geral | ❌ |
| Membros | ❌ |
| Departamentos | ❌ |
| Eventos | ❌ |
| Escalas | ❌ |
| Formulários | ❌ |
| Acolhimento | ❌ |
| Aniversariantes | ❌ |
| Configurações | ❌ |

### 2.3 Visibilidade multi-tenant

- O zelador enxerga **apenas dados da própria congregação**
- Zelador da sede e zelador de congregação filha têm o mesmo escopo — cada um vê apenas a própria unidade
- `church_id` é preenchido automaticamente em todos os registros — nunca exposto como campo editável

---

## 3. Módulo Estoque

### 3.1 O que é um item de estoque

Cada item representa um produto ou material utilizado na manutenção e operação da congregação.

**Categorias sugeridas (configuráveis):**
- Limpeza (ex: sabão, desinfetante, papel higiênico)
- Manutenção (ex: lâmpadas, pilhas, fita isolante)
- Escritório (ex: papel, caneta, grampeador)
- Cozinha (ex: copos descartáveis, detergente)
- Outros

### 3.2 Campos do item de estoque

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `name` | `string` | ✅ | Nome do item (ex: "Sabão em pó 1kg") |
| `category` | `string` | ✅ | Categoria do item |
| `unit` | `string` | ✅ | Unidade de medida (ex: unidade, kg, litro, pacote) |
| `current_quantity` | `decimal` | ✅ | Quantidade atual em estoque — calculada automaticamente |
| `minimum_quantity` | `decimal` | ✅ | Quantidade mínima antes de gerar alerta de reposição |
| `location` | `string` | ❌ | Local de armazenamento (ex: "Depósito fundos") |
| `notes` | `text` | ❌ | Observações livres |
| `church_id` | `bigint` | ✅ | Congregação — preenchido automaticamente |

### 3.3 Movimentações de estoque

Toda alteração de quantidade é feita via **movimentação** — o zelador nunca edita `current_quantity` diretamente. O saldo é sempre calculado a partir do histórico de movimentações.

| Tipo de movimentação | Quando usar |
|---|---|
| `entrada` | Compra chegou e foi recebida no estoque |
| `saida` | Material foi consumido ou retirado |
| `ajuste` | Correção de inventário (ex: após contagem física) |
| `estorno` | Desfaz uma movimentação registrada por engano |

**Campos da movimentação:**

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `stock_item_id` | `bigint FK` | ✅ | Item movimentado |
| `movement_type` | `enum` | ✅ | `entrada`, `saida`, `ajuste`, `estorno` |
| `quantity` | `decimal` | ✅ | Quantidade movimentada |
| `reason` | `string` | ✅ | Motivo (ex: "Recebimento de compra", "Uso na limpeza semanal") |
| `purchase_request_id` | `bigint FK` | ❌ | Vínculo com solicitação de compra (quando for entrada por compra aprovada) |
| `registered_by_id` | `bigint FK` | ✅ | Zelador que registrou |
| `created_at` | `datetime` | ✅ | Timestamp automático |

### 3.4 Regras de movimentação

- `current_quantity` nunca pode ser negativo — o sistema bloqueia saídas maiores que o saldo disponível
- Toda movimentação é **permanente** — erros são corrigidos via `estorno`, nunca por edição ou exclusão
- Ao registrar uma `entrada` vinculada a uma solicitação de compra, o sistema atualiza automaticamente o status da solicitação para `recebido`
- Toda movimentação é registrada no `AuditLog`

### 3.5 Controle de quantidade mínima

- O zelador define `minimum_quantity` para cada item no cadastro
- O sistema verifica diariamente se `current_quantity <= minimum_quantity`
- Se atingir o mínimo: gera alerta para o zelador (sino + notificação) e cria automaticamente uma **sugestão de solicitação de compra** (não enviada — o zelador confirma antes)

---

## 4. Módulo Solicitações de Compra

### 4.1 O que é

Uma solicitação de compra é um pedido formal do zelador ao tesoureiro para aquisição de materiais. O tesoureiro aprova e autoriza o gasto; o pastor tem visibilidade de todas as solicitações.

### 4.2 Fluxo completo

```
Zelador cria solicitação de compra
(item, quantidade, justificativa, urgência)
          │
          ▼
Tesoureiro recebe notificação
Pastor recebe notificação (somente leitura)
          │
     ┌────┴────┐
     ▼         ▼
 Aprova     Recusa (com motivo obrigatório)
     │         │
     ▼         ▼
Zelador     Zelador é notificado
notificado  e pode revisar
e realiza   e reenviar
a compra
     │
     ▼
Zelador registra entrada no estoque
(vinculada à solicitação aprovada)
     │
     ▼
Status da solicitação → recebido
Tesoureiro e pastor são notificados
```

### 4.3 Status da solicitação

| Status | Descrição |
|---|---|
| `pending` | Aguardando aprovação do tesoureiro |
| `approved` | Tesoureiro aprovou — zelador pode realizar a compra |
| `rejected` | Tesoureiro recusou — motivo obrigatório |
| `purchased` | Zelador marcou como comprado — aguardando recebimento |
| `received` | Entrada registrada no estoque — solicitação concluída |
| `cancelled` | Cancelada pelo zelador antes da aprovação |

### 4.4 Campos da solicitação

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `church_id` | `bigint FK` | ✅ | Congregação — automático |
| `stock_item_id` | `bigint FK` | ❌ | Item do estoque (opcional — pode ser item novo) |
| `item_name` | `string` | ✅ | Nome do item (preenchido do estoque ou digitado manualmente) |
| `quantity_requested` | `decimal` | ✅ | Quantidade solicitada |
| `unit` | `string` | ✅ | Unidade de medida |
| `estimated_cost` | `decimal` | ❌ | Valor estimado da compra |
| `justification` | `text` | ✅ | Justificativa da compra |
| `urgency` | `enum` | ✅ | `low`, `medium`, `high` |
| `status` | `enum` | ✅ | Ver tabela acima |
| `requested_by_id` | `bigint FK` | ✅ | Zelador solicitante |
| `approved_by_id` | `bigint FK` | ❌ | Tesoureiro aprovador |
| `approved_at` | `datetime` | ❌ | Data de aprovação |
| `rejection_reason` | `string` | ❌ | Motivo da recusa (obrigatório se `rejected`) |
| `received_at` | `datetime` | ❌ | Data de recebimento no estoque |

### 4.5 Regras da solicitação

- O zelador pode cancelar uma solicitação enquanto `status = pending`
- Após aprovação, o zelador não pode cancelar — deve comunicar o tesoureiro
- Uma solicitação recusada pode ser **reeditada e reenviada** pelo zelador com os ajustes necessários
- O zelador **não pode** editar uma solicitação após envio — apenas cancelar e criar nova
- O tesoureiro **não pode** editar o valor ou a quantidade da solicitação — apenas aprovar ou recusar
- Solicitações com `urgency: high` geram notificação prioritária para o tesoureiro (badge diferenciado)
- Toda ação na solicitação é registrada no `AuditLog`

### 4.6 Visibilidade do pastor

- O pastor visualiza **todas as solicitações** da própria congregação em modo somente leitura
- Recebe notificação ao criar e ao concluir (`received`) cada solicitação
- Não aprova nem recusa — apenas acompanha

---

## 5. Alertas e Notificações

| Alerta | Gatilho | Destinatário |
|---|---|---|
| ⚠ Estoque baixo | `current_quantity <= minimum_quantity` | Zelador (sino + sugestão de solicitação) |
| ✅ Solicitação aprovada | Tesoureiro aprova | Zelador |
| ❌ Solicitação recusada | Tesoureiro recusa | Zelador |
| 📦 Nova solicitação | Zelador cria solicitação | Tesoureiro + Pastor (somente leitura) |
| ✅ Recebimento confirmado | Zelador registra entrada | Tesoureiro + Pastor |
| ⚠ Solicitação urgente | `urgency: high` | Tesoureiro (badge prioritário) |

---

## 6. Dashboard do Zelador

Tela inicial após o login. Foco em visibilidade rápida do estado atual do estoque e das solicitações.

### 6.1 Cards de resumo

| Card | O que exibe |
|---|---|
| Itens no estoque | Total de itens cadastrados |
| Itens com estoque baixo | Itens com `current_quantity <= minimum_quantity` |
| Solicitações pendentes | Solicitações com `status: pending` |
| Solicitações aprovadas | Solicitações com `status: approved` — aguardando compra |

### 6.2 Lista de alertas de estoque baixo

Abaixo dos cards, lista dos itens com estoque abaixo do mínimo:
- Nome do item
- Quantidade atual vs. quantidade mínima
- Botão de ação rápida: **"Solicitar reposição"** — pré-preenche o formulário de solicitação com os dados do item

### 6.3 Últimas movimentações

Tabela com as 10 últimas movimentações registradas:
- Data/hora, item, tipo (badge colorido), quantidade, responsável

### 6.4 Solicitações recentes

Lista das últimas 5 solicitações com status atualizado em tempo real via Turbo Stream.

---

## 7. Regras de Segurança e Integridade

### 7.1 O que o zelador NUNCA pode fazer

- Aprovar as próprias solicitações de compra
- Editar `current_quantity` diretamente — apenas via movimentações
- Excluir movimentações ou solicitações — apenas estornar ou cancelar
- Acessar qualquer módulo fora de Estoque e Solicitações de Compra
- Ver dados de outras congregações
- Acessar o financeiro geral da instituição
- Acessar configurações do sistema

### 7.2 Auditoria

Toda ação do zelador é registrada no `AuditLog`:

| Ação | Registrado |
|---|---|
| Item de estoque criado / editado | ✅ |
| Movimentação registrada | ✅ com tipo e quantidade |
| Movimentação estornada | ✅ com motivo |
| Solicitação de compra criada | ✅ |
| Solicitação cancelada | ✅ com motivo |
| Entrada vinculada a solicitação aprovada | ✅ |

### 7.3 Validações obrigatórias

- `church_id` preenchido automaticamente — nunca editável pelo zelador
- `current_quantity` nunca negativo — bloqueado no model e no banco (`CHECK` constraint)
- `rejection_reason` obrigatório quando `status = rejected`
- `movement_type: estorno` obrigatoriamente referencia a movimentação original

---

## 8. Modelagem Rails

### 8.1 Migration — Itens de estoque

```ruby
class CreateStockItems < ActiveRecord::Migration[8.0]
  def change
    create_table :stock_items do |t|
      t.references :church,       null: false, foreign_key: true
      t.references :created_by,   null: false,
                   foreign_key: { to_table: :users }
      t.string     :name,         null: false
      t.string     :category,     null: false
      t.string     :unit,         null: false
      t.decimal    :current_quantity, null: false,
                   precision: 10, scale: 3, default: 0
      t.decimal    :minimum_quantity, null: false,
                   precision: 10, scale: 3, default: 0
      t.string     :location
      t.text       :notes
      t.integer    :status,       null: false, default: 0
      t.timestamps
    end

    add_index :stock_items, [:church_id, :name], unique: true,
              name: "index_stock_items_on_church_and_name"
    add_index :stock_items, :category
    add_index :stock_items, :status

    # Constraint no banco: quantidade nunca negativa
    execute <<-SQL
      ALTER TABLE stock_items
      ADD CONSTRAINT stock_items_current_quantity_non_negative
      CHECK (current_quantity >= 0);
    SQL

    # enum :status, { active: 0, inactive: 1 }
  end
end
```

### 8.2 Migration — Movimentações de estoque

```ruby
class CreateStockMovements < ActiveRecord::Migration[8.0]
  def change
    create_table :stock_movements do |t|
      t.references :stock_item,        null: false, foreign_key: true
      t.references :registered_by,     null: false,
                   foreign_key: { to_table: :users }
      t.references :purchase_request,  foreign_key: true, null: true
      t.bigint     :reversal_of_id
      t.integer    :movement_type,     null: false
      t.decimal    :quantity,          null: false,
                   precision: 10, scale: 3
      t.decimal    :quantity_before,   null: false,
                   precision: 10, scale: 3
      t.decimal    :quantity_after,    null: false,
                   precision: 10, scale: 3
      t.string     :reason,            null: false
      t.timestamps
    end

    add_index :stock_movements, :movement_type
    add_index :stock_movements, :reversal_of_id
    add_foreign_key :stock_movements, :stock_movements,
                    column: :reversal_of_id

    # enum :movement_type, {
    #   entrada: 0,
    #   saida:   1,
    #   ajuste:  2,
    #   estorno: 3
    # }
  end
end
```

### 8.3 Migration — Solicitações de compra

```ruby
class CreatePurchaseRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :purchase_requests do |t|
      t.references :church,         null: false, foreign_key: true
      t.references :stock_item,     foreign_key: true, null: true
      t.references :requested_by,   null: false,
                   foreign_key: { to_table: :users }
      t.bigint     :approved_by_id
      t.string     :item_name,      null: false
      t.string     :unit,           null: false
      t.decimal    :quantity_requested, null: false,
                   precision: 10, scale: 3
      t.decimal    :estimated_cost, precision: 10, scale: 2
      t.text       :justification,  null: false
      t.integer    :urgency,        null: false, default: 1
      t.integer    :status,         null: false, default: 0
      t.string     :rejection_reason
      t.datetime   :approved_at
      t.datetime   :received_at
      t.timestamps
    end

    add_index :purchase_requests, :status
    add_index :purchase_requests, :urgency
    add_index :purchase_requests, [:church_id, :status],
              name: "index_purchase_requests_on_church_and_status"
    add_foreign_key :purchase_requests, :users,
                    column: :approved_by_id

    # enum :urgency, { low: 0, medium: 1, high: 2 }
    # enum :status,  {
    #   pending:   0,
    #   approved:  1,
    #   rejected:  2,
    #   purchased: 3,
    #   received:  4,
    #   cancelled: 5
    # }
  end
end
```

### 8.4 Model — `StockItem`

```ruby
# app/models/stock_item.rb
class StockItem < ApplicationRecord
  belongs_to :church
  belongs_to :created_by, class_name: "User"
  has_many :stock_movements, dependent: :restrict_with_error
  has_many :purchase_requests, dependent: :restrict_with_error

  enum :status, { active: 0, inactive: 1 }

  scope :do_church,    ->(church_id) { where(church_id: church_id) }
  scope :ativos,       -> { where(status: :active) }
  scope :estoque_baixo, -> {
    where("current_quantity <= minimum_quantity AND status = 0")
  }

  validates :name,             presence: true
  validates :category,         presence: true
  validates :unit,             presence: true
  validates :current_quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :minimum_quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :name, uniqueness: { scope: :church_id,
    message: "já existe nesta congregação" }

  # Registra uma movimentação e atualiza o saldo
  def movimentar!(tipo:, quantidade:, motivo:, por:, solicitacao: nil)
    raise ArgumentError, "Quantidade inválida" if quantidade <= 0

    if tipo == :saida && quantidade > current_quantity
      raise ArgumentError, "Quantidade insuficiente em estoque"
    end

    quantidade_antes = current_quantity
    nova_quantidade  = case tipo
                       when :entrada then current_quantity + quantidade
                       when :saida   then current_quantity - quantidade
                       when :ajuste  then quantidade
                       end

    transaction do
      update!(current_quantity: nova_quantidade)
      stock_movements.create!(
        movement_type:    tipo,
        quantity:         quantidade,
        quantity_before:  quantidade_antes,
        quantity_after:   nova_quantidade,
        reason:           motivo,
        registered_by:    por,
        purchase_request: solicitacao
      )
    end
  end
end
```

---

## 9. Funcionalidades Futuras

| Funcionalidade | Descrição |
|---|---|
| **Registro de serviços realizados** | Zelador registra tarefas de limpeza e manutenção por data e local (ex: "Limpeza do salão — 15/07") |
| **Histórico de serviços** | Pastor e secretário visualizam o histórico de tarefas realizadas pelo zelador |
| **Orçamentos múltiplos** | Zelador anexa orçamentos de fornecedores diferentes antes da aprovação do tesoureiro |
| **Fornecedores cadastrados** | Cadastro de fornecedores recorrentes vinculados aos itens de estoque |
| **Inventário periódico** | Fluxo guiado de contagem física do estoque com geração de relatório de diferenças |
| **Relatório de consumo** | Relatório de saídas por período e categoria para planejamento de compras futuras |
| **Zelador da sede com visão consolidada** | Zelador da sede visualiza resumo do estoque de todas as congregações do campo |

---

## 10. Glossário

| Termo | Definição |
|---|---|
| **Zelador** | Perfil responsável pela gestão de materiais e suprimentos da congregação. Role: `warehouse` |
| **Item de estoque** | Produto ou material cadastrado no sistema com quantidade mínima e saldo atual |
| **Movimentação** | Registro de entrada, saída, ajuste ou estorno que altera o saldo de um item |
| **Quantidade mínima** | Limite configurado pelo zelador abaixo do qual o sistema gera alerta de reposição |
| **Estoque baixo** | Estado em que `current_quantity <= minimum_quantity` |
| **Solicitação de compra** | Pedido formal do zelador ao tesoureiro para aquisição de materiais |
| **Urgência** | Prioridade da solicitação: `low` (baixa), `medium` (média), `high` (alta) |
| **Estorno** | Movimentação que desfaz outra registrada por engano — nunca exclusão física |
| **Entrada** | Movimentação que aumenta o saldo (ex: recebimento de compra) |
| **Saída** | Movimentação que diminui o saldo (ex: consumo de material) |
| **Ajuste** | Correção do saldo após contagem física — registra a diferença com justificativa |
| **AuditLog** | Tabela de rastreabilidade de todas as ações executadas no sistema |
| **church_id** | Identificador da congregação — garante o isolamento de dados entre unidades |

---

*Ekklesia — Documento interno · Versão 1.0 · Julho 2026*