# Ekklesia — Padrões de Desenvolvimento
## Design Patterns & Arquitetura de Código

> **Versão 1.1 · Julho 2026**
> Owner: Equipe de Engenharia · Revisão a cada sprint de arquitetura
> Este documento é a referência oficial para decisões de design de código no projeto Ekklesia.
> Em caso de dúvida entre uma abordagem e outra, este documento tem precedência.

---

## Sumário

1. [Stack e Contexto](#1-stack-e-contexto)
2. [Controllers](#2-controllers)
3. [Models](#3-models)
4. [Services](#4-services)
5. [Query Objects](#5-query-objects)
6. [Jobs (Solid Queue)](#6-jobs-solid-queue)
7. [Policies (Pundit)](#7-policies-pundit)
8. [ViewComponents](#8-viewcomponents)
9. [Turbo Streams e Hotwire](#9-turbo-streams-e-hotwire)
10. [Concerns](#10-concerns)
11. [Testes](#11-testes)
12. [Nomenclatura e Estrutura de Arquivos](#12-nomenclatura-e-estrutura-de-arquivos)
13. [i18n](#13-i18n)
14. [Migrations](#14-migrations)
15. [Idioma do Desenvolvimento](#15-idioma-do-desenvolvimento)
16. [Anti-padrões — O que nunca fazer](#16-anti-padrões--o-que-nunca-fazer)

---

## 1. Stack e Contexto

O Ekklesia é uma aplicação **Rails 8 fullstack com Hotwire** — não é uma API JSON com front-end separado. Esse contexto muda fundamentalmente algumas decisões de arquitetura:

| Tecnologia | Uso |
|---|---|
| **Ruby on Rails 8** | Framework principal — MVC fullstack |
| **PostgreSQL** | Banco de dados principal |
| **Hotwire** (Turbo + Stimulus) | Reatividade no front — sem SPA, sem React |
| **Pundit** | Autorização baseada em policies |
| **Devise** | Autenticação |
| **Solid Queue** | Background jobs (nativo Rails 8 — sem Sidekiq) |
| **Solid Cache** | Cache (nativo Rails 8) |
| **ViewComponent** | Componentes de UI reutilizáveis |
| **dry-monads** | Resultado tipado de Services (`Success` / `Failure`) |

> **Consequência direta:** não usamos Serializers JSON (Blueprinter, AMS, etc.) nas telas do produto. A saída do servidor é HTML renderizado via ERB + ViewComponents. Serializers só entram em endpoints de API explicitamente criados para integrações externas.

### 1.1 Fluxo padrão de uma requisição

```
Requisição HTTP
      │
      ▼
ApplicationController (autenticação Devise + autorização Pundit)
      │
      ▼
Controller action (strong params → chama Service)
      │
      ▼
Service (orquestra: valida, persiste, enfileira jobs)
      │         │
      ▼         ▼
   Model     Job (Solid Queue)
   (persist) (side effects assíncronos)
      │
      ▼
Turbo Stream ou render de ViewComponent
```

---

## 2. Controllers

### 2.1 Responsabilidade

O controller é um **despachante** — recebe a requisição, delega ao Service e renderiza o resultado. Nenhuma lógica de negócio vive aqui.

### 2.2 Regra de ouro — ação em uma linha

O corpo de cada ação deve ser legível em até 5 linhas. Se passou disso, a lógica foi para o lugar errado.

```ruby
# ✅ CORRETO
class Members::InvitesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_departament

  def create
    result = Departaments::InviteMemberService.call(
      departament: @departament,
      invited_by:  current_user,
      params:      invite_params
    )

    if result.success?
      redirect_to departament_path(@departament),
                  notice: t(".success")
    else
      render :new, status: :unprocessable_entity,
             locals: { errors: result.failure }
    end
  end

  private

  def set_departament
    @departament = policy_scope(Departament)
                   .find(params[:departament_id])
    authorize @departament, :invite_member?
  end

  def invite_params
    params.require(:invite).permit(:user_id)
  end
end
```

```ruby
# ❌ ERRADO — lógica de negócio no controller
def create
  user = User.find(params[:user_id])
  return redirect_to root_path if user.already_in_departament?(@departament)

  membership = Memberchip.new(user: user, departament: @departament)
  if membership.save
    UserMailer.invite_notification(user).deliver_later
    redirect_to departament_path(@departament)
  else
    render :new
  end
end
```

### 2.3 Callbacks (`before_action`)

Use `before_action` **apenas** para:

- Autenticação (`authenticate_user!`)
- Autorização (`authorize @record`)
- Busca simples por ID (`@church = Church.find(params[:id])`)

**Nunca** para lógica de negócio, transformação de dados ou chamadas a services.

### 2.4 Ações RESTful — respeite as 7 ações

Mantenha-se nas 7 ações padrão do Rails: `index`, `show`, `new`, `create`, `edit`, `update`, `destroy`.

Para ações customizadas, crie um controller aninhado dedicado:

```ruby
# ❌ ERRADO — ação customizada no controller principal
class UsersController < ApplicationController
  def activate
  def deactivate
  def resend_invite
end

# ✅ CORRETO — controllers focados e RESTful
class Users::ActivationsController < ApplicationController
  def create  # ativa o usuário
  def destroy # desativa o usuário
end

class Users::InvitesController < ApplicationController
  def create  # reenvia convite
end
```

### 2.5 Tratamento de erros centralizado

Use `rescue_from` no `ApplicationController` para erros comuns. Nunca `begin/rescue` espalhado nas ações.

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  rescue_from ActiveRecord::RecordNotFound,  with: :not_found
  rescue_from Pundit::NotAuthorizedError,    with: :forbidden

  private

  def not_found
    render file: "public/404.html", status: :not_found
  end

  def forbidden
    redirect_to root_path, alert: t("errors.not_authorized")
  end
end
```

### 2.6 Múltiplas variáveis de instância — use Facade

Se a view precisar de mais de 3 variáveis de instância, agrupe-as em um Presenter/Facade:

```ruby
# ❌ EVITAR
def show
  @church    = Church.find(params[:id])
  @members   = @church.users.active
  @stats     = ChurchStatsQuery.new(@church).call
  @schedules = @church.schedules.published
  @events    = @church.events.upcoming
end

# ✅ CORRETO
def show
  @church    = Church.find(params[:id])
  @presenter = Churches::DashboardPresenter.new(@church, current_user)
end
```

---

## 3. Models

### 3.1 Responsabilidade

O model é a **representação do domínio e guardião da integridade dos dados**. Ele sabe o que é válido estruturalmente, expõe métodos semânticos de mudança de estado e define escopos de consulta.

### 3.2 O que pertence ao Model

```ruby
# app/models/user.rb
class User < ApplicationRecord
  # 1. Associations
  belongs_to :church
  has_many   :memberchips, dependent: :restrict_with_error
  has_many   :departaments, through: :memberchips

  # 2. Enums
  enum :role,   { admin: 0, secretary: 1, member: 2, leader: 4 }
  enum :status, { ativo: 0, inativo: 1 }

  # 3. Validações estruturais
  validates :name,  presence: true, length: { minimum: 3 }
  validates :email, presence: true, uniqueness: { scope: :church_id },
                    format: { with: URI::MailTo::EMAIL_REGEXP }

  # 4. Callbacks apenas para sanitização de dados
  before_validation :normalize_phone

  # 5. Scopes puros e reutilizáveis
  scope :ativos,        -> { where(status: :ativo) }
  scope :do_church,     ->(church_id) { where(church_id: church_id) }
  scope :aniversariantes_do_mes, ->(mes = Date.current.month) {
    where("EXTRACT(MONTH FROM birth_date) = ?", mes)
  }

  # 6. Métodos semânticos de mudança de estado
  def inativar!(motivo:, por:)
    update!(
      status:              :inativo,
      inactivation_reason: motivo,
      inactivated_by_id:   por.id,
      inactivated_at:      Time.current
    )
  end

  def reativar!
    update!(status: :ativo, inactivated_at: nil,
            inactivated_by_id: nil, inactivation_reason: nil)
  end

  private

  def normalize_phone
    self.phone = phone.gsub(/\D/, "") if phone.present?
  end
end
```

### 3.3 O que NUNCA pertence ao Model

```ruby
# ❌ NUNCA — side effects fora do banco
after_create :send_welcome_email       # mova para o Service
after_update :sync_with_external_crm   # mova para um Job
after_commit :invalidate_cache         # use o Service ou um Concern de cache

# ❌ NUNCA — lógica de negócio complexa
def self.process_monthly_report
  # 40 linhas de lógica aqui → mova para um Service
end

# ❌ NUNCA — queries complexas inline
scope :with_active_schedules, -> {
  joins(:schedules)
    .where(schedules: { status: :published })
    .group("users.id")
    .having("COUNT(schedules.id) > 3")
    .order("users.name")
}
# → mova para um Query Object
```

---

## 4. Services

### 4.1 Responsabilidade

O Service é o **orquestrador da lógica de negócio**. Ele coordena Models, Jobs e dependências externas para executar uma única ação de negócio com começo, meio e fim claros.

### 4.2 Base Service

Todos os services herdam de `BaseService`:

```ruby
# app/services/base_service.rb
class BaseService
  include Dry::Monads[:result]

  # Açúcar sintático: permite chamar Service.call(...) em vez de Service.new(...).call
  def self.call(...)
    new(...).call
  end
end
```

### 4.3 Estrutura padrão de um Service

```ruby
# app/services/departaments/invite_member_service.rb
module Departaments
  class InviteMemberService < BaseService
    def initialize(departament:, invited_by:, params:)
      @departament = departament
      @invited_by  = invited_by
      @params      = params
    end

    def call
      return Failure(:already_member) if already_member?
      return Failure(:pending_invite) if pending_invite_exists?

      invite = create_invite!
      notify_approvers(invite)

      Success(invite)
    end

    private

    attr_reader :departament, :invited_by, :params

    def already_member?
      Memberchip.exists?(
        user_id: params[:user_id],
        departament: departament
      )
    end

    def pending_invite_exists?
      DepartmentInvite.pending.exists?(
        user_id:       params[:user_id],
        departament:   departament
      )
    end

    def create_invite!
      DepartmentInvite.create!(
        departament:   departament,
        user_id:       params[:user_id],
        invited_by:    invited_by,
        status:        :pending_approval,
        expires_at:    30.days.from_now
      )
    end

    def notify_approvers(invite)
      Notifications::DepartmentInviteJob.perform_later(invite.id)
    end
  end
end
```

### 4.4 Retorno padronizado com dry-monads

Todo Service retorna `Success(data)` ou `Failure(reason)`. O controller lê o resultado via `.success?` e `.failure`.

```ruby
# No controller — leitura do resultado
result = Departaments::InviteMemberService.call(...)

case result
in Success(invite)
  redirect_to departament_path(@departament), notice: t(".success")
in Failure(:already_member)
  redirect_to departament_path(@departament), alert: t(".already_member")
in Failure(:pending_invite)
  redirect_to departament_path(@departament), alert: t(".pending_invite")
end
```

### 4.5 Fail-fast — valide antes de persistir

```ruby
def call
  # ✅ Valide tudo ANTES de tocar no banco
  return Failure(:user_not_found)    unless target_user
  return Failure(:unauthorized)      unless can_invite?
  return Failure(:already_member)    if already_member?
  return Failure(:pending_invite)    if pending_invite_exists?

  # Só persiste se tudo estiver validado
  invite = create_invite!
  Success(invite)
end
```

### 4.6 Injeção de dependências

Passe dependências externas como argumentos com valor padrão — facilita mocks nos testes:

```ruby
# ✅ Testável
def initialize(church:, mailer: ChurchMailer, payment_gateway: StripeClient.new)
  @church           = church
  @mailer           = mailer
  @payment_gateway  = payment_gateway
end

# No teste:
result = Subscriptions::ChargeService.call(
  church:          church,
  payment_gateway: FakeStripeClient.new # mock sem chamar API real
)
```

---

## 5. Query Objects

### 5.1 Responsabilidade

Query Objects encapsulam **consultas SQL complexas** que não pertencem ao Model. Use quando a query envolver joins, subqueries, aggregações ou parâmetros dinâmicos de filtro.

### 5.2 Estrutura padrão

```ruby
# app/queries/users/birthday_query.rb
module Users
  class BirthdayQuery
    def initialize(church:, scope: User.all)
      @church = church
      @scope  = scope
    end

    def this_week
      @scope
        .do_church(@church.id)
        .ativos
        .where(
          "TO_CHAR(birth_date, 'MM-DD') BETWEEN ? AND ?",
          Date.current.strftime("%m-%d"),
          7.days.from_now.strftime("%m-%d")
        )
        .order(
          Arel.sql("TO_CHAR(birth_date, 'MM-DD')")
        )
    end

    def this_month
      @scope
        .do_church(@church.id)
        .ativos
        .aniversariantes_do_mes
        .order(Arel.sql("EXTRACT(DAY FROM birth_date)"))
    end
  end
end

# Uso no Service ou Controller:
Users::BirthdayQuery.new(church: current_church).this_week
```

### 5.3 Quando usar Query Object vs. Scope no Model

| Situação | Onde fica |
|---|---|
| Filtro simples por um campo | Scope no Model |
| Filtro com parâmetros opcionais | Query Object |
| JOIN com outra tabela | Query Object |
| Aggregação (COUNT, SUM, GROUP BY) | Query Object |
| Subquery ou CTE | Query Object |
| Reutilizado em mais de 3 contextos diferentes | Query Object |

---

## 6. Jobs (Solid Queue)

### 6.1 Responsabilidade

Jobs são **executores assíncronos de side effects** — ações que não precisam bloquear a resposta ao usuário (envio de e-mail, notificação, sincronização externa).

### 6.2 Filas disponíveis

O Ekklesia define 3 filas por prioridade:

```ruby
# config/queue.yml (Solid Queue)
queues:
  - critical   # redefinir senha, convites urgentes, autenticação
  - default    # fluxos normais do app
  - low        # relatórios, exportações, notificações em massa
```

### 6.3 Estrutura padrão de um Job

```ruby
# app/jobs/notifications/department_invite_job.rb
module Notifications
  class DepartmentInviteJob < ApplicationJob
    queue_as :default

    # Erros de rede: tenta novamente com backoff exponencial
    retry_on  Net::OpenTimeout, Timeout::Error,
              attempts: 5, wait: :exponentially_longer

    # Registro deletado antes de rodar: descarta sem erro
    discard_on ActiveRecord::RecordNotFound

    def perform(invite_id)
      invite = DepartmentInvite.find(invite_id)

      # Job limpo: delega lógica para o Service
      Notifications::SendDepartmentInviteService.call(invite: invite)
    end
  end
end
```

### 6.4 Regras obrigatórias

**Passe apenas IDs — nunca objetos ActiveRecord:**

```ruby
# ❌ ERRADO — objeto pode mudar ou ser deletado antes do Job rodar
Notifications::DepartmentInviteJob.perform_later(invite)

# ✅ CORRETO
Notifications::DepartmentInviteJob.perform_later(invite.id)
```

**Jobs devem ser idempotentes:**

```ruby
def perform(invite_id)
  invite = DepartmentInvite.find(invite_id)

  # Idempotência: não envia se já foi notificado
  return if invite.notified_at.present?

  Notifications::SendDepartmentInviteService.call(invite: invite)
  invite.update_columns(notified_at: Time.current)
end
```

**Nunca enfileirar dentro de uma transaction:**

```ruby
# ❌ ERRADO — se a transaction sofrer rollback, o job já foi para a fila
ActiveRecord::Base.transaction do
  invite.save!
  Notifications::DepartmentInviteJob.perform_later(invite.id) # PROBLEMA
end

# ✅ CORRETO — enfileirar no Service após fechar a transaction
def create_invite_and_notify!
  invite = DepartmentInvite.create!(...)      # transaction fecha aqui
  Notifications::DepartmentInviteJob.perform_later(invite.id) # seguro
  invite
end
```

---

## 7. Policies (Pundit)

### 7.1 Responsabilidade

Policies centralizam as **regras de autorização** — quem pode fazer o quê com qual recurso. Nenhuma regra de permissão vive no Controller, Model ou Service.

### 7.2 Estrutura padrão

```ruby
# app/policies/schedule_policy.rb
class SchedulePolicy < ApplicationPolicy
  # T.I. tem acesso global — definido na ApplicationPolicy base
  # Os métodos abaixo definem acesso para os demais perfis

  def index?
    church_member? && (admin? || secretary? || leader_of_departament? || regente?)
  end

  def create?
    church_member? && (admin? || secretary? || leader_of_departament?)
  end

  def update?
    create? && (admin? || secretary? || owns_schedule?)
  end

  def destroy?
    admin? || secretary?
  end

  def publish?
    update?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if user.ti?

      if admin_or_secretary?
        scope.where(church_id: user.church_id)
      else
        # Líderes/regentes veem apenas escalas do próprio departamento
        scope.joins(:departament)
             .where(departaments: { id: user_departament_ids })
      end
    end

    private

    def admin_or_secretary?
      user.admin? || user.secretary?
    end

    def user_departament_ids
      user.memberchips.pluck(:departament_id)
    end
  end

  private

  def church_member?
    user.church_id == record.church_id
  end

  def admin?
    user.admin?
  end

  def secretary?
    user.secretary?
  end

  def regente?
    user.regente?
  end

  def leader_of_departament?
    user.memberchips.leader.exists?(departament_id: record.departament_id)
  end

  def owns_schedule?
    record.departament.memberchips.leader.exists?(user: user)
  end
end
```

### 7.3 Regras de uso

- **Sempre** chame `authorize @record` no controller antes de operar
- **Sempre** use `policy_scope(Model)` em listagens para filtrar o escopo
- **Nunca** coloque `if current_user.admin?` direto na view — use `policy(@record).action?`

```erb
<%# ✅ CORRETO na view %>
<% if policy(@schedule).publish? %>
  <%= link_to "Publicar", publish_schedule_path(@schedule), method: :post %>
<% end %>
```

---

## 8. ViewComponents

### 8.1 Responsabilidade

ViewComponents encapsulam **fragmentos de UI reutilizáveis** com lógica de apresentação isolada. Substituem partials complexas e helpers com lógica embutida.

### 8.2 Quando usar ViewComponent vs. Partial

| Situação | Solução |
|---|---|
| HTML estático simples sem lógica | Partial ERB |
| Componente com lógica de apresentação | ViewComponent |
| Componente reutilizado em 3+ lugares | ViewComponent |
| Componente que precisa de teste unitário | ViewComponent |
| Badge, card, avatar, alert, modal | ViewComponent |

### 8.3 Estrutura padrão

```ruby
# app/components/schedule/status_badge_component.rb
module Schedule
  class StatusBadgeComponent < ViewComponent::Base
    def initialize(schedule:)
      @schedule = schedule
    end

    def call
      content_tag :span, label, class: css_classes
    end

    private

    def label
      I18n.t("schedules.status.#{@schedule.status}")
    end

    def css_classes
      base = "inline-flex items-center px-2 py-1 rounded-full text-xs font-medium"
      color = case @schedule.status
              when "draft"     then "bg-gray-100 text-gray-700"
              when "published" then "bg-green-100 text-green-700"
              else                  "bg-yellow-100 text-yellow-700"
              end
      "#{base} #{color}"
    end
  end
end
```

```erb
<%# Uso na view %>
<%= render Schedule::StatusBadgeComponent.new(schedule: @schedule) %>
```

### 8.4 Nomenclatura

```
app/components/
├── schedule/
│   ├── status_badge_component.rb
│   └── status_badge_component.html.erb
├── member/
│   ├── avatar_component.rb
│   └── card_component.rb
├── shared/
│   ├── alert_component.rb
│   └── empty_state_component.rb
```

---

## 9. Turbo Streams e Hotwire

### 9.1 Contexto

O Ekklesia usa **Hotwire como camada de reatividade** — não React, não Vue, não SPA. Toda atualização de UI acontece via Turbo Frames e Turbo Streams gerados pelo servidor.

### 9.2 Turbo Frame — navegação parcial

Use Turbo Frame para **substituir uma seção da página** sem reload completo:

```erb
<%# app/views/schedules/index.html.erb %>
<%= turbo_frame_tag "schedules-list" do %>
  <%= render @schedules %>
<% end %>

<%# app/views/schedules/_schedule.html.erb %>
<%= turbo_frame_tag dom_id(schedule) do %>
  <div class="card">
    <%= schedule.name %>
    <%= render Schedule::StatusBadgeComponent.new(schedule: schedule) %>
  </div>
<% end %>
```

### 9.3 Turbo Stream — atualização granular pós-ação

Use Turbo Stream para **atualizar múltiplos elementos** após um create/update/destroy:

```ruby
# app/controllers/schedules/assignments_controller.rb
def create
  result = Schedules::AssignMemberService.call(
    entry:  @entry,
    column: @column,
    user:   User.find(params[:user_id])
  )

  if result.success?
    render turbo_stream: [
      turbo_stream.replace(
        "assignment-#{@entry.id}-#{@column.id}",
        partial: "assignment_cell",
        locals:  { assignment: result.value! }
      ),
      turbo_stream.update(
        "conflict-indicator-#{@entry.id}",
        partial: "conflict_indicator",
        locals:  { entry: @entry }
      )
    ]
  else
    render turbo_stream: turbo_stream.update(
      "flash-messages",
      partial: "shared/flash",
      locals:  { type: :error, message: t(".conflict") }
    )
  end
end
```

### 9.4 Stimulus — comportamentos client-side

Use Stimulus para comportamentos JavaScript **mínimos e específicos**: máscaras, toggles, timers. Nunca para lógica de negócio.

```javascript
// app/javascript/controllers/phone_mask_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  format() {
    let value = this.inputTarget.value.replace(/\D/g, "")
    // aplica máscara (DD) 9XXXX-XXXX
    this.inputTarget.value = value.replace(
      /^(\d{2})(\d{5})(\d{4})$/,
      "($1) $2-$3"
    )
  }
}
```

---

## 10. Concerns

### 10.1 Quando usar

Use Concerns para **comportamento compartilhado entre múltiplos models ou controllers** — não como lugar para despejar código que não sabe onde botar.

### 10.2 Regra de uso

Um Concern só existe se for incluído em **pelo menos 2 classes diferentes**. Se é usado em apenas uma, o código pertence à própria classe.

```ruby
# app/models/concerns/church_scoped.rb
# Incluído em: User, Departament, Schedule, Event, WelcomeRecord...
module ChurchScoped
  extend ActiveSupport::Concern

  included do
    belongs_to :church
    validates  :church_id, presence: true

    scope :do_church, ->(church_id) { where(church_id: church_id) }
    scope :do_tenant, ->(church) {
      church_ids = [church.id] + church.churches.pluck(:id)
      where(church_id: church_ids)
    }
  end
end

# app/models/concerns/inactivatable.rb
# Incluído em: User, Departament, Memberchip
module Inactivatable
  extend ActiveSupport::Concern

  included do
    scope :ativos,   -> { where(status: :ativo) }
    scope :inativos, -> { where(status: :inativo) }
  end

  def inativar!(motivo:, por:)
    update!(
      status:              :inativo,
      inactivation_reason: motivo,
      inactivated_by_id:   por.id,
      inactivated_at:      Time.current
    )
  end

  def reativar!
    update!(status: :ativo, inactivated_at: nil,
            inactivated_by_id: nil, inactivation_reason: nil)
  end
end
```

---

## 11. Testes

### 11.1 Stack de testes

| Ferramenta | Uso |
|---|---|
| **RSpec** | Framework de testes |
| **FactoryBot** | Criação de dados de teste |
| **Faker** | Dados aleatórios |
| **Shoulda Matchers** | Matchers para validações e associations |
| **Capybara** | Testes de integração/sistema |

### 11.2 O que testar em cada camada

| Camada | O que testar | Como |
|---|---|---|
| **Model** | Validações, scopes, métodos semânticos | RSpec + Shoulda |
| **Service** | Fluxo completo, casos de sucesso e falha | RSpec — unit |
| **Query Object** | SQL gerado, resultados corretos | RSpec — integração com DB |
| **Policy** | Cada combinação de role × ação | RSpec + Pundit helpers |
| **ViewComponent** | Renderização HTML esperada | RSpec — component spec |
| **Controller** | Roteamento e resposta HTTP | RSpec — request spec |
| **Job** | Enfileiramento e idempotência | RSpec + ActiveJob helpers |
| **Sistema** | Fluxos críticos end-to-end | Capybara |

### 11.3 Exemplo — teste de Service

```ruby
# spec/services/departaments/invite_member_service_spec.rb
RSpec.describe Departaments::InviteMemberService do
  let(:church)      { create(:church) }
  let(:departament) { create(:departament, church: church) }
  let(:invited_by)  { create(:user, :leader, church: church) }
  let(:user)        { create(:user, church: church) }

  subject(:result) do
    described_class.call(
      departament: departament,
      invited_by:  invited_by,
      params:      { user_id: user.id }
    )
  end

  context "quando o convite é válido" do
    it { is_expected.to be_success }
    it { expect { result }.to change(DepartmentInvite, :count).by(1) }
    it { expect { result }.to have_enqueued_job(Notifications::DepartmentInviteJob) }
  end

  context "quando o membro já pertence ao departamento" do
    before { create(:memberchip, user: user, departament: departament) }

    it { is_expected.to be_failure }
    it { expect(result.failure).to eq :already_member }
    it { expect { result }.not_to change(DepartmentInvite, :count) }
  end

  context "quando já existe convite pendente" do
    before { create(:department_invite, :pending, user: user, departament: departament) }

    it { is_expected.to be_failure }
    it { expect(result.failure).to eq :pending_invite }
  end
end
```

### 11.4 Exemplo — teste de Policy

```ruby
# spec/policies/schedule_policy_spec.rb
RSpec.describe SchedulePolicy do
  let(:church)    { create(:church) }
  let(:schedule)  { create(:schedule, church: church) }

  subject { described_class }

  permissions :create? do
    it { is_expected.to permit(create(:user, :admin,     church: church), schedule) }
    it { is_expected.to permit(create(:user, :secretary, church: church), schedule) }
    it { is_expected.not_to permit(create(:user, :member,    church: church), schedule) }
    it { is_expected.not_to permit(create(:user, :treasurer, church: church), schedule) }
  end
end
```

---

## 12. Nomenclatura e Estrutura de Arquivos

### 12.1 Estrutura de diretórios

```
app/
├── components/            # ViewComponents — por domínio
│   ├── schedule/
│   ├── member/
│   └── shared/
├── controllers/           # Controllers RESTful — por domínio
│   ├── members/
│   │   └── invites_controller.rb
│   ├── schedules/
│   │   └── assignments_controller.rb
│   └── application_controller.rb
├── jobs/                  # Jobs Solid Queue — por domínio
│   └── notifications/
│       └── department_invite_job.rb
├── models/
│   ├── concerns/          # Concerns compartilhados
│   │   ├── church_scoped.rb
│   │   └── inactivatable.rb
│   └── user.rb
├── policies/              # Pundit — por resource
│   ├── application_policy.rb
│   └── schedule_policy.rb
├── queries/               # Query Objects — por domínio
│   └── users/
│       └── birthday_query.rb
└── services/              # Services — por domínio + ação
    ├── base_service.rb
    └── departaments/
        ├── invite_member_service.rb
        └── remove_member_service.rb
```

### 12.2 Convenções de nomenclatura

| Tipo | Padrão | Exemplo |
|---|---|---|
| Service | `Dominio::VerbNounService` | `Departaments::InviteMemberService` |
| Query Object | `Dominio::NounQuery` | `Users::BirthdayQuery` |
| Job | `Categoria::NounJob` | `Notifications::DepartmentInviteJob` |
| ViewComponent | `Dominio::NounComponent` | `Schedule::StatusBadgeComponent` |
| Policy | `NounPolicy` | `SchedulePolicy` |
| Concern | adjetivo ou substantivo | `ChurchScoped`, `Inactivatable` |

### 12.3 Idioma do código

| O que | Idioma | Exemplo |
|---|---|---|
| Nomes de classes, métodos, variáveis | **Inglês** | `invite_member`, `church_id` |
| Strings para o usuário (labels, mensagens) | **Português** — via i18n | `t(".success")` |
| Comentários de código | **Português** | `# Valida se o membro já está no departamento` |
| Commits | **Português** | `feat: adiciona fluxo de convite de membro` |
| Nomes de colunas no banco | **snake_case em inglês** | `inactivated_at`, `church_id` |

---

## 13. i18n

### 13.1 Regra principal

**Nenhuma string visível ao usuário** pode estar hardcoded em Ruby ou ERB. Toda string usa `I18n.t()`.

### 13.2 Estrutura de arquivos

```
config/locales/
├── pt-BR.yml              # Strings globais (erros, datas, botões)
├── models/
│   ├── user.pt-BR.yml
│   └── schedule.pt-BR.yml
└── views/
    ├── schedules/
    │   ├── index.pt-BR.yml
    │   └── show.pt-BR.yml
    └── members/
        └── invites/
            └── create.pt-BR.yml
```

### 13.3 Chaves lazy (relativas à view)

Prefira chaves lazy em vez de chaves absolutas — menos digitação e menos acoplamento:

```erb
<%# ✅ Chave lazy — Rails infere o path pela view atual %>
<%= t(".success") %>
<%= t(".already_member") %>

<%# ❌ Chave absoluta — frágil se o arquivo for movido %>
<%= t("members.invites.create.success") %>
```

### 13.4 Enums traduzidos

```yaml
# config/locales/models/user.pt-BR.yml
pt-BR:
  activerecord:
    attributes:
      user:
        role:
          admin:     "Administrador"
          secretary: "Secretário"
          leader:    "Líder"
          member:    "Membro"
        status:
          ativo:   "Ativo"
          inativo: "Inativo"
```

```ruby
# Uso no código
User.human_attribute_name("role.admin") # => "Administrador"
```

---

## 14. Migrations

### 14.1 Regra principal

Toda alteração no banco de dados **obrigatoriamente** passa pelo gerador oficial do Rails:

```bash
rails g migration NomeDaMigration
```

**Nunca** edite o arquivo `schema.rb` diretamente. **Nunca** escreva uma migration do zero sem usar o gerador. O `schema.rb` é gerado automaticamente pelo Rails após rodar as migrations — ele é leitura, não escrita.

### 14.2 Convenção de nomenclatura

O nome da migration deve descrever **o que ela faz** de forma clara e no formato `VerbNounContext`. O Rails usa esse nome para gerar o timestamp e o arquivo.

| Ação | Padrão | Exemplo de comando |
|---|---|---|
| Criar tabela | `CreateNomeDaTabela` | `rails g migration CreateDepartmentInvites` |
| Adicionar coluna | `AddColunaToTabela` | `rails g migration AddStatusToEvents` |
| Remover coluna | `RemoveColunaFromTabela` | `rails g migration RemoveOldFieldFromUsers` |
| Adicionar índice | `AddIndexToTabela` | `rails g migration AddIndexToAuditLogs` |
| Renomear coluna | `RenameColunaNaTabela` | `rails g migration RenameFieldInUsers` |
| Adicionar FK | `AddForeignKeyToTabela` | `rails g migration AddChurchForeignKeyToUsers` |
| Alterar tipo de coluna | `ChangeColunaTipoInTabela` | `rails g migration ChangeAmountTypeInBudgets` |

### 14.3 Rails infere o conteúdo pelo nome

Para adições e remoções, o Rails gera o corpo da migration automaticamente quando o nome segue o padrão `AddXxxToYyy` ou `RemoveXxxFromYyy`:

```bash
# Rails gera add_column automaticamente
rails g migration AddStatusToEvents status:integer

# Rails gera remove_column automaticamente
rails g migration RemoveOldTokenFromUsers old_token:string
```

```ruby
# Gerado automaticamente — só complete os detalhes se necessário
class AddStatusToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :status, :integer, null: false, default: 0
  end
end
```

### 14.4 Estrutura obrigatória de uma migration

```ruby
# ✅ Migration bem escrita
class CreateDepartmentInvites < ActiveRecord::Migration[8.0]
  def change
    create_table :department_invites do |t|
      # 1. Foreign keys primeiro
      t.references :departament,  null: false, foreign_key: true
      t.references :user,         null: false, foreign_key: true
      t.references :invited_by,   null: false,
                   foreign_key: { to_table: :users }

      # 2. Campos de negócio
      t.integer  :status,         null: false, default: 0
      t.string   :rejection_reason
      t.datetime :expires_at,     null: false
      t.datetime :responded_at

      # 3. Campos de FK sem helper references (bigint simples)
      t.bigint   :approved_by_id

      t.timestamps
    end

    # 4. Índices — sempre fora do create_table
    add_index :department_invites, :status
    add_index :department_invites, :expires_at
    add_index :department_invites, [:user_id, :departament_id],
              name: "index_dept_invites_uniqueness", unique: true

    # 5. FKs manuais (quando não foi possível usar foreign_key: true no references)
    add_foreign_key :department_invites, :users, column: :approved_by_id
  end
end
```

### 14.5 Regras obrigatórias de migration

**`null: false` é o padrão** — todo campo deve ter `null: false` por padrão. Se um campo pode ser nulo, é a exceção e precisa ser explicitamente justificada no PR.

```ruby
# ✅ Explícito em todos os campos
t.string  :name,   null: false
t.integer :status, null: false, default: 0
t.string  :notes                            # nullable — aceitável com justificativa
```

**Sempre defina `default`** para campos enum e boolean:

```ruby
t.integer :status,  null: false, default: 0   # enum — default no valor inicial
t.boolean :active,  null: false, default: true # boolean — nunca sem default
```

**Índices são obrigatórios** para:
- Todas as colunas usadas em `WHERE` frequente
- Todas as foreign keys que não usaram `t.references` (que já adiciona o índice)
- Colunas usadas em `ORDER BY` em listagens paginadas

**Constraints no banco para regras críticas:**

```ruby
# Quantidade nunca negativa — garantida no banco, não só no model
execute <<-SQL
  ALTER TABLE stock_items
  ADD CONSTRAINT stock_items_quantity_non_negative
  CHECK (current_quantity >= 0);
SQL
```

**Nunca use `change_column`** para alterar o tipo de uma coluna em produção sem checar compatibilidade. Prefira adicionar a coluna nova, migrar os dados e remover a antiga em migrations separadas.

### 14.6 Fluxo completo de uma migration

```bash
# 1. Gerar a migration
rails g migration AddApprovalFieldsToEvents \
  status:integer approved_by_id:bigint approved_at:datetime rejection_reason:string

# 2. Revisar e completar o arquivo gerado
# (adicionar null:, default:, índices, constraints)

# 3. Rodar localmente
rails db:migrate

# 4. Verificar o schema.rb — confirmar que reflete o esperado
git diff db/schema.rb

# 5. Rodar os testes para garantir que nada quebrou
bundle exec rspec

# 6. Commitar migration E schema.rb juntos no mesmo commit
git add db/migrate/TIMESTAMP_add_approval_fields_to_events.rb db/schema.rb
git commit -m "db: add approval fields to events"
```

### 14.7 Convenção de commit para migrations

Commits de migration seguem o prefixo `db:`:

```
db: create department_invites table
db: add status and approval fields to events
db: add index to audit_logs on church_id and created_at
db: add non-negative constraint to stock_items
```

### 14.8 O que NUNCA fazer em migrations

```ruby
# ❌ NUNCA — referenciar Models dentro de migrations
class MigrateUserRoles < ActiveRecord::Migration[8.0]
  def up
    User.find_each { |u| u.update!(role: 2) }  # Model pode mudar e quebrar migrations antigas
  end
end

# ✅ CORRETO — usar SQL puro
def up
  execute "UPDATE users SET role = 2 WHERE role IS NULL"
end
```

```bash
# ❌ NUNCA — editar schema.rb manualmente
vim db/schema.rb  # proibido

# ❌ NUNCA — criar arquivo de migration sem o gerador
touch db/migrate/20260710_minha_migration.rb  # proibido

# ❌ NUNCA — rodar migration em produção sem testar localmente antes
```

---

## 15. Idioma do Desenvolvimento

### 15.1 Regra central

**Todo o código é escrito em inglês. Todo texto visível ao usuário usa I18n.**

Essa é uma regra sem exceção. Ela garante consistência no código, facilita contribuições da equipe, e mantém os textos da interface centralizados e traduzíveis.

### 15.2 Tabela de referência rápida

| O que | Idioma | Onde fica |
|---|---|---|
| Nomes de classes, módulos | Inglês | `app/models/`, `app/services/`... |
| Nomes de métodos e variáveis | Inglês | Em todo o código Ruby |
| Nomes de colunas e tabelas no banco | Inglês | Migrations + schema.rb |
| Nomes de arquivos e diretórios | Inglês | Toda a estrutura do projeto |
| Rotas (`resources`, `path`) | Inglês | `config/routes.rb` |
| Comentários no código | Português | Dentro dos arquivos `.rb`, `.erb` |
| Mensagens de commit | Português | Git log |
| Textos de interface (labels, botões) | Português — via I18n | `config/locales/` |
| Mensagens de flash (notice, alert) | Português — via I18n | `config/locales/views/` |
| Notificações (e-mail, push, in-app) | Português — via I18n | `config/locales/notifications/` |
| Mensagens de erro de validação | Português — via I18n | `config/locales/models/` |
| Textos de e-mail (mailers) | Português — via I18n | `config/locales/mailers/` |

### 15.3 Código — sempre em inglês

```ruby
# ✅ CORRETO — código em inglês
class DepartmentInvite < ApplicationRecord
  belongs_to :departament
  belongs_to :user
  belongs_to :invited_by, class_name: "User"

  enum :status, {
    pending_approval: 0,
    approved:         1,
    accepted:         2,
    rejected:         3,
    declined:         4,
    expired:          5
  }

  scope :pending,  -> { where(status: :pending_approval) }
  scope :expired,  -> { where("expires_at < ?", Time.current) }

  def expired?
    expires_at < Time.current
  end
end

# ❌ ERRADO — código em português
class ConviteDepartamento < ApplicationRecord
  enum :status, { aguardando_aprovacao: 0, aprovado: 1, aceito: 2 }
  scope :pendentes, -> { where(status: :aguardando_aprovacao) }
end
```

### 15.4 Textos de interface — sempre via I18n

```ruby
# ❌ BLOQUEADO em code review — string hardcoded
flash[:notice] = "Convite enviado com sucesso!"
flash[:alert]  = "Você não tem permissão para realizar esta ação."
render plain: "Erro: membro já pertence ao departamento"

# ✅ CORRETO — sempre via I18n
flash[:notice] = t(".success")
flash[:alert]  = t("errors.not_authorized")
redirect_to root_path, notice: t(".invite_sent")
```

```erb
<%# ❌ BLOQUEADO — texto hardcoded na view %>
<button>Salvar alterações</button>
<p>Nenhum membro encontrado.</p>
<span>Aniversariantes do mês</span>

<%# ✅ CORRETO — via I18n %>
<button><%= t(".save") %></button>
<p><%= t(".no_members_found") %></p>
<span><%= t("members.birthdays.this_month") %></span>
```

### 15.5 Notificações — sempre via I18n

Isso inclui notificações in-app (sino), e-mails, mensagens de WhatsApp e qualquer outro canal:

```ruby
# ❌ ERRADO — string hardcoded na notificação
Notification.create!(
  title:   "Convite de departamento",
  message: "Você foi convidado para o departamento Mídia."
)

# ✅ CORRETO — I18n com interpolação
Notification.create!(
  title:   I18n.t("notifications.department_invite.title"),
  message: I18n.t(
    "notifications.department_invite.message",
    departament: invite.departament.name
  )
)
```

```yaml
# config/locales/notifications/pt-BR.yml
pt-BR:
  notifications:
    department_invite:
      title: "Convite de departamento"
      message: "Você foi convidado para participar do departamento %{departament}."
    schedule_published:
      title: "Escala publicada"
      message: "A escala de %{month} do departamento %{departament} foi publicada."
    birthday_reminder:
      title: "🎂 Aniversariante hoje"
      message: "%{name} faz aniversário hoje. Que tal enviar uma mensagem?"
```

### 15.6 Erros de validação — sempre via I18n

```ruby
# ❌ ERRADO — mensagem hardcoded no model
validates :name, presence: { message: "não pode ficar em branco" }
validates :email, uniqueness: { message: "já está em uso nesta congregação" }

# ✅ CORRETO — usar as chaves padrão do Rails I18n
validates :name,  presence: true    # mensagem vem do locale automaticamente
validates :email, uniqueness: { scope: :church_id }
```

```yaml
# config/locales/models/user.pt-BR.yml
pt-BR:
  activerecord:
    errors:
      models:
        user:
          attributes:
            name:
              blank: "não pode ficar em branco"
            email:
              taken: "já está em uso nesta congregação"
              invalid: "não é um endereço de e-mail válido"
            birth_date:
              blank: "é obrigatória"
              future: "não pode ser uma data futura"
```

### 15.7 Mailers — sempre via I18n

```ruby
# app/mailers/department_invite_mailer.rb
class DepartmentInviteMailer < ApplicationMailer
  def invite_notification(invite)
    @invite = invite
    @user   = invite.user

    mail(
      to:      @user.email,
      subject: t(".subject", departament: @invite.departament.name)
    )
  end
end
```

```yaml
# config/locales/mailers/pt-BR.yml
pt-BR:
  department_invite_mailer:
    invite_notification:
      subject: "Você foi convidado para o departamento %{departament}"
```

### 15.8 Estrutura de locales

```
config/locales/
├── pt-BR.yml                        # Globais: datas, formatos, erros genéricos
├── models/
│   ├── user.pt-BR.yml               # Atributos e erros do model User
│   ├── schedule.pt-BR.yml
│   ├── department_invite.pt-BR.yml
│   └── ...
├── views/
│   ├── application/
│   │   └── pt-BR.yml               # shared: botões, estados vazios, paginação
│   ├── schedules/
│   │   ├── index.pt-BR.yml
│   │   ├── show.pt-BR.yml
│   │   └── ...
│   ├── members/
│   │   └── invites/
│   │       └── create.pt-BR.yml
│   └── ...
├── mailers/
│   ├── department_invite_mailer.pt-BR.yml
│   └── welcome_mailer.pt-BR.yml
└── notifications/
    └── pt-BR.yml                    # Notificações in-app, push, WhatsApp
```

### 15.9 Rotas em inglês

```ruby
# config/routes.rb

# ✅ CORRETO — rotas em inglês
resources :churches do
  resources :members, only: [:index, :show]
  resources :departments do
    resources :invites, only: [:create, :destroy]
    resources :schedules
  end
end

resources :welcome_records, only: [:index, :create]
resources :birthdays,       only: [:index]

# ❌ ERRADO — rotas em português
resources :igrejas do
  resources :membros
  resources :departamentos
end
```

### 15.10 Checklist de code review — idioma

Antes de aprovar qualquer PR, verifique:

- [ ] Nomes de classes, métodos, variáveis, colunas e arquivos estão em inglês
- [ ] Nenhuma string visível ao usuário está hardcoded em `.rb` ou `.erb`
- [ ] Todas as mensagens de flash usam `t(".chave")`
- [ ] Todas as notificações usam `I18n.t("notifications...")`
- [ ] Todos os textos de e-mail (subject, body) usam `t(".chave")` no mailer
- [ ] Erros de validação personalizados estão nos arquivos de locale dos models
- [ ] Rotas estão em inglês
- [ ] Novos arquivos de locale foram criados em `config/locales/` na pasta correta

---

## 16. Anti-padrões — O que nunca fazer

Esta seção é a referência rápida durante code review. Qualquer PR que contenha um desses padrões deve ser bloqueado.

### 14.1 Lógica de negócio no Controller

```ruby
# ❌ BLOQUEADO em code review
def create
  if @user.active? && @user.church == current_church
    @schedule.assign_member!(@user)
    UserMailer.notify(@user).deliver_later
  end
end
```

### 14.2 Query complexa no Controller ou View

```ruby
# ❌ BLOQUEADO
@members = User.where(church: current_church)
               .joins(:memberchips)
               .where(memberchips: { role: :leader })
               .order(:name)
```

### 14.3 Side effects em callbacks do Model

```ruby
# ❌ BLOQUEADO
after_create :send_welcome_email
after_update :notify_pastor_of_change
```

### 14.4 Job enfileirado dentro de transaction

```ruby
# ❌ BLOQUEADO
ActiveRecord::Base.transaction do
  record.save!
  SomeJob.perform_later(record.id) # pode rodar com dados não commitados
end
```

### 14.5 String hardcoded visível ao usuário

```ruby
# ❌ BLOQUEADO
flash[:notice] = "Membro convidado com sucesso!"
render plain: "Erro: acesso negado"
```

### 14.6 Objeto ActiveRecord passado para Job

```ruby
# ❌ BLOQUEADO
SomeJob.perform_later(user)      # nunca objeto
SomeJob.perform_later(user.id)   # ✅ sempre ID
```

### 14.7 Pundit ignorado no Controller

```ruby
# ❌ BLOQUEADO — ação sem autorização explícita
def update
  @schedule.update!(schedule_params)
  redirect_to @schedule
end

# ✅ CORRETO
def update
  authorize @schedule  # ← obrigatório
  @schedule.update!(schedule_params)
  redirect_to @schedule
end
```

### 14.8 Múltiplos métodos públicos no Service

```ruby
# ❌ BLOQUEADO — expõe interface maior que o necessário
class ScheduleService
  def create_schedule(...)
  def publish_schedule(...)  # criar um novo service para isso
  def archive_schedule(...)  # e um para isso
end
```

---

*Ekklesia — Documento interno · Versão 1.0 · Julho 2026*
*Dúvidas sobre qualquer padrão: abra uma discussão no repositório antes de implementar uma abordagem diferente.*