# Ekklesia — Regras de Negócio
## Módulo Membros

> **Versão 1.0 · Julho 2026**
> Documento interno — uso restrito à equipe de produto

---

## Sumário

1. [Visão Geral](#1-visão-geral)
2. [Permissões por Perfil](#2-permissões-por-perfil)
3. [Página de Listagem](#3-página-de-listagem-panelmembers)
4. [Página de Detalhe do Membro](#4-página-de-detalhe-do-membro)
5. [Cadastro Manual de Membro](#5-cadastro-manual-de-membro)
6. [Edição e Inativação](#6-edição-e-inativação)
7. [Convite de Membro](#7-convite-de-membro)
8. [Regras de Integridade](#8-regras-de-integridade)
9. [Modelagem Rails](#9-modelagem-rails)
10. [Funcionalidades Futuras](#10-funcionalidades-futuras)
11. [Glossário](#11-glossário)

---

## 1. Visão Geral

O módulo de **Membros** é o núcleo do sistema — todas as outras funcionalidades (escalas, departamentos, eventos, acolhimento, aniversariantes) dependem dos dados cadastrados aqui. Ele centraliza o registro, a gestão e o acompanhamento de todos os membros da congregação.

**Rota principal:** `panel/members`

**O módulo é responsável por:**
- Listar e filtrar membros da própria congregação
- Cadastrar novos membros manualmente (secretário/pastor)
- Receber novos membros via **Convite de Membro** (link público)
- Gerenciar status (ativo/inativo) com histórico de motivo
- Exibir o perfil completo de cada membro
- Alimentar os módulos de Escalas, Departamentos, Aniversariantes e Acolhimento

**O módulo NÃO faz:**
- Conceder acesso ao sistema — isso é feito nas Configurações → Usuários
- Gerenciar departamentos — responsabilidade do módulo Departamentos
- Emitir credenciais oficiais — responsabilidade do Secretário Sede

---

## 2. Permissões por Perfil

| Perfil | Visualizar lista | Ver detalhe | Cadastrar | Editar | Inativar | Convite de Membro |
|---|---|---|---|---|---|---|
| Administrador (Pastor) | ✅ Todos | ✅ | ❌ | ❌ | ❌ | ✅ Gerar link |
| Secretário | ✅ Todos | ✅ | ✅ | ✅ | ✅ | ✅ Gerar link |
| Líder de departamento | ✅ Membros do próprio departamento | ✅ Parcial* | ❌ | ❌ | ❌ | ❌ |
| Regente | ✅ Membros do próprio departamento | ✅ Parcial* | ❌ | ❌ | ❌ | ❌ |
| Tesoureiro | ✅ Somente leitura** | ✅ Parcial* | ❌ | ❌ | ❌ | ❌ |
| Acolhimento | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Zelador | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Membro com cargo | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Membro sem cargo | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |

> **\* Detalhe parcial:** Líder, Regente e Tesoureiro veem apenas: nome, foto, telefone, departamento e cargo. Campos sensíveis como endereço completo, data de nascimento completa e notas pastorais ficam ocultos.

> **\*\* Tesoureiro:** acesso somente leitura à lista de membros — necessário para vincular dízimos nominais. Habilitado por padrão para o Tesoureiro, diferente do módulo de Eventos onde o acesso é condicional.

---

## 3. Página de Listagem (`panel/members`)

### 3.1 Filtros

**Busca textual** — campo único que pesquisa simultaneamente em:
- Nome completo
- E-mail
- Telefone

**Filtros por dropdown:**

| Filtro | Default | Opções |
|---|---|---|
| Cargo | Todos os cargos | Lista de cargos cadastrados na church + "Sem cargo" |
| Departamento | Todos os departamentos | Lista de departamentos ativos da church |
| Status | Ativos | Ativo / Inativo / Pendente / Todos |
| Batizado | Todos | Batizado / Não batizado |

**Botão "Limpar filtros"** — visível apenas quando algum filtro diferente do default estiver ativo.

### 3.2 Tabela

Colunas exibidas:

| Coluna | Conteúdo |
|---|---|
| **Membro** | Avatar (foto ou inicial do nome em círculo colorido) + Nome completo + E-mail |
| **Departamento** | Badges com os nomes dos departamentos. Se mais de 2: exibe 2 badges + contador "+N" |
| **Cargo** | Badge com o cargo no respectivo departamento. Se sem cargo: exibe `—` |
| **Telefone** | Número com máscara `(DD) 9XXXX-XXXX`. Ícone WhatsApp clicável se preenchido |
| **Desde** | Data de ingresso na congregação (ex: "Mar 2024") |
| **Status** | Badge: Ativo (verde) / Inativo (cinza) / Pendente (âmbar) |
| **Ações** | Ícones conforme permissão do perfil logado |

**Ordenação padrão:** nome completo ascendente (A → Z).

**Paginação:** 20 itens por página. Exibida apenas quando houver registros. Se não houver nenhum resultado:

```
[ícone de pessoas vazio]
Nenhum membro encontrado.
Tente ajustar os filtros ou cadastre um novo membro.
```

### 3.3 Coluna de ações

| Ação | Ícone | Quem vê |
|---|---|---|
| Ver perfil | `Eye` | Todos com acesso à listagem |
| Editar | `Pencil` | Secretário |
| Inativar | `UserX` | Secretário |
| Reativar | `UserCheck` | Secretário (apenas membros inativos) |
| Aprovar cadastro | `CheckCircle` | Secretário (apenas membros com status `pending`) |

### 3.4 Botões do cabeçalho

- **"+ Novo Membro"** — abre o formulário de cadastro manual. Visível para: Secretário
- **"Convite de Membro"** — abre o modal de geração de link. Visível para: Secretário e Administrador (Pastor)

---

## 4. Página de Detalhe do Membro

Rota: `panel/members/:id`

### 4.1 Seções exibidas

**Cabeçalho:**
- Foto/avatar em tamanho maior
- Nome completo
- Badge de status (Ativo / Inativo / Pendente)
- Badge "Batizado" se `baptized: true`
- Data de ingresso ("Membro desde Mar 2024")
- Botões de ação: Editar | Inativar (conforme permissão)

**Informações pessoais:**
- E-mail
- Telefone / WhatsApp (com link direto)
- Data de nascimento (dia e mês visíveis para todos; ano apenas para Secretário e Admin)
- Gênero
- Estado civil

**Endereço** *(visível apenas para Secretário e Admin):*
- CEP, logradouro, número, complemento, bairro, cidade, estado

**Dados eclesiásticos:**
- Cargo atual
- Data de batismo (se batizado)
- Data de apresentação à congregação (se apresentado)
- Congregação de origem (se transferido)

**Departamentos:**
- Cards dos departamentos com o papel do membro em cada um (membro ou líder)

**Notas pastorais** *(visível apenas para Secretário e Admin):*
- Campo de texto livre para anotações internas

**Histórico:**
- Linha do tempo com: data de ingresso, mudanças de cargo, inativações anteriores com motivo

---

## 5. Cadastro Manual de Membro

### 5.1 Campos do formulário

**Dados pessoais**

| Campo | Tipo | Obrigatório | Observação |
|---|---|---|---|
| `name` | Input texto | ✅ | Mín. 3 caracteres |
| `phone` | Input tel | ✅ | Máscara `(DD) 9XXXX-XXXX` |
| `email` | Input email | ❌ | Único por church. Usado para convite de acesso ao sistema |
| `birth_date` | Date picker | ❌ | Base para aniversariantes |
| `gender` | Select | ❌ | Masculino / Feminino / Prefiro não informar |
| `marital_status` | Select | ❌ | Solteiro / Casado / Divorciado / Viúvo |
| `photo` | Upload de imagem | ❌ | JPG, PNG · Máx. 2 MB · Usado como avatar e futuramente na carteirinha |

**Endereço**

| Campo | Tipo | Obrigatório |
|---|---|---|
| `cep` | Input texto com máscara | ❌ |
| `street` | Input texto | ❌ |
| `number` | Input texto | ❌ |
| `complement` | Input texto | ❌ |
| `neighborhood` | Input texto | ❌ |
| `city` | Input texto | ❌ |
| `state` | Select UF | ❌ |

**Dados eclesiásticos**

| Campo | Tipo | Obrigatório | Observação |
|---|---|---|---|
| `baptized` | Toggle | ❌ | Default: false |
| `baptism_date` | Date picker | ❌ | Visível apenas se `baptized: true` |
| `joined_at` | Date picker | ❌ | Data de ingresso na congregação. Default: data atual |
| `position` | Input texto | ❌ | Cargo: Diácono, Presbítero, Obreiro, etc. |
| `departament_id` | Select múltiplo | ❌ | Vincula o membro a um ou mais departamentos |
| `origin_church` | Input texto | ❌ | Congregação de origem (caso seja transferência) |
| `pastoral_notes` | Textarea | ❌ | Notas internas — visível apenas para Secretário e Admin |

### 5.2 Comportamento ao salvar

- Status inicial: `ativo` automaticamente
- O campo **Status** não aparece no formulário de criação — só na edição
- O membro aparece imediatamente na listagem após salvar
- Se `email` preenchido: o membro pode ser convidado para acessar o sistema posteriormente (via Configurações → Usuários)
- Toda criação é registrada no `AuditLog` com: quem criou e timestamp

---

## 6. Edição e Inativação

### 6.1 Edição

- Todos os campos do cadastro ficam disponíveis para edição
- O campo **Status** aparece **apenas** na edição — nunca no cadastro
- Toda edição é registrada no `AuditLog` com snapshot antes/depois

### 6.2 Inativação

Ao clicar em "Inativar", abre um modal de confirmação com:
- Campo de motivo obrigatório (textarea)
- Opções rápidas de motivo: "Transferência", "Afastamento voluntário", "Disciplina", "Outro"
- Botões: Cancelar | Confirmar inativação

**O que acontece ao inativar:**
- Status muda para `inativo`
- Membro é removido de todas as escalas **futuras** do sistema
- Líderes dos departamentos vinculados são notificados
- O membro permanece no histórico de departamentos como "ex-membro"
- Acesso ao sistema (se houver) é revogado automaticamente

**O que NÃO acontece:**
- O registro não é excluído fisicamente — permanece no banco para histórico
- Registros de acolhimento, escalas passadas e formulários respondidos são preservados

### 6.3 Reativação

- Executada pelo Secretário na coluna de ações (apenas membros inativos)
- Motivo de reativação obrigatório
- Status volta para `ativo`
- Acesso ao sistema **não é restaurado automaticamente** — deve ser reconcedido nas Configurações

---

## 7. Convite de Membro

### 7.1 O que é

**Convite de Membro** é a funcionalidade que permite ao Secretário ou Pastor gerar um link temporário e seguro para que um futuro membro se cadastre diretamente no sistema, sem precisar comparecer presencialmente à secretaria.

O link é criptografado, vinculado ao `church_id` e possui prazo de validade e limite de usos configuráveis.

### 7.2 Quem pode gerar

- Secretário ✅
- Administrador (Pastor) ✅
- Demais perfis ❌

### 7.3 Configuração do link

Ao clicar em "Convite de Membro", abre um modal com:

| Campo | Tipo | Obrigatório | Observação |
|---|---|---|---|
| `expires_in` | Select | ✅ | Opções: 24h / 3 dias / 7 dias / 15 dias / 30 dias |
| `max_uses` | Input numérico | ✅ | Quantas pessoas podem usar o link. Mín: 1 · Máx: 500 · Default: 1 |
| `note` | Input texto | ❌ | Identificação interna (ex: "Link para o retiro de junho") |

Após confirmar, o sistema gera o link e exibe:
- URL encurtada e criptografada (ex: `ekklesia.com.br/i/aX7kP2`)
- Botão "Copiar link"
- Botão "Compartilhar via WhatsApp"
- QR Code para facilitar o envio presencial

### 7.4 Segurança do link

- O token é gerado com `SecureRandom.urlsafe_base64(16)` — único e não sequencial
- O link carrega internamente o `church_id` criptografado — nunca exposto na URL
- Ao acessar, o sistema valida: token existe + não expirou + não atingiu o limite de usos
- Se inválido: exibe página de erro "Este link não está mais disponível"

### 7.5 Formulário público (tela sem login)

Rota: `/i/:token`

O formulário exibe no topo:
- Logo da igreja (da configuração da church)
- Nome da igreja
- Texto: "Preencha as informações abaixo para se cadastrar como membro de [Nome da Igreja]."

**Campos do formulário público:**

| Campo | Tipo | Obrigatório |
|---|---|---|
| `name` | Input texto | ✅ |
| `phone` | Input tel com máscara | ✅ |
| `email` | Input email | ❌ |
| `birth_date` | Date picker | ❌ |
| `photo` | Upload de imagem | ❌ |
| `baptized` | Toggle (Sim / Não) | ❌ |

> Campos como endereço, cargo, departamento e notas pastorais **não aparecem** no formulário público — são preenchidos posteriormente pelo Secretário no cadastro interno.

### 7.6 O que acontece após o envio

```
Usuário preenche o formulário e clica em "Enviar"
        │
        ▼
Sistema cria o registro do membro com status: pending
        │
        ▼
Contador de usos do link é decrementado
(se atingir 0, o link é desativado automaticamente)
        │
        ▼
Secretário e Pastor recebem notificação:
"Novo cadastro pendente: [Nome] solicitou ser membro."
        │
        ▼
Secretário acessa panel/members e vê o membro
com badge "Pendente" e botão "Aprovar cadastro"
        │
   ┌────┴────┐
   ▼         ▼
Aprova     Recusa (com motivo)
   │         │
   ▼         ▼
Status:    Registro
ativo      permanece
           como inativo
           no histórico
```

### 7.7 Tela de confirmação para o usuário

Após enviar o formulário com sucesso, o usuário vê:

```
✅ Cadastro enviado com sucesso!

Suas informações foram recebidas e estão aguardando
aprovação da liderança de [Nome da Igreja].

Em breve você receberá uma confirmação.
```

### 7.8 Gestão dos links gerados

O Secretário pode visualizar todos os links gerados em `panel/members` → aba "Convites":

| Coluna | Conteúdo |
|---|---|
| Link | URL encurtada |
| Nota | Identificação interna |
| Criado por | Nome do secretário/pastor |
| Validade | Data de expiração |
| Usos | Utilizados / Total (ex: 3/10) |
| Status | Ativo / Expirado / Esgotado |
| Ações | Copiar / Desativar |

O Secretário pode **desativar** um link manualmente antes do prazo — o link para de funcionar imediatamente.

---

## 8. Regras de Integridade

### 8.1 Nunca excluir — sempre inativar

Registros de membros nunca são excluídos fisicamente do banco. Toda remoção é uma inativação lógica com motivo e histórico completo.

### 8.2 Campos sensíveis com acesso restrito

Os seguintes campos são visíveis **apenas para Secretário e Administrador**:
- Endereço completo
- Data de nascimento completa (demais perfis veem apenas dia e mês)
- Notas pastorais
- Histórico de inativações e motivos

### 8.3 Auditoria

Toda ação sobre o cadastro de membro é registrada no `AuditLog`:

| Ação | Registrado |
|---|---|
| Membro criado manualmente | ✅ com `created_by_id` |
| Membro criado via Convite | ✅ com `invite_token` |
| Membro editado | ✅ com snapshot antes/depois |
| Membro inativado | ✅ com motivo |
| Membro reativado | ✅ com motivo |
| Cadastro via convite aprovado | ✅ com `approved_by_id` |
| Link de convite gerado | ✅ com configurações |
| Link de convite desativado | ✅ |

### 8.4 Isolamento multi-tenant

- Membros pertencem à church do usuário logado (`church_id`)
- `church_id` é preenchido automaticamente — nunca exposto como campo editável
- Nenhum usuário vê membros de outra church
- O formulário público via link valida o `church_id` criptografado no token antes de exibir qualquer dado

---

## 9. Modelagem Rails

### 9.1 Migration — campos adicionais ao schema existente

```ruby
class AddMissingFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    # Dados pessoais
    add_column :users, :gender,         :integer  # enum: male, female, undisclosed
    add_column :users, :marital_status, :integer  # enum: single, married, divorced, widowed

    # Endereço (via tabela addresses já existente — garantir FK)
    # users.address_id já existe no schema

    # Dados eclesiásticos
    add_column :users, :baptized,        :boolean, null: false, default: false
    add_column :users, :baptism_date,    :date
    add_column :users, :joined_at,       :date
    add_column :users, :position,        :string   # cargo: diácono, presbítero, etc.
    add_column :users, :origin_church,   :string
    add_column :users, :presented,       :boolean, null: false, default: false
    add_column :users, :presented_at,    :date
    add_column :users, :pastoral_notes,  :text

    # Inativação
    add_column :users, :inactivation_reason, :string
    add_column :users, :inactivated_by_id,   :bigint
    add_column :users, :inactivated_at,      :datetime

    add_index :users, :baptized
    add_index :users, :joined_at
    add_index :users, :gender
    add_foreign_key :users, :users, column: :inactivated_by_id
  end
end
```

### 9.2 Migration — Convites de Membro

```ruby
class CreateMemberInvites < ActiveRecord::Migration[8.0]
  def change
    create_table :member_invites do |t|
      t.references :church,      null: false, foreign_key: true
      t.references :created_by,  null: false,
                   foreign_key: { to_table: :users }
      t.string     :token,       null: false
      t.string     :note
      t.integer    :max_uses,    null: false, default: 1
      t.integer    :uses_count,  null: false, default: 0
      t.datetime   :expires_at,  null: false
      t.integer    :status,      null: false, default: 0
      t.timestamps
    end

    add_index :member_invites, :token,  unique: true
    add_index :member_invites, :status
    add_index :member_invites, :expires_at

    # enum :status, { active: 0, expired: 1, exhausted: 2, deactivated: 3 }
  end
end
```

### 9.3 Model — `MemberInvite`

```ruby
# app/models/member_invite.rb
class MemberInvite < ApplicationRecord
  belongs_to :church
  belongs_to :created_by, class_name: "User"

  enum :status, {
    active:      0,
    expired:     1,
    exhausted:   2,
    deactivated: 3
  }

  before_create :generate_token

  scope :usable, -> {
    active
      .where("expires_at > ?", Time.current)
      .where("uses_count < max_uses")
  }

  def usable?
    active? && expires_at > Time.current && uses_count < max_uses
  end

  def use!
    increment!(:uses_count)
    update!(status: :exhausted) if uses_count >= max_uses
  end

  def deactivate!
    update!(status: :deactivated)
  end

  def remaining_uses
    max_uses - uses_count
  end

  private

  def generate_token
    self.token = loop do
      candidate = SecureRandom.urlsafe_base64(16)
      break candidate unless MemberInvite.exists?(token: candidate)
    end
  end
end
```

---

## 10. Funcionalidades Futuras

| Funcionalidade | Descrição |
|---|---|
| **Status: Falecido** | Terceiro estado para registrar óbito — membro sai das listagens ativas mas mantém todo o histórico |
| **Status: Transferido** | Fluxo formal de transferência com carta de recomendação integrada |
| **Carteirinha digital** | Geração de carteirinha em PDF com foto, nome, cargo e QR Code para identificação |
| **Histórico de cargos** | Linha do tempo completa de todos os cargos que o membro ocupou |
| **Importação em lote** | Upload de planilha CSV/Excel para cadastrar múltiplos membros de uma vez |
| **Módulo de Presença** | Controle de frequência nos cultos — base para alertas de membros ausentes |

---

## 11. Glossário

| Termo | Definição |
|---|---|
| **Membro ativo** | Membro com `status: ativo` — participa da congregação |
| **Membro inativo** | Membro com `status: inativo` — afastado; mantido no histórico |
| **Membro pendente** | Membro cadastrado via Convite aguardando aprovação do Secretário |
| **Convite de Membro** | Funcionalidade que gera um link temporário para auto-cadastro de novos membros |
| **Token** | Identificador único e criptografado do link de convite — nunca sequencial |
| **Soft delete** | Remoção lógica — o registro permanece no banco com `status: inativo` |
| **Campos sensíveis** | Endereço, data de nascimento completa e notas pastorais — visíveis apenas para Secretário e Admin |
| **joined_at** | Data de ingresso formal do membro na congregação |
| **Cargo** | Título eclesiástico do membro (Diácono, Presbítero, Obreiro...) — diferente do role do sistema |
| **Role** | Perfil de acesso ao sistema (secretário, líder, membro...) — diferente do cargo eclesiástico |
| **AuditLog** | Tabela de rastreabilidade de todas as ações executadas no sistema |
| **church_id** | Identificador da congregação — garante isolamento de dados entre igrejas |

---

*Ekklesia — Documento interno · Versão 1.0 · Julho 2026*