# Ekklesia — Regras de Negócio
## Perfil Administrador (Pastor) & Co-Pastor

> **Versão 1.0 · Julho 2026**
> Documento interno — uso restrito à equipe de produto

---

## Sumário

1. [Visão Geral](#1-visão-geral)
2. [Perfis e Hierarquia](#2-perfis-e-hierarquia)
3. [Permissões por Módulo](#3-permissões-por-módulo)
4. [Módulo Membros](#4-módulo-membros)
5. [Módulo Eventos](#5-módulo-eventos)
6. [Módulo Departamentos](#6-módulo-departamentos)
7. [Módulo Acolhimento](#7-módulo-acolhimento)
8. [Módulo Aniversariantes](#8-módulo-aniversariantes)
9. [Módulo Agenda](#9-módulo-agenda)
10. [Dashboard e Métricas](#10-dashboard-e-métricas)
11. [Alertas e Notificações](#11-alertas-e-notificações)
12. [Co-Pastor](#12-co-pastor)
13. [Regras de Segurança e Integridade](#13-regras-de-segurança-e-integridade)
14. [Glossário](#14-glossário)

---

## 1. Visão Geral

O **Administrador** é o perfil de maior autoridade dentro de uma instituição no sistema Ekklesia. Corresponde ao **Pastor Presidente** ou líder principal da congregação. É a camada máxima de aprovação e supervisão — não executa as tarefas operacionais do dia a dia (que são responsabilidade do secretário), mas **supervisiona, autoriza e é notificado** sobre tudo que acontece na instituição.

**O Administrador é responsável por:**

- Supervisionar membros, departamentos, eventos e escalas da instituição
- Aprovar ações estratégicas que extrapolam o escopo do secretário
- Acompanhar métricas de crescimento e engajamento da congregação
- Receber alertas pastorais: aniversariantes, membros ausentes, pedidos de oração
- Gerenciar sua agenda de compromissos
- Definir as permissões customizadas do Co-Pastor
- Ser a autoridade final em decisões que envolvem toda a instituição

**O Administrador NÃO é responsável por:**

- Operação diária do sistema (cadastros, escalas, formulários) — isso é do secretário
- Aprovação de eventos — quem aprova é o **secretário** (o pastor cria como rascunho)
- Gerenciar permissões de módulos — exclusivo do **master**

> **Importante:** O role `administrador` no sistema corresponde ao Pastor. Não confundir com o usuário `master`, que é o administrador técnico do SaaS com acesso às configurações globais de permissões.

---

## 2. Perfis e Hierarquia

```
master (SaaS)
    └── administrador (Pastor)
            ├── co_pastor
            ├── secretario_sede / secretario_local
            ├── tesoureiro
            ├── regente
            ├── lider
            ├── acolhimento
            ├── membro_cargo
            └── membro
```

### 2.1 Role

| Campo | Valor |
|---|---|
| Role | `administrador` |
| Policy (Pundit) | `AdministradorPolicy` |
| Escopo de atuação | Própria instituição (sede ou congregação onde está vinculado) |
| Isolamento | Enxerga apenas dados do próprio `institution_id` e `tenant_id` |

### 2.2 Diferença entre Administrador e Master

| Capacidade | Administrador (Pastor) | Master (SaaS) |
|---|---|---|
| Gerenciar membros e departamentos | ✅ | ✅ |
| Criar eventos e escalas | ✅ | ✅ |
| Alterar permissões de módulos | ❌ | ✅ |
| Criar novas instituições/tenants | ❌ | ✅ |
| Ver dados de outros tenants | ❌ | ✅ |
| Remover secretário | ✅ | ✅ |
| Definir permissões do co-pastor | ✅ | ✅ |
| Acessar logs de auditoria | ✅ Própria instituição | ✅ Global |

---

## 3. Permissões por Módulo

| Módulo | Administrador | Co-Pastor |
|---|---|---|
| Dashboard / Métricas | ✅ Completo | Conforme permissões definidas pelo pastor |
| Calendário | ✅ Visualizar + gerenciar | Idem |
| Eventos | ✅ CRUD (cria como rascunho — secretário aprova) | Idem |
| Departamentos | ✅ CRUD + nomear líderes | Idem |
| Membros | ✅ Visualizar + promover cargos + acompanhar evolução | Idem |
| Escalas | ✅ Visualizar todas | Idem |
| Formulários | ✅ Visualizar | Idem |
| Acolhimento | ✅ Visualizar lista + receber pedidos de oração | Idem |
| Aniversariantes | ✅ Visualizar + receber lembretes | Idem |
| Agenda | ✅ CRUD própria agenda | Idem |
| Financeiro | ✅ Visualizar resumo (sem editar lançamentos) | Idem |
| Configurações — Co-Pastor | ✅ Definir permissões do co-pastor | ❌ |
| Configurações — Sistema | ❌ (exclusivo do master) | ❌ |
| Configurações — Permissões de módulos | ❌ (exclusivo do master) | ❌ |

---

## 4. Módulo Membros

### 4.1 O que o Administrador pode fazer

- Visualizar lista completa de membros da própria instituição
- Filtrar membros por: status (ativo/inativo), batismo, cargo, departamento, tempo de casa
- Acompanhar a evolução individual de cada membro (departamentos, cargos, tempo de casa)
- Promover ou alterar o cargo de um membro (ex: nomear líder de departamento, diácono)
- Receber alerta de membros ausentes conforme critério configurado (ver seção 11)
- Visualizar histórico de transferências e de cargos de cada membro
- Apresentar novos membros à congregação (marcando o status `apresentado` no cadastro)

### 4.2 O que o Administrador NÃO pode fazer

- Criar ou editar o cadastro de membros — responsabilidade do secretário
- Excluir ou inativar membros diretamente — deve solicitar ao secretário
- Aprovar transferências de membros entre congregações — responsabilidade do secretário sede

### 4.3 Acompanhamento de evolução de membros

O pastor pode visualizar um painel individual de cada membro com:

- Tempo de casa (calculado a partir da data de cadastro)
- Departamentos que participa
- Cargo atual e histórico de cargos
- Presença nos cultos (se o módulo de presença estiver ativo)
- Se foi batizado ou não
- Se já foi apresentado à congregação

Esse painel auxilia o pastor a identificar membros com perfil para assumir cargos futuros (juventude, mídia, louvor, etc.).

---

## 5. Módulo Eventos

### 5.1 Fluxo de criação de eventos pelo Administrador

O pastor **cria eventos como rascunho**. O secretário é responsável por revisar e aprovar, pois tem visão do calendário completo e pode identificar conflitos de data.

```
Pastor cria evento (status: rascunho)
         │
         ▼
Secretário recebe notificação
         │
    ┌────┴────┐
    ▼         ▼
Aprova     Recusa (com motivo)
    │         │
    ▼         ▼
Evento     Pastor é notificado
publicado  e pode revisar
no calendário
```

### 5.2 Regras do fluxo

- O pastor **não pode publicar** um evento diretamente — sempre passa pelo secretário
- O pastor pode **editar** o rascunho enquanto o status for `rascunho` ou `recusado`
- Após aprovação, o pastor pode **solicitar alteração** ao secretário, mas não editar diretamente
- O pastor visualiza todos os eventos da instituição, independente de quem os criou

### 5.3 Eventos de grande porte (assembleias, conferências)

Para eventos que envolvem múltiplas congregações do campo, o pastor da sede pode criar o evento e o secretário sede é responsável pela aprovação e comunicação às filhas.

---

## 6. Módulo Departamentos

### 6.1 O que o Administrador pode fazer

- Criar novos departamentos na própria instituição
- Nomear e substituir líderes de departamentos
- Visualizar lista de departamentos, seus líderes e membros
- Inativar departamentos (com motivo obrigatório)

### 6.2 O que o Administrador NÃO pode fazer

- Editar os detalhes operacionais do departamento (escalas, membros) — responsabilidade do líder e secretário
- Excluir fisicamente um departamento — apenas inativar

### 6.3 Regra de nomeação de líder

Ao nomear um líder de departamento:

1. Pastor seleciona o membro e o departamento
2. Sistema verifica se o membro já é líder de outro departamento — exibe aviso (não bloqueante)
3. O membro recebe notificação da nomeação
4. O cargo do membro é atualizado no cadastro automaticamente
5. A ação é registrada no `AuditLog`

---

## 7. Módulo Acolhimento

O pastor utiliza o módulo de acolhimento de forma **passiva** — não registra visitas, mas consome as informações para uso pastoral durante e após os cultos.

### 7.1 Durante o culto

- Acessa lista simplificada (somente leitura) dos visitantes do culto em andamento
- Visualiza: nome e tipo (visitante ou irmão)
- Usa essa lista para realizar a **apresentação dos visitantes** durante a celebração

### 7.2 Após o culto

- Visualiza lista completa dos acolhidos com todos os campos
- Acessa pedidos de oração registrados no dia
- Acompanha status dos encaminhamentos ao Departamento de Evangelismo

### 7.3 O que o Administrador NÃO faz no Acolhimento

- Registrar visitas — responsabilidade da recepcionista
- Alterar status de pedidos de oração — responsabilidade do líder de Evangelismo
- Converter visitante em membro — responsabilidade do secretário

---

## 8. Módulo Aniversariantes

### 8.1 Visualização

- Página de aniversariantes com duas abas: **Esta semana** e **Este mês**
- Filtra membros ativos da própria instituição por dia e mês de nascimento
- Exibe: nome, foto/avatar, data de aniversário formatada, departamento e contatos (telefone/WhatsApp)
- Destaque especial para aniversariantes do dia (borda colorida + badge "🎂 Hoje!")

### 8.2 Lembretes automáticos

O pastor recebe notificação automática:

- **No dia anterior:** lista dos aniversariantes do dia seguinte
- **No dia:** lista dos aniversariantes do dia atual ao fazer login

As notificações aparecem no sino da navbar e podem ser configuradas para envio por e-mail ou WhatsApp (quando integração estiver ativa).

---

## 9. Módulo Agenda

A agenda é pessoal do pastor — não é compartilhada com outros usuários, a menos que o pastor explicitamente compartilhe um compromisso.

### 9.1 O que é uma Agenda

**Migration**

```ruby
class CreateCompromissos < ActiveRecord::Migration[8.0]
  def change
    create_table :compromissos, id: :uuid do |t|
      t.references :institution, null: false, foreign_key: true, type: :uuid
      t.uuid        :tenant_id,       null: false
      t.references :criado_por,       null: false, foreign_key: { to_table: :users }, type: :uuid

      t.string      :titulo,          null: false
      t.text        :descricao
      t.integer     :tipo,            null: false, default: 0
      t.datetime    :data_inicio,     null: false
      t.datetime    :data_fim
      t.string      :local
      t.text        :participantes
      t.integer     :visivel_para,    null: false, default: 0
      t.integer     :status,          null: false, default: 0

      t.timestamps
    end

    add_index :compromissos, :tenant_id
    add_index :compromissos, :data_inicio
  end
end
```

**Model**

```ruby
# app/models/compromisso.rb
class Compromisso < ApplicationRecord
  belongs_to :institution
  belongs_to :criado_por, class_name: "User"

  enum :tipo, {
    reuniao:          0,
    visita_pastoral:  1,
    culto_externo:    2,
    administrativo:   3,
    pessoal:          4,
    outro:            5
  }

  enum :visivel_para, {
    apenas_pastor: 0,
    co_pastor:     1,
    secretario:    2,
    todos:         3
  }

  enum :status, {
    agendado:  0,
    concluido: 1,
    cancelado: 2
  }

  # Isolamento multi-tenant
  scope :do_tenant, ->(user) {
    where(institution_id: user.institution_id, tenant_id: user.tenant_id)
  }

  validates :titulo,      presence: true
  validates :data_inicio, presence: true
  validates :tipo,        presence: true
  validates :visivel_para, presence: true
  validates :status,      presence: true

  validate :data_fim_depois_de_data_inicio

  private

  def data_fim_depois_de_data_inicio
    return unless data_fim.present? && data_inicio.present?
    errors.add(:data_fim, "deve ser posterior à data de início") if data_fim <= data_inicio
  end
end
```

### 9.2 Funcionalidades

- Criar, editar e excluir compromissos pessoais
- Visualizar agenda em modo calendário (mensal, semanal) e lista
- Filtrar por tipo de compromisso
- Definir visibilidade de cada compromisso (apenas pastor, co-pastor, secretário ou todos)
- Receber lembrete do compromisso com antecedência configurável (1h, 1 dia, 1 semana)

### 9.3 Integração com Eventos do sistema

- Cultos e eventos aprovados no módulo **Eventos** aparecem automaticamente na agenda do pastor como itens somente leitura
- O pastor não precisa criar manualmente os cultos na agenda — eles sincronizam automaticamente

### 9.4 O que a Agenda NÃO é

- Não substitui o módulo de **Eventos** — a agenda é pessoal, os eventos são institucionais
- Não é um sistema de agendamento de visitas pastorais com fluxo de aprovação — é um bloco de notas de compromissos
- Não é compartilhada automaticamente com nenhum outro usuário sem permissão explícita do pastor

---

## 10. Dashboard e Métricas

O dashboard do Administrador é a tela inicial após o login. Apresenta uma visão consolidada da saúde e crescimento da instituição.

### 10.1 Cards de resumo

| Card | O que exibe |
|---|---|
| Membros ativos | Total de membros com status `ativo` |
| Membros batizados | Total e percentual sobre o total de membros |
| Novos membros (mês) | Membros cadastrados nos últimos 30 dias |
| Membros ausentes | Membros que não comparecem conforme critério configurado |
| Departamentos ativos | Total de departamentos com ao menos 1 membro |
| Eventos este mês | Total de eventos com status `aprovado` no mês atual |
| Visitantes (mês) | Total de registros de acolhimento no mês |
| Pedidos de oração | Total com status `pendente` |

### 10.2 Gráficos de crescimento

- **Crescimento de membros:** linha mensal dos últimos 12 meses (total de membros ativos por mês)
- **Batismos:** barras mensais dos últimos 12 meses
- **Visitantes vs. Conversões:** linha comparativa — total de visitantes × quantidade que se tornou membro
- **Engajamento por departamento:** barras mostrando membros ativos por departamento

### 10.3 Métricas de influência na comunidade

- Total de visitantes acolhidos no mês (do módulo Acolhimento)
- Total de conversões (visitantes que viraram membros) no mês e no ano
- Taxa de conversão: `(conversões / visitantes) × 100`
- Número de pedidos de oração registrados (impacto evangelístico)

### 10.4 Painel de evolução de membros

Lista dos membros com maior potencial de liderança, baseada em critérios configuráveis:
- Tempo de casa (ex: mais de 1 ano)
- Participação em departamentos (ex: 2 ou mais)
- Status de batismo
- Presença regular nos cultos (quando módulo de presença ativo)

---

## 11. Alertas e Notificações

### 11.1 Tipos de alerta recebidos pelo Administrador

| Alerta | Gatilho | Canal |
|---|---|---|
| 🎂 Aniversariante amanhã | D-1 em relação à data de nascimento do membro | Sino + e-mail/WhatsApp (configurável) |
| 🎂 Aniversariante hoje | Dia do aniversário do membro | Sino + e-mail/WhatsApp (configurável) |
| 👤 Membro ausente | Conforme critério configurado (ver 11.2) | Sino semanal |
| 🙏 Pedido de oração | Novo pedido registrado no acolhimento | Sino |
| 📋 Evento recusado | Secretário recusa um evento criado pelo pastor | Sino + e-mail |
| 📋 Evento aprovado | Secretário aprova um evento criado pelo pastor | Sino |
| 🏛 Nova aprovação pendente | Ação que requer aprovação do pastor (ex: remoção de secretário) | Sino + e-mail |
| 💳 Lançamento financeiro pendente | Movimentação bancária acima do limite aguardando aprovação | Sino |

### 11.2 Critério de membro ausente

O critério é **configurável pelo próprio pastor** nas Configurações da instituição:

**Opções disponíveis:**
- Ausente por **X cultos consecutivos** (ex: 4 cultos = aprox. 1 mês)
- Ausente por **X semanas** sem registro de presença
- Ausente por **X meses** (calculado por data)

**Comportamento:**
- O sistema verifica semanalmente (toda segunda-feira) os membros que atendem ao critério
- O pastor recebe uma lista consolidada no sino: _"5 membros não comparecem há mais de [critério configurado]"_
- A lista exibe: nome, último culto registrado e departamento
- O pastor pode marcar um membro como _"em acompanhamento"_ para retirar temporariamente do alerta

> **Dependência:** este alerta requer que o módulo de **Presença** esteja ativo. Se não estiver, o alerta é baseado na data do último registro de acolhimento em que o membro apareceu como visitante (fallback).

---

## 12. Co-Pastor

### 12.1 Visão geral

O Co-Pastor é um perfil de **confiança delegada** — suas permissões são definidas inteiramente pelo Pastor. Não há um conjunto fixo de permissões para este perfil.

### 12.2 Role

| Campo | Valor |
|---|---|
| Role | `co_pastor` |
| Policy (Pundit) | `CoPastorPolicy` (herda de `AdministradorPolicy` com filtro de permissões) |
| Escopo de atuação | Idêntico ao do pastor (própria instituição) |

### 12.3 Como o Pastor define as permissões do Co-Pastor

Nas **Configurações → Co-Pastor**, o pastor vê uma matriz de permissões:

| Módulo | Pode visualizar | Pode criar/editar | Pode aprovar |
|---|---|---|---|
| Membros | toggle | toggle | toggle |
| Eventos | toggle | toggle | toggle |
| Departamentos | toggle | toggle | — |
| Acolhimento | toggle | — | — |
| Aniversariantes | toggle | — | — |
| Agenda | toggle | toggle | — |
| Financeiro | toggle | — | toggle |
| Escalas | toggle | toggle | — |
| Formulários | toggle | — | — |
| Dashboard / Métricas | toggle | — | — |

- O pastor pode ativar ou desativar cada combinação individualmente
- As permissões do co-pastor **nunca superam** as do pastor — o sistema bloqueia qualquer tentativa de conceder ao co-pastor o que o próprio pastor não possui
- Alterações nas permissões do co-pastor são registradas no `AuditLog`

### 12.4 O que o Co-Pastor NUNCA pode fazer

Independente das permissões concedidas pelo pastor:

- Remover ou rebaixar o pastor
- Alterar as próprias permissões
- Definir permissões de outros usuários (exceto se explicitamente delegado pelo pastor)
- Acessar Configurações globais do sistema (exclusivo do master)

### 12.5 Funcionalidades futuras _(Em construção)_

- Agenda compartilhada entre pastor e co-pastor
- Delegação temporária de autoridade (ex: pastor em viagem delega aprovações ao co-pastor por período determinado)

---

## 13. Regras de Segurança e Integridade

### 13.1 O que o Administrador NUNCA pode fazer

- Alterar permissões de módulos — exclusivo do master
- Excluir fisicamente membros, usuários ou registros — apenas inativar
- Aprovar os próprios eventos — self-approval bloqueado pelo sistema
- Ver dados de outros tenants/ministérios
- Acessar dados financeiros detalhados sem que o tesoureiro tenha concedido visibilidade (apenas resumo no dashboard)

### 13.2 Auditoria

Toda ação do Administrador é registrada no `AuditLog`:

- Nomeação e remoção de líderes de departamentos
- Criação e edição de eventos
- Criação e edição de compromissos na agenda
- Alteração de permissões do co-pastor
- Aprovação de lançamentos financeiros acima do limite
- Inativação de departamentos

### 13.3 Isolamento multi-tenant

- O administrador enxerga **apenas dados da própria instituição** (`institution_id` + `tenant_id`)
- Se o pastor for da sede, enxerga apenas a sede — não as congregações filhas (a menos que seja também secretário sede ou tenha permissão explícita do master)
- `institution_id` e `tenant_id` são sempre preenchidos automaticamente pelo contexto do usuário logado

---

## 14. Glossário

| Termo | Definição |
|---|---|
| **Administrador** | Role do Pastor no sistema Ekklesia. Camada máxima de autoridade na instituição. |
| **Master** | Administrador técnico do SaaS. Acima do administrador. Gerencia permissões globais. |
| **Co-Pastor** | Perfil com permissões customizadas definidas pelo pastor. Confiança delegada. |
| **Rascunho** | Status inicial de eventos criados pelo pastor — aguarda aprovação do secretário. |
| **Self-approval** | Auto-aprovação bloqueada — o pastor não pode aprovar os próprios eventos. |
| **Membro ausente** | Membro que não comparece conforme critério configurado pelo pastor nas Configurações. |
| **Apresentação** | Ato de apresentar o novo membro à congregação durante o culto. Marcado no cadastro do membro. |
| **Nomeação** | Ato do pastor de definir o líder de um departamento. Registrado no AuditLog. |
| **Agenda** | Módulo pessoal do pastor para gestão de compromissos. Não substitui o módulo de Eventos. |
| **Taxa de conversão** | Percentual de visitantes que se tornaram membros no período. Exibida no dashboard. |
| **AuditLog** | Tabela de rastreabilidade de todas as ações executadas no sistema. |
| **Tenant** | Ministério/Igreja contratante do Ekklesia — isolamento total entre tenants. |
| **institution_id** | Identificador da congregação específica dentro de um tenant. |

---

## Funcionalidades Futuras _(Fora do escopo atual)_

As funcionalidades abaixo foram identificadas como necessidades do perfil Administrador mas estão fora do escopo da versão atual. Devem ser documentadas e priorizadas em sprints futuras.

| Funcionalidade | Descrição |
|---|---|
| **Mentorias** | Pastor cria trilhas de mentoria e acompanha o desenvolvimento espiritual individual de membros |
| **Projetos** | Gestão de projetos e iniciativas da igreja (obras, missões, campanhas) com tarefas e responsáveis |
| **Módulo de Presença** | Registro de frequência de membros nos cultos — base para o alerta de membros ausentes |
| **Agenda compartilhada** | Compartilhamento de compromissos entre pastor e co-pastor |
| **Delegação temporária** | Pastor delega aprovações ao co-pastor por período determinado (ex: viagens) |
| **Integração WhatsApp** | Envio de lembretes de aniversariantes e alertas via WhatsApp Business API |

---

*Ekklesia — Documento interno · Versão 1.0 · Julho 2026*