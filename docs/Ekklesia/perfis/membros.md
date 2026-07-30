# Ekklesia — Regras de Negócio
## Módulo Membros

> **Versão 1.0 · Julho 2026**
> Documento interno — uso restrito à equipe de produto

---

## Sumário

1. [Visão Geral](#1-visão-geral)
2. [Cadastro de Membro](#2-cadastro-de-membro)
3. [Ciclo de Vida do Membro](#3-ciclo-de-vida-do-membro)
4. [Acesso ao Sistema por Perfil](#4-acesso-ao-sistema-por-perfil)
5. [Perfis e Responsabilidades](#5-perfis-e-responsabilidades)
6. [Cargos e Promoção](#6-cargos-e-promoção)
7. [Transferência entre Congregações](#7-transferência-entre-congregações)
8. [Carta de Recomendação](#8-carta-de-recomendação)
9. [Caixa de Departamento](#9-caixa-de-departamento)
10. [Regras de Segurança e Integridade](#10-regras-de-segurança-e-integridade)
11. [Modelagem (Ruby on Rails)](#11-modelagem-ruby-on-rails)
12. [Glossário](#12-glossário)

---

## 1. Visão Geral

**Membro** é toda pessoa formalmente vinculada a uma congregação no sistema Ekklesia. Os membros compõem o corpo da igreja e são a base de todos os outros módulos — escalas, departamentos, acolhimento, aniversariantes e financeiro operam sobre os dados de membros.

**Separação fundamental entre dois conceitos:**

| Conceito | Definição |
|---|---|
| **Membro** | Pessoa vinculada à congregação — pode ou não ter acesso ao sistema |
| **Usuário** | Conta de acesso ao sistema — sempre ligada a um membro, mas nem todo membro é usuário |

> Um membro sem departamento é apenas um **registro** no sistema — não possui login nem acesso. O acesso ao sistema é concedido quando o membro recebe um perfil (role) pelo secretário ou administrador.

---

## 2. Cadastro de Membro

### 2.1 Quem pode cadastrar

| Ação | Quem pode |
|---|---|
| Criar membro | Secretário local, Secretário sede, Administrador |
| Editar membro | Secretário local, Secretário sede, Administrador |
| Inativar membro | Secretário local, Secretário sede, Administrador (com motivo obrigatório) |
| Excluir fisicamente | ❌ Ninguém — nunca permitido |

### 2.2 Campos do cadastro

**Dados pessoais — obrigatórios**

| Campo | Tipo | Observação |
|---|---|---|
| `nome_completo` | `string` | Mínimo 3 caracteres |
| `data_nascimento` | `date` | Base para o módulo de Aniversariantes |
| `sexo` | `enum` | `masculino`, `feminino` |
| `estado_civil` | `enum` | `solteiro`, `casado`, `divorciado`, `viuvo` |
| `status` | `enum` | `ativo`, `inativo` — padrão: `ativo` |

**Dados pessoais — opcionais**

| Campo | Tipo | Observação |
|---|---|---|
| `foto` | `string` | URL do avatar |
| `telefone` | `string` | Máscara `(DD) 9XXXX-XXXX` |
| `whatsapp` | `string` | Máscara `(DD) 9XXXX-XXXX` |
| `email` | `string` | Usado para convite de acesso ao sistema |
| `profissao` | `string` | — |
| `naturalidade` | `string` | Cidade e estado de origem |

**Endereço — obrigatório**

| Campo | Tipo |
|---|---|
| `cep` | `string` |
| `logradouro` | `string` |
| `numero` | `string` |
| `complemento` | `string` (opcional) |
| `bairro` | `string` |
| `cidade` | `string` |
| `estado` | `string` |

**Dados eclesiásticos — opcionais**

| Campo | Tipo | Observação |
|---|---|---|
| `batizado` | `boolean` | Base para métricas do dashboard do pastor |
| `data_batismo` | `date` | Obrigatório se `batizado = true` |
| `data_ingresso` | `date` | Data de entrada na congregação — base para "tempo de casa" |
| `cargo_atual` | `string` | Ex: diácono, presbítero, líder — atualizado pelo administrador |
| `congregacao_origem` | `string` | Preenchido em caso de transferência de outra congregação |
| `apresentado` | `boolean` | Se já foi apresentado à congregação pelo pastor |
| `data_apresentacao` | `date` | Preenchido quando `apresentado = true` |
| `observacao` | `text` | Anotações pastorais — visível apenas para admin e secretário |

**Vínculo institucional — preenchido automaticamente**

| Campo | Tipo | Observação |
|---|---|---|
| `institution_id` | `uuid` | Congregação à qual o membro pertence |
| `tenant_id` | `uuid` | Ministério/tenant — isolamento multi-tenant |
| `cadastrado_por_id` | `uuid` | FK → `users` — quem criou o registro |

### 2.3 Validações

- `nome_completo`, `data_nascimento`, `sexo`, `estado_civil` e endereço completo são obrigatórios
- `data_batismo` é obrigatória quando `batizado = true`
- `data_apresentacao` é obrigatória quando `apresentado = true`
- `email` deve ser único por tenant (usado para convite de acesso)
- Não é possível cadastrar dois membros com o mesmo `nome_completo` + `data_nascimento` na mesma `institution_id` — sistema exibe alerta de possível duplicidade (não bloqueante)

---

## 3. Ciclo de Vida do Membro

### 3.1 Estados disponíveis (escopo atual)

```
ativo ──────────────────────────► inativo
  ▲                                  │
  └── reativação (secretário/admin) ─┘
```

| Status | Descrição |
|---|---|
| `ativo` | Membro presente e participante da congregação |
| `inativo` | Membro afastado, desligado ou sem participação — mantido no histórico |

> **Estados futuros previstos:** `transferido`, `falecido`, `suspenso` — a serem especificados em versão posterior.

### 3.2 Regras de transição

**Ativo → Inativo:**
- Executado pelo secretário ou administrador
- Motivo de inativação é **obrigatório**
- O membro inativo perde acesso ao sistema automaticamente
- O registro permanece no banco — nunca é excluído
- Departamentos e escalas onde o membro estava vinculado recebem alerta para substituição

**Inativo → Ativo:**
- Executado pelo secretário ou administrador
- Sistema registra a reativação no `AuditLog` com data e responsável
- O acesso ao sistema **não é restaurado automaticamente** — deve ser concedido novamente pelo secretário

### 3.3 Nunca deletar, sempre inativar

Registros de membros **nunca são excluídos fisicamente** do banco de dados. Toda remoção é uma inativação lógica com histórico completo. Essa regra é absoluta e não pode ser alterada por nenhum perfil, incluindo o master.

---

## 4. Acesso ao Sistema por Perfil

Nem todo membro tem acesso ao sistema. O acesso depende do perfil (role) atribuído:

| Perfil (role) | Tem acesso ao sistema | Observação |
|---|---|---|
| `administrador` | ✅ | Pastor — acesso máximo da instituição |
| `co_pastor` | ✅ | Permissões definidas pelo pastor |
| `secretario_sede` | ✅ | Acesso a todo o campo do tenant |
| `secretario_local` | ✅ | Acesso à própria congregação |
| `tesoureiro` | ✅ | Módulo financeiro + leitura de membros/eventos |
| `almoxarifado` | ✅ | Acesso restrito — ver seção 5.6 |
| `regente` | ✅ | Escalas + visualização de membros e eventos |
| `lider` | ✅ | Gestão do próprio departamento |
| `acolhimento` | ✅ | Módulo de acolhimento + dashboard do dia |
| `membro_cargo` | ✅ Limitado | Apenas visualiza seu(s) departamento(s) |
| `membro` | ❌ | Apenas registro — sem acesso ao sistema |

> **Regra:** membro sem departamento = sem acesso. O acesso é concedido pelo secretário ao atribuir um perfil ao membro.

---

## 5. Perfis e Responsabilidades

### 5.1 Administrador (Pastor)

Camada máxima de autoridade da instituição. Supervisiona, autoriza e é notificado sobre tudo que acontece na congregação. Documentação completa: `ekklesia_pastor_regras_negocio.md`.

**Acesso resumido:**
- Visualiza todos os módulos da própria instituição
- Cria eventos como rascunho (secretário aprova)
- Nomeia líderes de departamentos
- Define permissões do co-pastor
- Recebe alertas pastorais (aniversariantes, pedidos de oração, membros ausentes)
- Gerencia agenda pessoal de compromissos

### 5.2 Co-Pastor

Perfil de confiança delegada — permissões definidas inteiramente pelo pastor via matriz de toggles nas Configurações. Documentação completa: `ekklesia_pastor_regras_negocio.md` — seção 12.

### 5.3 Secretário

Braço operacional do pastor. Documentação completa: `ekklesia_secretario_regras_negocio.md`.

**Acesso resumido:**

| Secretário Local | Secretário Sede |
|---|---|
| CRUD de membros da própria congregação | CRUD de membros de todo o campo |
| CRUD de eventos, departamentos, escalas | Idem + compartilhamento entre filhas |
| Aprovar eventos de líderes e pastor | Idem + transferências entre congregações |
| Gerenciar usuários da própria congregação | Gerenciar usuários de qualquer congregação |
| Gerar carta de recomendação | Gerar + emitir credenciais oficiais |
| ❌ Criar congregações filhas | ✅ Criar congregações filhas |

### 5.4 Tesoureiro

Responsável pela gestão financeira da instituição. Documentação completa: `ekklesia_tesoureiro_regras_negocio.md`.

**Acesso resumido:**
- CRUD completo no módulo Financeiro (entradas, saídas, contas, relatórios)
- Visualização de membros (somente leitura — para vincular dízimos)
- Visualização de eventos (somente leitura — para associar ofertas)
- Sem acesso a departamentos, escalas, formulários ou configurações

### 5.5 Líder

Responsável pelo próprio departamento. Documentação completa: a ser gerada em `ekklesia_lider_regras_negocio.md`.

**Acesso resumido:**
- Visualiza e convida membros para o próprio departamento
- Cria e edita escalas do próprio departamento
- Cria eventos como rascunho (secretário aprova)
- Gerencia o caixa do próprio departamento (ver seção 9)
- Visualiza aniversariantes dos membros do departamento
- Visualiza calendário geral (somente leitura)
- **Não pode:** criar departamentos, acessar membros fora do departamento, acessar financeiro geral, acessar configurações

### 5.6 Almoxarifado

Perfil responsável pela gestão de materiais, limpeza e suprimentos da instituição.

**Acesso ao sistema:**

| Módulo | Acesso |
|---|---|
| Dashboard próprio | ✅ Solicitações pendentes e estoque |
| Solicitações de compra | ✅ Criar e acompanhar |
| Estoque / Inventário | ✅ Visualizar e atualizar |
| Financeiro | ❌ (apenas o tesoureiro aprova as compras) |
| Membros | ❌ |
| Departamentos | ❌ |
| Escalas | ❌ |
| Configurações | ❌ |

**Fluxo de solicitação de compra:**

```
Almoxarifado cria solicitação de compra
        │
        ▼
Tesoureiro recebe notificação
        │
   ┌────┴────┐
   ▼         ▼
Aprova     Recusa (com motivo)
   │         │
   ▼         ▼
Compra     Almoxarifado
autorizada é notificado
```

> **Nota:** o módulo de Estoque/Almoxarifado é novo e requer especificação própria em documento separado (`ekklesia_almoxarifado_regras_negocio.md`). As permissões acima são o escopo mínimo acordado para o perfil.

### 5.7 Regente

Responsável pela gestão musical e de escalas do departamento de louvor/música. Documentação completa: a ser gerada em `ekklesia_regente_regras_negocio.md`.

**Acesso resumido:**
- Cria e edita escalas do próprio departamento
- Visualiza membros do próprio departamento
- Visualiza eventos e calendário (somente leitura)
- **Não pode:** criar formulários, adicionar novos membros ao departamento, acessar financeiro, acessar configurações

### 5.8 Acolhimento (Recepcionista)

Responsável pelo registro de visitantes durante os cultos. Documentação completa: `ekklesia_acolhimento_regras_negocio.md`.

**Acesso resumido:**
- Dashboard do dia (métricas de visitantes e pedidos de oração)
- Registrar e visualizar visitas do dia
- Registrar pedidos de oração
- Histórico de visitas (somente leitura)

### 5.9 Membro com Cargo (`membro_cargo`)

Membro vinculado a um ou mais departamentos, com acesso limitado ao sistema.

**Acesso:**
- Visualiza o(s) departamento(s) ao qual pertence
- Visualiza a própria escala
- Visualiza o calendário de eventos
- Visualiza aniversariantes do próprio departamento
- **Não pode:** criar, editar ou excluir nada no sistema

### 5.10 Membro sem Cargo (`membro`)

Membro registrado no sistema mas sem vínculo com nenhum departamento.

- **Sem acesso ao sistema** — apenas registro
- Aparece nas listagens do secretário e administrador
- Pode ser convidado para um departamento pelo líder
- Ao aceitar o convite e ser vinculado a um departamento, recebe automaticamente o role `membro_cargo`

---

## 6. Cargos e Promoção

### 6.1 Cargos disponíveis

Os cargos são os títulos eclesiásticos do membro dentro da congregação. São diferentes dos perfis (roles) do sistema.

| Cargo | Descrição |
|---|---|
| Obreiro | Cargo inicial de serviço na igreja |
| Diácono | Cargo de serviço e liderança intermediária |
| Presbítero | Cargo de liderança sênior |
| Líder de Departamento | Responsável por um departamento específico |
| Tesoureiro | Responsável pelo financeiro |
| Secretário | Responsável administrativo |
| Pastor | Líder principal da congregação |

> Cargos são campos de texto livre no cadastro do membro — a lista acima é o padrão sugerido, mas o secretário pode registrar qualquer cargo conforme a estrutura da denominação.

### 6.2 Quem promove

- **Nomeação de líder de departamento:** executada pelo Administrador (pastor)
- **Demais cargos:** registrados pelo Secretário no cadastro do membro
- Toda alteração de cargo é registrada no `AuditLog` com cargo anterior, cargo novo, data e responsável

### 6.3 Credencial oficial

Emitida exclusivamente pelo **Secretário Sede** para cargos de pastor, presbítero, diácono, auxiliar e missionário. Documentação: `ekklesia_secretario_regras_negocio.md` — seção 10.

---

## 7. Transferência entre Congregações

### 7.1 Fluxo

| Etapa | Responsável | Status |
|---|---|---|
| Secretário local solicita transferência | Secretário Local | `pendente` |
| Sistema notifica secretário sede | Sistema | — |
| Secretário sede aprova ou recusa | Secretário Sede | `aprovada` / `recusada` |
| Membro muda de `institution_id` | Sistema | `concluida` |
| Histórico de transferência registrado | Sistema | — |

### 7.2 Regras

- O membro transferido mantém todo o histórico de cargos e departamentos anteriores
- O campo `congregacao_origem` é preenchido automaticamente com o nome da congregação anterior
- O membro transferido perde automaticamente o vínculo com os departamentos da congregação de origem
- O líder dos departamentos afetados é notificado da saída do membro
- A transferência entre tenants diferentes **não é permitida** — membros só transitam dentro do mesmo tenant

---

## 8. Carta de Recomendação

### 8.1 O que é

Documento oficial emitido pelo secretário que atesta o vínculo e a conduta de um membro, utilizado quando o membro vai se congregar temporária ou permanentemente em outra igreja.

### 8.2 Quem emite

- **Secretário local** e **Secretário sede** — ambos podem emitir
- O **Administrador (pastor)** pode solicitar a geração mas não emite diretamente

### 8.3 Campos da carta

| Campo | Descrição |
|---|---|
| Nome completo do membro | Gerado automaticamente do cadastro |
| Data de ingresso na congregação | Gerada automaticamente do cadastro |
| Cargo atual | Gerado automaticamente do cadastro |
| Nome da congregação de origem | Gerado automaticamente da instituição |
| Nome e cargo do emitente | Gerado automaticamente do secretário logado |
| Data de emissão | `Date.current` automático |
| Validade | 90 dias a partir da emissão (configurável pelo master) |
| Número de registro | Gerado automaticamente — único por tenant |
| Destinatário (opcional) | Nome da igreja ou ministério de destino |
| Observações (opcional) | Campo livre do secretário |

### 8.4 Fluxo de emissão

```
Secretário acessa o cadastro do membro
        │
        ▼
Clica em "Emitir carta de recomendação"
        │
        ▼
Modal de confirmação com preview da carta
        │
        ▼
Confirma → sistema gera PDF + registra no AuditLog
        │
        ▼
Download do PDF disponível para impressão/envio
```

### 8.5 Recebimento de carta de outra congregação

Quando um membro chega com carta de recomendação de outra congregação:

- O secretário registra o **recebimento** no cadastro do novo membro com campos: congregação de origem, número da carta e data
- O sistema **não valida** a carta automaticamente (validação manual pelo secretário)
- O campo `congregacao_origem` é preenchido com os dados da carta

### 8.6 Regras

- Uma carta por membro por período — o sistema alerta se já existe carta ativa para o membro
- Carta não pode ser editada após geração — apenas uma nova carta pode ser emitida
- Toda emissão é registrada no `AuditLog` com: membro, emitente, data e número de registro
- O PDF segue o template padrão da instituição (logo, cor primária e nome definidos nas Configurações)

---

## 9. Caixa de Departamento

### 9.1 O que é

Cada departamento pode ter um **caixa próprio**, gerenciado pelo líder do departamento. É um módulo financeiro simplificado e **separado** do financeiro geral da instituição (gerenciado pelo tesoureiro).

### 9.2 Quem gerencia

- **Líder do departamento:** cria e registra movimentações do caixa do próprio departamento
- **Tesoureiro:** não acessa o caixa de departamento diretamente, mas **aprova** solicitações de verba
- **Administrador e Secretário:** visualizam o resumo de todos os caixas de departamento

### 9.3 Fluxo de solicitação de verba

```
Líder cria solicitação de verba ao tesoureiro
        │
        ▼
Tesoureiro recebe notificação
        │
   ┌────┴────┐
   ▼         ▼
Aprova     Recusa (com motivo)
   │         │
   ▼         ▼
Verba      Líder é notificado
creditada  e pode revisar
no caixa
do departamento
```

### 9.4 O que o líder pode registrar no caixa do departamento

- Entradas: verba recebida da tesouraria, arrecadações próprias do departamento
- Saídas: despesas do departamento (materiais, eventos internos)
- Comprovante anexado em cada lançamento (foto ou PDF)

### 9.5 Regras

- O caixa do departamento **não substitui** o financeiro da instituição — são sistemas paralelos
- O líder **não acessa** o financeiro geral da instituição
- Toda movimentação do caixa é registrada no `AuditLog`
- Lançamentos não podem ser excluídos — apenas estornados (mesmo princípio do financeiro geral)
- O administrador e o secretário podem visualizar o saldo e o extrato de qualquer caixa de departamento

---

## 10. Regras de Segurança e Integridade

### 10.1 Regras absolutas

- Membros **nunca são excluídos fisicamente** — apenas inativados com motivo obrigatório
- `institution_id` e `tenant_id` são preenchidos automaticamente — nunca expostos como campo editável
- Nenhum usuário enxerga membros de outro tenant
- Secretário local enxerga apenas membros da própria congregação
- Secretário sede enxerga membros de todas as congregações do campo (mesmo tenant)

### 10.2 Dados sensíveis

Os seguintes campos são visíveis apenas para administrador e secretário — nunca para líderes ou membros:

- `observacao` (anotações pastorais)
- `data_nascimento` completa (líderes veem apenas dia e mês — para aniversário)
- Endereço completo
- Histórico de inativações e motivos

### 10.3 Auditoria

Toda ação sobre o cadastro de membro é registrada no `AuditLog`:

- Criação, edição e inativação
- Alteração de cargo
- Emissão de carta de recomendação
- Nomeação como líder de departamento
- Transferência entre congregações

---

## 11. Modelagem (Ruby on Rails)

### Migration

```ruby
class CreateMembros < ActiveRecord::Migration[8.0]
  def change
    create_table :membros, id: :uuid do |t|
      t.references :institution,    null: false, foreign_key: true, type: :uuid
      t.uuid        :tenant_id,     null: false
      t.references :cadastrado_por, null: false,
                   foreign_key: { to_table: :users }, type: :uuid

      # Dados pessoais
      t.string   :nome_completo,       null: false
      t.date     :data_nascimento,     null: false
      t.integer  :sexo,                null: false
      t.integer  :estado_civil,        null: false
      t.integer  :status,              null: false, default: 0
      t.string   :foto
      t.string   :telefone
      t.string   :whatsapp
      t.string   :email
      t.string   :profissao
      t.string   :naturalidade

      # Endereço
      t.string   :cep,                 null: false
      t.string   :logradouro,          null: false
      t.string   :numero,              null: false
      t.string   :complemento
      t.string   :bairro,              null: false
      t.string   :cidade,              null: false
      t.string   :estado,              null: false

      # Dados eclesiásticos
      t.boolean  :batizado,            null: false, default: false
      t.date     :data_batismo
      t.date     :data_ingresso
      t.string   :cargo_atual
      t.string   :congregacao_origem
      t.boolean  :apresentado,         null: false, default: false
      t.date     :data_apresentacao
      t.text     :observacao

      # Inativação
      t.datetime :inactivated_at
      t.uuid     :inactivated_by_id
      t.string   :inactivation_reason

      t.timestamps
    end

    add_index :membros, :tenant_id
    add_index :membros, :status
    add_index :membros, :data_nascimento
    add_index :membros, [:nome_completo, :data_nascimento, :institution_id],
              name: "index_membros_on_nome_data_institution"
  end
end
```

### Model

```ruby
# app/models/membro.rb
class Membro < ApplicationRecord
  belongs_to :institution
  belongs_to :cadastrado_por, class_name: "User"

  has_many :membro_departamentos, dependent: :restrict_with_error
  has_many :departamentos, through: :membro_departamentos
  has_many :cartas_recomendacao, dependent: :restrict_with_error

  enum :status, {
    ativo:   0,
    inativo: 1
  }

  enum :sexo, {
    masculino: 0,
    feminino:  1
  }

  enum :estado_civil, {
    solteiro:   0,
    casado:     1,
    divorciado: 2,
    viuvo:      3
  }

  # Isolamento multi-tenant
  scope :do_tenant, ->(user) {
    where(institution_id: user.institution_id, tenant_id: user.tenant_id)
  }

  scope :ativos,   -> { where(status: :ativo) }
  scope :inativos, -> { where(status: :inativo) }
  scope :batizados, -> { where(batizado: true) }

  # Aniversariantes do mês atual
  scope :aniversariantes_do_mes, ->(mes = Date.current.month) {
    where("EXTRACT(MONTH FROM data_nascimento) = ?", mes)
  }

  # Aniversariantes da semana atual
  scope :aniversariantes_da_semana, -> {
    hoje      = Date.current
    em_7_dias = hoje + 7.days
    where(
      "TO_CHAR(data_nascimento, 'MM-DD') BETWEEN ? AND ?",
      hoje.strftime("%m-%d"),
      em_7_dias.strftime("%m-%d")
    )
  }

  validates :nome_completo,   presence: true, length: { minimum: 3 }
  validates :data_nascimento, presence: true
  validates :sexo,            presence: true
  validates :estado_civil,    presence: true
  validates :cep,             presence: true
  validates :logradouro,      presence: true
  validates :numero,          presence: true
  validates :bairro,          presence: true
  validates :cidade,          presence: true
  validates :estado,          presence: true
  validates :data_batismo,    presence: true, if: :batizado?
  validates :data_apresentacao, presence: true, if: :apresentado?
  validates :inactivation_reason, presence: true, if: :inativo?

  validate :data_batismo_nao_pode_ser_futura
  validate :data_nascimento_nao_pode_ser_futura

  def inativar!(motivo:, por:)
    update!(
      status:              :inativo,
      inactivation_reason: motivo,
      inactivated_by_id:   por.id,
      inactivated_at:      Time.current
    )
  end

  def reativar!(por:)
    update!(
      status:            :ativo,
      inactivated_at:    nil,
      inactivated_by_id: nil,
      inactivation_reason: nil
    )
  end

  private

  def data_batismo_nao_pode_ser_futura
    return unless data_batismo.present?
    errors.add(:data_batismo, "não pode ser uma data futura") if data_batismo > Date.current
  end

  def data_nascimento_nao_pode_ser_futura
    return unless data_nascimento.present?
    errors.add(:data_nascimento, "não pode ser uma data futura") if data_nascimento > Date.current
  end
end
```

---

## 12. Glossário

| Termo | Definição |
|---|---|
| **Membro** | Pessoa formalmente vinculada a uma congregação no sistema Ekklesia |
| **Usuário** | Conta de acesso ao sistema — sempre ligada a um membro |
| **Role / Perfil** | Nível de acesso do usuário no sistema (administrador, secretário, líder, etc.) |
| **Cargo** | Título eclesiástico do membro na congregação (diácono, presbítero, etc.) — diferente do role |
| **Ativo** | Membro presente e participante da congregação |
| **Inativo** | Membro afastado ou desligado — mantido no histórico, sem acesso ao sistema |
| **Apresentado** | Membro que já foi apresentado formalmente à congregação pelo pastor |
| **Carta de Recomendação** | Documento oficial emitido pelo secretário que atesta o vínculo do membro |
| **Caixa de Departamento** | Módulo financeiro simplificado gerenciado pelo líder, separado do financeiro geral |
| **Transferência** | Movimento de um membro entre congregações do mesmo tenant |
| **Inativação** | Remoção lógica com histórico — nunca exclusão física |
| **AuditLog** | Tabela de rastreabilidade de todas as ações executadas no sistema |
| **Tenant** | Ministério/Igreja contratante do Ekklesia — isolamento total entre tenants |
| **institution_id** | Identificador da congregação específica dentro de um tenant |

---

## Funcionalidades Futuras _(Fora do escopo atual)_

| Funcionalidade | Descrição |
|---|---|
| **Status: Transferido** | Status específico para membros em processo de transferência formal |
| **Status: Falecido** | Registro de óbito com data — membro sai das listagens ativas mas mantém histórico |
| **Status: Suspenso** | Suspensão disciplinar temporária com prazo e motivo |
| **Módulo de Presença** | Registro de frequência nos cultos — base para alertas de membros ausentes |
| **Histórico de cargos** | Linha do tempo de todos os cargos que o membro ocupou |
| **Foto de documento** | Upload de RG/CPF vinculado ao cadastro |
| **Módulo Almoxarifado** | Especificação completa do perfil e fluxo de estoque e solicitações de compra |

---

*Ekklesia — Documento interno · Versão 1.0 · Julho 2026*