# Ekklesia — Acesso Interno
## Perfil T.I. · Desenvolvedor da Equipe Ekklesia

> **Versão 1.1 · Julho 2026**
> Documento estritamente interno — exclusivo da equipe de engenharia da Ekklesia
> ⚠️ Este documento NÃO descreve um perfil de usuário do produto. Descreve o acesso interno da equipe técnica ao sistema em produção.

---

## Sumário

1. [Visão Geral](#1-visão-geral)
2. [O que é e o que não é o perfil T.I.](#2-o-que-é-e-o-que-não-é-o-perfil-ti)
3. [Posição na Hierarquia](#3-posição-na-hierarquia)
4. [Permissões Globais](#4-permissões-globais)
5. [Painel Global de Igrejas](#5-painel-global-de-igrejas)
6. [Acesso a uma Church Específica](#6-acesso-a-uma-church-específica)
7. [Menu de Simulação de Perfis e Departamentos](#7-menu-de-simulação-de-perfis-e-departamentos)
8. [Auditoria Reforçada](#8-auditoria-reforçada)
9. [Dashboard do T.I.](#9-dashboard-do-ti)
10. [Regras de Segurança e Integridade](#10-regras-de-segurança-e-integridade)
11. [Modelagem Rails](#11-modelagem-rails)
12. [Glossário](#12-glossário)

---

## 1. Visão Geral

O perfil **T.I.** é o acesso de desenvolvimento e suporte técnico da **equipe interna da Ekklesia**. É o equivalente ao acesso de staff que empresas como iFood, Stripe ou Linear concedem aos seus desenvolvedores — invisível para os clientes, operado internamente para manutenção, investigação de bugs e suporte técnico em produção.

Assim como um desenvolvedor do iFood consegue acessar o painel de qualquer restaurante cadastrado para investigar um problema sem que o restaurante precise saber, o T.I. da Ekklesia consegue acessar qualquer church cadastrada para investigar e corrigir problemas técnicos.

**O T.I. é responsável por:**
- Investigar e corrigir bugs reportados por qualquer church em produção
- Simular qualquer perfil ou departamento para reproduzir comportamentos inesperados
- Gerenciar todas as churches cadastradas no sistema (criar, editar, inativar)
- Monitorar a saúde global da plataforma (erros, logs, métricas)
- Gerenciar outros usuários T.I. da equipe Ekklesia

**Analogia direta com o mercado:**

| Empresa SaaS | Equivalente ao T.I. da Ekklesia |
|---|---|
| iFood | Desenvolvedor que acessa painel de qualquer restaurante |
| Stripe | Engineer que acessa dashboard de qualquer merchant |
| Linear | Staff que acessa workspace de qualquer empresa cliente |
| Ekklesia | T.I. que acessa sistema de qualquer church cadastrada |

---

## 2. O que é e o que não é o perfil T.I.

### 2.1 O que é

- Um **acesso interno da equipe Ekklesia** — não é um perfil do produto vendido às igrejas
- Um **perfil de staff técnico** — criado e gerenciado exclusivamente pela equipe de engenharia
- Uma **ferramenta de suporte e debug** em produção
- **Invisível para os usuários das churches** — não aparece em nenhuma tela, listagem ou configuração acessível pelas igrejas

### 2.2 O que NÃO é

- Um perfil que pode ser criado pelo `master` ou pelo `administrador` de uma church
- Um perfil concedido a membros, pastores ou qualquer usuário da igreja
- Um substituto do `master` ou do `administrador` para operações rotineiras
- Um perfil que aparece no enum de roles visível às churches

### 2.3 Como é provisionado

O acesso T.I. não passa pelo fluxo normal de criação de usuários do produto. Ele é provisionado diretamente pela equipe de engenharia via:

```bash
# Rake task exclusiva do ambiente de produção/staging
# Executada via terminal pelo tech lead ou CTO
rails ti:create EMAIL="dev@ekklesia.com.br" NAME="Nome do Dev"
```

Nunca via interface do sistema. Nunca por um usuário comum.

---

## 3. Posição na Hierarquia

```
╔══════════════════════════════════════════════╗
║  T.I. (Equipe interna Ekklesia)              ║
║  — fora da hierarquia de qualquer tenant —   ║
╚══════════════════════════════════════════════╝
                      │
                      ▼
         [Todos os tenants / churches]
                      │
         ┌────────────┴────────────┐
         ▼                         ▼
   Tenant A                   Tenant B
   └── master                 └── master
       └── administrador          └── administrador
           ├── co_pastor              ├── co_pastor
           ├── secretario             ├── secretario
           ├── tesoureiro             ├── tesoureiro
           ├── lider                  ├── lider
           ├── regente                ├── regente
           ├── acolhimento            ├── acolhimento
           ├── zelador                ├── zelador
           ├── membro_cargo           ├── membro_cargo
           └── membro                 └── membro
```

O T.I. está **completamente fora** da hierarquia de qualquer tenant. Ele acessa qualquer nível da árvore sem depender de permissão de nenhum usuário interno das churches.

### 3.1 Diferença entre T.I., Master e Administrador

| Característica | T.I. | Master | Administrador (Pastor) |
|---|---|---|---|
| Pertence a | Equipe Ekklesia | Igreja contratante | Igreja contratante |
| Visível no produto | ❌ Nunca | ✅ | ✅ |
| Provisionado por | Equipe de engenharia | T.I. ou outro master | Master ou secretário |
| Escopo | Global — todos os tenants | Apenas o próprio tenant | Apenas a própria church |
| Acesso a outros tenants | ✅ | ❌ | ❌ |
| Simula perfis | ✅ Com operação completa | ❌ | ❌ |
| Aparece no AuditLog | ✅ Com flag `performed_by_ti` | ✅ | ✅ |
| Pode ser criado via UI | ❌ Apenas via rake task | ✅ Via UI | ✅ Via UI |

---

## 4. Permissões Globais

O T.I. tem acesso irrestrito a **todos os módulos de todas as churches**. Não há `church_id` limitando seu escopo.

| Módulo | Acesso |
|---|---|
| Painel global de igrejas | ✅ CRUD — todas as churches |
| Dashboard de qualquer church | ✅ |
| Membros de qualquer church | ✅ CRUD |
| Departamentos de qualquer church | ✅ CRUD |
| Eventos de qualquer church | ✅ CRUD + aprovar/recusar |
| Escalas de qualquer church | ✅ CRUD |
| Formulários de qualquer church | ✅ CRUD |
| Acolhimento de qualquer church | ✅ CRUD |
| Financeiro de qualquer church | ✅ CRUD |
| Estoque / Almoxarifado de qualquer church | ✅ CRUD |
| Configurações de qualquer church | ✅ Total |
| Permissões de módulos de qualquer church | ✅ |
| AuditLog de qualquer church | ✅ Somente leitura — nunca editável |
| Gerenciar usuários T.I. | ✅ Apenas via rake task / console |
| Simulação de perfis e departamentos | ✅ Com operação completa |

---

## 5. Painel Global de Igrejas

Tela exclusiva do T.I. — primeiro módulo exibido após o login. Não existe em nenhuma outra sessão do produto.

### 5.1 O que exibe

| Coluna | Descrição |
|---|---|
| Nome da church | Com badge de tipo: Sede / Congregação / Ponto de Pregação |
| Tenant / Ministério | Nome do ministério contratante |
| Plano | Free / Básico / Premium (badge colorido) |
| Status | Ativa / Inativa (badge) |
| Total de usuários | Usuários ativos na church |
| Último acesso | Data do último login de qualquer usuário da church |
| Ações | Acessar / Editar / Inativar |

### 5.2 Filtros disponíveis

- Busca por nome da church ou do ministério
- Filtro por tipo (`sede`, `congregacao`, `ponto_pregacao`)
- Filtro por plano
- Filtro por status (ativa / inativa)
- Filtro por data de criação (date range)
- Ordenação por: nome, data de criação, último acesso, total de usuários

### 5.3 Ações disponíveis

- **Acessar** — entra no contexto daquela church (ver seção 6)
- **Editar** — edita dados da church (nome, plano, status, configurações)
- **Inativar** — inativa a church com motivo obrigatório
- **Reativar** — reativa uma church inativa
- **Criar nova church** — cria uma nova church/tenant no sistema

---

## 6. Acesso a uma Church Específica

### 6.1 Como funciona

Ao clicar em **"Acessar"** no painel global, o T.I. entra no contexto daquela church. A interface carrega os dados e os menus daquela church — como se o T.I. fosse um usuário local com acesso máximo, mas com indicadores visuais claros de que é um acesso de staff.

**Indicadores visuais obrigatórios durante o acesso:**
- Banner fixo no topo: `⚙ Modo T.I. — Acessando: [Nome da Church]` com fundo âmbar
- Badge com o nome da church no header ao lado do logo
- Esses indicadores nunca desaparecem durante a sessão — o T.I. nunca pode confundir um acesso real com um acesso de suporte

### 6.2 O que o T.I. pode fazer dentro de uma church

- Tudo que o `master` e o `administrador` podem fazer naquela church
- Aprovar ou recusar eventos pendentes
- Editar configurações, permissões e usuários
- Visualizar e exportar o `AuditLog` completo da church
- Executar qualquer operação necessária para investigar ou corrigir o problema reportado

### 6.3 Saindo do contexto da church

- Botão **"Sair da church"** sempre visível no banner
- Ao sair, o T.I. retorna ao Painel Global de Igrejas
- Todas as ações executadas durante a sessão ficam registradas no `AuditLog` da church com `performed_by_ti: true`

### 6.4 Acesso silencioso

- O administrador (pastor) da church **não é notificado** quando o T.I. acessa
- O acesso não requer justificativa prévia
- O pastor pode identificar ações do T.I. consultando o `AuditLog` da própria church — as ações aparecem com o campo `performed_by_ti: true`

---

## 7. Menu de Simulação de Perfis e Departamentos

### 7.1 O que é

Ferramenta exclusiva do T.I. que permite **operar o sistema como se fosse outro perfil de usuário ou membro de um departamento específico**. Essencial para:

- Reproduzir bugs reportados por usuários ("o líder não consegue salvar a escala")
- Validar comportamentos de interface e permissão após deploys
- Testar fluxos completos sem precisar criar usuários reais de teste

### 7.2 Como acessar

Dentro do contexto de uma church, o menu lateral exibe o item **"Simulação"** com ícone de alternância — exclusivo do T.I., completamente invisível para todos os outros perfis.

### 7.3 Opções de simulação

**Por perfil (role):**

| Perfil simulado | Interface resultante |
|---|---|
| `administrador` | Menus e permissões do pastor |
| `co_pastor` | Menus conforme permissões configuradas pelo pastor da church |
| `secretario_local` | Menus com escopo da própria congregação |
| `secretario_sede` | Menus com visão de campo |
| `tesoureiro` | Financeiro + leitura de membros/eventos |
| `lider` | Apenas o departamento selecionado |
| `regente` | Escalas + visualização |
| `acolhimento` | Dashboard do dia + registro de visitas |
| `zelador` | Estoque + solicitações de compra |
| `membro_cargo` | Apenas visualização do departamento |
| `membro` | Tela de "sem permissão" |

**Por departamento** (quando simular `lider` ou `membro_cargo`):
- Dropdown com todos os departamentos ativos da church
- O sistema filtra os dados exatamente como faria para um líder real daquele departamento

### 7.4 Comportamento durante a simulação

- Banner adicional abaixo do banner de modo T.I.: `👤 Simulando: [Perfil] — [Departamento se aplicável]`
- O sistema aplica **exatamente** as mesmas políticas Pundit do perfil simulado — incluindo restrições de módulos, filtros de `church_id` e escopos de tenant
- O T.I. pode criar, editar e excluir dados como se fosse aquele perfil — para reproduzir bugs que dependem de operação real
- Todas as ações durante simulação: registradas no `AuditLog` com `performed_by_ti: true` + `simulated_role` + `simulation: true`
- Botão **"Encerrar simulação"** sempre visível — retorna ao modo T.I. completo dentro da church

### 7.5 O que a simulação NÃO faz

- **Não envia notificações reais** — qualquer notificação gerada durante a simulação é marcada com `simulation: true` e bloqueada antes do envio
- **Não cria uma sessão real** do perfil simulado — é sempre o T.I. operando, com as permissões restritas ao perfil escolhido
- **Não altera o `current_user`** da sessão — apenas aplica as políticas de permissão do perfil simulado

---

## 8. Auditoria Reforçada

Por ter acesso global e irrestrito, toda ação do T.I. é rastreada com campos adicionais no `AuditLog`. Esses campos permitem que qualquer church identifique quando e o que um membro da equipe Ekklesia fez em seus dados.

### 8.1 Campos extras no AuditLog para ações do T.I.

| Campo | Tipo | Descrição |
|---|---|---|
| `performed_by_ti` | `boolean` | `true` para todas as ações do T.I. |
| `ti_user_id` | `bigint` | ID do desenvolvedor T.I. que executou |
| `simulated_role` | `string` | Role simulado durante a ação (se aplicável) |
| `simulated_departament_id` | `bigint` | Departamento simulado (se aplicável) |
| `simulation` | `boolean` | `true` se executado durante sessão de simulação |
| `accessed_church_id` | `bigint` | Church acessada — diferente da church do T.I. (nula) |

### 8.2 Quem pode ver as ações do T.I. no AuditLog

| Perfil | O que vê |
|---|---|
| T.I. | AuditLog global — todas as churches, todas as ações |
| Administrador (pastor) | AuditLog da própria church — ações do T.I. identificadas por `performed_by_ti` |
| Secretário | AuditLog da própria church — incluindo ações do T.I. |
| Demais perfis | ❌ Sem acesso ao AuditLog |

---

## 9. Dashboard do T.I.

Tela inicial após login do T.I. — visão global do estado da plataforma. Não existe em nenhuma outra sessão do produto.

### 9.1 Cards de resumo global

| Card | O que exibe |
|---|---|
| Total de churches | Quantidade total de churches ativas no sistema |
| Total de tenants | Ministérios/tenants cadastrados |
| Total de usuários | Usuários ativos em todas as churches |
| Novos cadastros (mês) | Churches criadas nos últimos 30 dias |
| Churches inativas | Churches com `status: inativo` |
| Simulações ativas | Sessões de simulação em andamento (múltiplos T.I.) |

### 9.2 Histórico de acessos do T.I.

- Últimas 10 churches acessadas pelo T.I. logado
- Acesso rápido: botão **"Acessar novamente"**
- Data e hora do último acesso a cada church

### 9.3 Alertas da plataforma

- Churches com plano expirado ou próximo do vencimento (D-7, D-1)
- Usuários bloqueados por excesso de tentativas de login
- Erros críticos recentes (integração futura com serviço de log — ex: Sentry, Datadog)

---

## 10. Regras de Segurança e Integridade

### 10.1 Restrições absolutas do perfil T.I.

Mesmo sendo o perfil mais alto da plataforma, o T.I. tem restrições intencionais e não negociáveis:

- **Nunca exclui fisicamente** nenhum registro — a regra "nunca deletar, sempre inativar" se aplica ao T.I. sem exceção
- **Nunca edita o AuditLog** — registros de auditoria são imutáveis para qualquer perfil, incluindo o T.I.
- **Nunca acessa senhas** — `encrypted_password` nunca é exposto, nem via console, para o T.I.
- **Nunca envia notificações reais** durante simulações — todas marcadas com `simulation: true` e bloqueadas
- **Nunca cria outro T.I. via UI** — apenas via rake task no terminal de produção

### 10.2 Provisionamento e gestão de usuários T.I.

- Criação: exclusivamente via rake task pelo tech lead ou CTO — nunca pela interface do produto
- O role `ti` **nunca aparece** no enum de roles exibido nas telas de configuração de usuários das churches
- Todo T.I. criado é registrado em tabela separada (`ti_users`) com: nome, email, quem criou e quando
- Desativação: via rake task — o acesso é revogado imediatamente, sessões ativas são encerradas

### 10.3 Auditoria das próprias ações

- Toda ação do T.I. é rastreada: login, logout, acesso a churches, início e encerramento de simulações
- O T.I. **pode ler** seu próprio AuditLog — **nunca pode editá-lo**
- Nenhuma ação do T.I. pode ser apagada do AuditLog por nenhum perfil

---

## 11. Modelagem Rails

### 11.1 Separação do role T.I. dos roles do produto

O role `ti` existe no enum de `users` mas **nunca é exposto via UI do produto**. É filtrado em todas as listagens de seleção de roles acessíveis pelas churches.

```ruby
# app/models/user.rb
enum :role, {
  admin:     0,
  secretary: 1,
  member:    2,
  treasurer: 3,
  leader:    4,
  regente:   5,
  reception: 6,
  co_pastor: 7,
  warehouse: 8,
  ti:        9   # nunca exibido nas seleções do produto
}

# Roles visíveis para as churches (excluindo ti)
PRODUCT_ROLES = roles.keys.excluding("ti").freeze
```

### 11.2 Migration — Campos extras no AuditLog

```ruby
class AddTiFieldsToAuditLogs < ActiveRecord::Migration[8.0]
  def change
    add_column :audit_logs, :performed_by_ti,         :boolean,
               default: false, null: false
    add_column :audit_logs, :ti_user_id,               :bigint
    add_column :audit_logs, :simulated_role,           :string
    add_column :audit_logs, :simulated_departament_id, :bigint
    add_column :audit_logs, :simulation,               :boolean,
               default: false, null: false
    add_column :audit_logs, :accessed_church_id,       :bigint

    add_index :audit_logs, :performed_by_ti
    add_index :audit_logs, :ti_user_id
    add_index :audit_logs, :simulation

    add_foreign_key :audit_logs, :users,
                    column: :ti_user_id
    add_foreign_key :audit_logs, :churches,
                    column: :accessed_church_id
    add_foreign_key :audit_logs, :departaments,
                    column: :simulated_departament_id
  end
end
```

### 11.3 Rake task — Provisionamento de T.I.

```ruby
# lib/tasks/ti.rake
namespace :ti do
  desc "Cria um usuário T.I. da equipe Ekklesia"
  task :create, [:email, :name] => :environment do |_, args|
    email = args[:email] || ENV["EMAIL"]
    name  = args[:name]  || ENV["NAME"]

    abort "EMAIL obrigatório" unless email.present?
    abort "NAME obrigatório"  unless name.present?

    password = SecureRandom.hex(16)

    user = User.create!(
      name:                  name,
      email:                 email,
      password:              password,
      password_confirmation: password,
      role:                  :ti,
      church_id:             nil,   # T.I. não pertence a nenhuma church
      status:                :ativo
    )

    puts "✅ T.I. criado: #{user.email}"
    puts "🔑 Senha temporária: #{password}"
    puts "⚠️  Solicite troca de senha no primeiro login."
  end

  desc "Desativa um usuário T.I."
  task :revoke, [:email] => :environment do |_, args|
    user = User.find_by!(email: args[:email], role: :ti)
    user.update!(status: :inativo, deleted_at: Time.current)
    puts "🚫 Acesso T.I. revogado para: #{user.email}"
  end
end
```

### 11.4 Concern — `TiAccessible`

```ruby
# app/controllers/concerns/ti_accessible.rb
module TiAccessible
  extend ActiveSupport::Concern

  included do
    before_action :set_ti_context
    before_action :block_notifications_in_simulation
  end

  private

  def set_ti_context
    return unless current_user&.ti?

    # Church acessada via painel global
    if params[:church_id].present?
      @current_church = Church.find(params[:church_id])
      session[:ti_church_id] = @current_church.id
    elsif session[:ti_church_id].present?
      @current_church = Church.find(session[:ti_church_id])
    end

    # Perfil sendo simulado
    @simulated_role           = session[:simulated_role]
    @simulated_departament_id = session[:simulated_departament_id]
  end

  def ti_simulating?
    current_user&.ti? && session[:simulated_role].present?
  end

  # Role efetivo para aplicar nas policies durante simulação
  def effective_role
    ti_simulating? ? @simulated_role : current_user.role
  end

  # Bloqueia envio de notificações durante simulação
  def block_notifications_in_simulation
    RequestStore.store[:simulation] = ti_simulating?
  end
end
```

### 11.5 Policy base — escopo global para T.I.

```ruby
# app/policies/application_policy.rb
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user   = user
    @record = record
  end

  def ti_access?
    user.ti?
  end

  def index?   = ti_access? || false
  def show?    = ti_access? || false
  def create?  = ti_access? || false
  def update?  = ti_access? || false
  def destroy? = false  # ninguém deleta fisicamente — nem o T.I.

  class Scope
    def initialize(user, scope)
      @user  = user
      @scope = scope
    end

    def resolve
      # T.I. enxerga todos os registros sem filtro de church_id
      return scope.all if user.ti?
      # Demais perfis: isolamento por church_id
      scope.where(church_id: user.church_id)
    end

    private

    attr_reader :user, :scope
  end
end
```

---

## 12. Glossário

| Termo | Definição |
|---|---|
| **T.I.** | Desenvolvedor interno da equipe Ekklesia com acesso global à plataforma em produção |
| **Staff / Internal access** | Padrão de mercado SaaS para acesso da equipe técnica aos dados dos clientes |
| **Painel Global** | Tela exclusiva do T.I. com listagem e acesso a todas as churches do sistema |
| **Modo T.I.** | Estado visual do sistema quando o T.I. está operando dentro de uma church específica |
| **Simulação** | Modo em que o T.I. opera como outro perfil — para debug e QA |
| **Acesso silencioso** | Acesso do T.I. a uma church sem notificar o administrador local |
| **`performed_by_ti`** | Flag no AuditLog que identifica ações executadas por um desenvolvedor T.I. |
| **`simulation: true`** | Flag que marca ações e notificações geradas durante sessão de simulação — bloqueia envio |
| **Banner de modo T.I.** | Indicador visual fixo com fundo âmbar exibido quando o T.I. acessa uma church |
| **Rake task** | Comando de terminal Rails usado para provisionar e revogar acessos T.I. — nunca via UI |
| **PRODUCT_ROLES** | Constante que lista os roles visíveis às churches — exclui o role `ti` |
| **AuditLog** | Tabela de rastreabilidade de todas as ações — imutável para qualquer perfil |
| **Tenant** | Ministério/Igreja contratante — conjunto de churches sob um mesmo contrato |

---

*Ekklesia — Documento interno · Versão 1.1 · Julho 2026*
*Acesso restrito à equipe de engenharia. Não compartilhar com clientes ou usuários das churches.*