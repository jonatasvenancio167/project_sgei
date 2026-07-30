# Ekklesia — Regras de Negócio
## Módulo Acolhimento · Perfil Recepcionista

> **Versão 1.1 · Julho 2026**
> Documento interno — uso restrito à equipe de produto

---

## Sumário

1. [Visão Geral](#1-visão-geral)
2. [Perfil e Permissões](#2-perfil-e-permissões)
3. [Entidades e Modelagem](#3-entidades-e-modelagem)
4. [Formulário de Registro de Visita](#4-formulário-de-registro-de-visita)
5. [Regras de Negócio](#5-regras-de-negócio)
6. [Fluxo de Pedidos de Oração e Visita Pastoral](#6-fluxo-de-pedidos-de-oração-e-visita-pastoral)
7. [Histórico de Visitas](#7-histórico-de-visitas)
8. [Dashboard do Acolhimento](#8-dashboard-do-acolhimento)
9. [Regras de Segurança e Integridade](#9-regras-de-segurança-e-integridade)
10. [Referência Técnica (Rails 8 + Hotwire)](#10-referência-técnica-rails-8--hotwire)
11. [Glossário](#11-glossário)

---

## 1. Visão Geral

O módulo de **Acolhimento** é o ponto de contato inicial entre o visitante e a igreja local. Funciona como uma **triagem evangelística e comunitária**, operada pela equipe de recepção durante os cultos e eventos.

**Responsabilidades do módulo:**

- Identificar o perfil da pessoa acolhida: simpatizante/novo convertido ou irmão membro de outra congregação
- Coletar dados de contato para acompanhamento pós-culto e agendamento de visitas pastorais
- Registrar pedidos de oração e encaminhar ao departamento responsável
- Alimentar o histórico de visitas para acompanhamento pastoral e geração de relatórios
- Disponibilizar lista de visitantes ao pastor/dirigente durante a celebração

**O módulo NÃO é responsável por:**

- Converter um visitante em membro — esse fluxo pertence ao módulo **Membros**
- Gerenciar o culto em si — cultos são criados no módulo **Eventos**
- Gerir o acompanhamento pastoral após o encaminhamento — responsabilidade do departamento de Evangelismo

---

## 2. Perfil e Permissões

### 2.1 Role

- **Role:** `acolhimento`
- **Policy (Pundit):** `AcolhimentoPolicy`
- **Princípio do menor privilégio:** interface enxuta, projetada para uso rápido em celular ou tablet durante os cultos

### 2.2 Acesso padrão (sem nenhuma configuração extra)

| Módulo / Tela | Acesso |
|---|---|
| Dashboard de Acolhimento | ✅ Visualizar métricas do dia |
| Registrar visita (modal) | ✅ Criar |
| Listagem de acolhidos do dia | ✅ Visualizar + editar até 30 min após o registro |
| Histórico de visitas | ✅ Visualizar — apenas da própria congregação |
| Pedidos de oração | ✅ Criar + visualizar os do dia |
| Membros | ❌ |
| Departamentos | ❌ |
| Escalas | ❌ |
| Formulários | ❌ |
| Eventos | ❌ |
| Financeiro | ❌ |
| Configurações | ❌ |

### 2.3 Acesso expandido

O Administrador (pastor) ou Secretário pode liberar acesso a outros módulos alterando as permissões do usuário nas **Configurações → Perfis e Permissões**. Esse acesso extra é registrado no `AuditLog`.

### 2.4 Visibilidade multi-tenant

- A recepcionista enxerga **apenas registros da própria congregação** (`institution_id` do usuário logado)
- Nunca enxerga registros de outras congregações do campo, mesmo que pertençam ao mesmo tenant
- `institution_id` e `tenant_id` são preenchidos automaticamente no momento do registro — nunca pelo usuário

---

## 3. Entidades e Modelagem

### 3.1 `RegistroAcolhimento`

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `id` | `uuid` | — | Identificador único |
| `institution_id` | `uuid` | ✅ | Congregação onde o registro foi feito |
| `tenant_id` | `uuid` | ✅ | Ministério/tenant — preenchido automaticamente |
| `nome` | `string` | ✅ | Nome completo do acolhido |
| `tipo` | `enum` | ✅ | `visitante` ou `irmao` |
| `congregacao` | `string` | ❌ | Igreja/ministério de origem (somente para `irmao`) |
| `cidade` | `string` | ❌ | Cidade de residência |
| `telefone_whatsapp` | `string` | ❌ | Telefone com máscara `(DD) 9XXXX-XXXX` |
| `culto_id` | `uuid` | ✅ | FK → `eventos` (tipo: culto) |
| `observacao` | `text` | ❌ | Pedido de oração, solicitação de visita ou nota livre |
| `status` | `enum` | ✅ | `registrado`, `encaminhado`, `convertido_em_membro` |
| `data_hora_registro` | `datetime` | ✅ | Preenchido automaticamente via `Time.current` no submit |
| `registrado_por_id` | `uuid` | ✅ | FK → `users` — quem fez o registro |
| `inactivated_at` | `datetime` | ❌ | Preenchido em caso de inativação |
| `inactivated_by_id` | `uuid` | ❌ | FK → `users` |
| `inactivation_reason` | `string` | ❌ | Motivo da inativação |

### 3.2 `PedidoOracao`

> Gerado automaticamente quando o campo `observacao` do `RegistroAcolhimento` é marcado como pedido de oração, **ou** criado diretamente pela recepcionista.

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `id` | `uuid` | — | Identificador único |
| `institution_id` | `uuid` | ✅ | Preenchido automaticamente |
| `tenant_id` | `uuid` | ✅ | Preenchido automaticamente |
| `registro_acolhimento_id` | `uuid` | ❌ | Vínculo com o registro de visita (se houver) |
| `nome_solicitante` | `string` | ✅ | Pode ser o visitante ou um membro presente |
| `descricao` | `text` | ✅ | Descrição do pedido |
| `tipo` | `enum` | ✅ | `oracao`, `visita_pastoral`, `acompanhamento` |
| `status` | `enum` | ✅ | `pendente`, `em_andamento`, `concluido` |
| `encaminhado_para_id` | `uuid` | ❌ | FK → `departamentos` (ex: Evangelismo) |
| `criado_por_id` | `uuid` | ✅ | FK → `users` |
| `created_at` | `datetime` | ✅ | — |

### 3.3 Relação com `Eventos` (Cultos)

O campo `culto_id` referencia a tabela `eventos` com filtro `tipo: :culto`. A recepcionista **não cria cultos** — eles são criados pelo secretário ou administrador no módulo **Eventos**.

No formulário de registro, o select de culto exibe apenas:
- Cultos do dia atual (`date = Date.current`)
- Da própria congregação (`institution_id` do usuário logado)
- Com status `aprovado` ou `em_andamento`

Se não houver culto cadastrado para o dia, a recepcionista vê uma mensagem orientando a acionar o secretário.

---

## 4. Formulário de Registro de Visita

### 4.1 Campos e comportamento

| Campo | UI | Validação |
|---|---|---|
| **Nome** | Input texto | Obrigatório, mínimo 3 caracteres |
| **Tipo** | Toggle: "Visitante" / "Irmão" | Obrigatório |
| **Congregação** | Input texto | Opcional — exibido apenas se `tipo = irmao` |
| **Cidade** | Input texto | Opcional |
| **Telefone / WhatsApp** | Input com máscara `(DD) 9XXXX-XXXX` | Opcional, formato validado se preenchido |
| **Culto** | Select (cultos do dia) | Obrigatório |
| **Observação / Pedido de oração** | Textarea | Opcional |

### 4.2 Comportamento condicional

- Ao selecionar `tipo = irmao`: campo **Congregação** aparece com animação suave (Stimulus)
- Ao selecionar `tipo = visitante`: campo **Congregação** é ocultado e seu valor limpo
- Ao submeter: modal fecha automaticamente e o novo registro aparece no topo da listagem via Turbo Stream, sem reload de página

### 4.3 Edição pós-registro

- A recepcionista pode editar um registro **até 30 minutos** após criá-lo
- Após esse prazo, apenas o secretário ou administrador pode editar
- Toda edição é registrada no `AuditLog` com snapshot antes/depois

---

## 5. Regras de Negócio

### 5.1 Nunca deletar, sempre inativar

Registros de acolhimento **nunca são excluídos fisicamente**. Caso um registro tenha sido feito por engano:

- A recepcionista pode inativar o próprio registro **até 30 minutos** após criá-lo, informando o motivo
- Após esse prazo, apenas o secretário ou administrador pode inativar
- O registro inativado some da listagem do dia mas permanece no histórico com badge _"Inativado"_ e o motivo visível

### 5.2 Tipos de acolhido

| Tipo | Descrição | Campos adicionais |
|---|---|---|
| `visitante` | Simpatizante, novo convertido ou pessoa sem vínculo com nenhuma congregação | Cidade, telefone, observação |
| `irmao` | Crente membro de outra congregação ou ministério | Congregação de origem, cidade, telefone |

> A distinção é fundamental para o acompanhamento pastoral: visitantes entram no funil de evangelismo; irmãos são acolhidos como convidados sem necessidade de acompanhamento evangelístico.

### 5.3 Registro duplicado no mesmo culto

Se a recepcionista tentar registrar um nome **muito semelhante** (fuzzy match) para o mesmo culto no mesmo dia, o sistema exibe um alerta:

> _"Já existe um registro com nome semelhante neste culto: 'Maria Souza' registrada às 19h32. Deseja continuar mesmo assim?"_

O registro ainda pode ser salvo (não bloqueante) — a decisão é da recepcionista.

### 5.4 Conversão em membro

Quando um visitante decide se tornar membro da igreja:

- O secretário ou administrador acessa o registro de acolhimento e clica em **"Converter em membro"**
- O sistema pré-preenche o formulário de cadastro de membro com os dados já coletados no acolhimento
- O status do registro muda para `convertido_em_membro`
- A recepcionista **não executa** essa ação — apenas o secretário ou administrador

### 5.5 Lista para o pastor durante o culto

O pastor/dirigente do culto tem acesso a uma **visão simplificada e somente leitura** da lista de visitantes do culto em andamento, para realizar a apresentação pastoral durante a celebração. Essa visão exibe apenas: nome e tipo (visitante ou irmão).

---

## 6. Fluxo de Pedidos de Oração e Visita Pastoral

```
Recepcionista registra pedido
         │
         ▼
Sistema cria PedidoOracao com status: pendente
         │
         ▼
Notificação enviada ao Departamento de Evangelismo
         │
    ┌────┴────┐
    ▼         ▼
oracao    visita_pastoral / acompanhamento
    │         │
    ▼         ▼
Líder do  Líder do Evangelismo
Evangelismo agenda visita
ora e marca     │
como concluído  ▼
           status: em_andamento
                │
                ▼
           status: concluido
```

**Regras do fluxo:**

- A recepcionista **cria** o pedido e **visualiza** o status, mas **não altera** o status após o encaminhamento
- O líder ou secretário do departamento de Evangelismo é responsável por tratar e atualizar o status
- Pedidos com status `pendente` há mais de **7 dias** geram alerta no dashboard do secretário e do administrador
- Todo pedido é associado ao culto e à data de origem

---

## 7. Histórico de Visitas

### 7.1 O que é registrado

Cada `RegistroAcolhimento` alimenta automaticamente o histórico, sem necessidade de ação adicional. O histórico permite consultar:

- Visitantes por culto, semana, mês ou período personalizado
- Frequência de um mesmo visitante (mesmo nome + telefone em cultos diferentes)
- Total de conversões (`status = convertido_em_membro`) no período
- Pedidos de oração encaminhados e seus status

### 7.2 Quem pode consultar

| Perfil | Acesso ao histórico |
|---|---|
| Recepcionista | ✅ Apenas da própria congregação — somente leitura |
| Secretário local | ✅ Apenas da própria congregação |
| Secretário sede | ✅ Todas as congregações do campo |
| Administrador | ✅ Todas as congregações do campo |
| Líder | ❌ |
| Tesoureiro | ❌ |

### 7.3 Filtros disponíveis

- Busca por nome
- Tipo: Visitante / Irmão / Todos
- Culto (select)
- Período (date range)
- Status: Registrado / Encaminhado / Convertido em membro / Inativado
- Apenas com pedido de oração (checkbox)

---

## 8. Dashboard do Acolhimento

Exibido ao fazer login com perfil `acolhimento`. Atualizado em tempo real via Turbo Streams.

### Cards do dia

| Card | O que exibe |
|---|---|
| Total de registros hoje | Contagem de `RegistroAcolhimento` do dia na própria congregação |
| Visitantes | Contagem com `tipo = visitante` |
| Irmãos | Contagem com `tipo = irmao` |
| Pedidos de oração | Contagem de `PedidoOracao` com `status = pendente` do dia |

### Lista dos acolhidos de hoje

- Exibida logo abaixo dos cards
- Ordenada por `data_hora_registro DESC` (mais recente no topo)
- Cada item exibe: nome, tipo (badge), culto, horário do registro e ícone de WhatsApp se telefone preenchido
- Botão de edição visível apenas se dentro da janela de 30 minutos
- Estado vazio: _"Nenhum registro hoje. Clique em '+ Registrar visita' para começar."_

---

## 9. Regras de Segurança e Integridade

### 9.1 O que a recepcionista NUNCA pode fazer

- Excluir fisicamente qualquer registro
- Acessar dados de outras congregações (mesmo do mesmo tenant)
- Converter visitante em membro (exclusivo do secretário/administrador)
- Alterar status de pedidos de oração após encaminhamento
- Acessar qualquer módulo fora dos listados na seção 2.2 sem permissão explícita

### 9.2 Auditoria

Toda ação da recepcionista é registrada no `AuditLog`:

- Criação de registro de acolhimento
- Edição dentro da janela de 30 minutos
- Inativação de registro (com motivo)
- Criação de pedido de oração

### 9.3 Validações obrigatórias no sistema

- `institution_id` e `tenant_id` preenchidos automaticamente — nunca expostos no formulário
- `culto_id` validado: deve pertencer à mesma `institution_id` do usuário logado e estar ativo no dia
- `data_hora_registro` gerado no servidor via `Time.current` — nunca enviado pelo cliente

---

## 10. Referência Técnica (Rails 8 + Hotwire)

> Esta seção é de referência para a equipe de desenvolvimento. As regras de negócio estão nas seções anteriores.

### 10.1 Componentes e Controllers

| Componente | Responsabilidade |
|---|---|
| `Acolhimentos::ModalFormComponent` (ViewComponent) | Renderiza o formulário de registro em modal |
| `Acolhimentos::RegistroCardComponent` | Card de cada registro na listagem |
| `AcolhimentoController` (Stimulus) | Comportamentos client-side: máscara de telefone, toggle de campos condicionais, contador de tempo da janela de edição |

### 10.2 Turbo Streams esperados

| Ação | Stream | Comportamento |
|---|---|---|
| Criar registro | `prepend` em `#registros-list` | Novo card aparece no topo sem reload |
| Editar registro | `replace` no card correspondente | Card atualizado in-place |
| Inativar registro | `remove` do card ou `replace` com badge "Inativado" | Conforme configuração |
| Criar pedido de oração | `update` no card de métricas | Contador de pedidos atualizado |

### 10.3 Policy (Pundit)

```ruby
class AcolhimentoPolicy < ApplicationPolicy
  def create?
    user.acolhimento? || user.secretario_local? || user.secretario_sede? || user.administrador?
  end

  def update?
    return true if user.secretario_local? || user.secretario_sede? || user.administrador?
    # Recepcionista: apenas dentro da janela de 30 minutos
    user.acolhimento? && record.created_at > 30.minutes.ago
  end

  def inactivate?
    update? # mesma regra de janela
  end

  def historico?
    !user.lider? && !user.tesoureiro?
  end
end
```

### 10.4 Scope multi-tenant

```ruby
class AcolhimentoPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(institution_id: user.institution_id, tenant_id: user.tenant_id)
    end
  end
end
```

---

## 11. Glossário

| Termo | Definição |
|---|---|
| **Acolhimento** | Módulo responsável pelo registro e acompanhamento inicial de visitantes nos cultos |
| **Visitante** | Pessoa sem vínculo com nenhuma congregação — simpatizante ou novo convertido |
| **Irmão** | Crente membro de outra congregação ou ministério |
| **Culto** | Evento do tipo culto cadastrado no módulo Eventos com status `aprovado` ou `em_andamento` |
| **Pedido de Oração** | Solicitação de intercessão ou visita pastoral registrada durante o acolhimento |
| **Janela de edição** | Período de 30 minutos após o registro em que a recepcionista pode editar ou inativar |
| **Conversão em membro** | Fluxo pelo qual um visitante passa a ser membro — executado pelo secretário/administrador |
| **Encaminhamento** | Envio de um pedido de oração ou visita ao Departamento de Evangelismo para acompanhamento |
| **Inativação** | Remoção lógica de um registro com histórico — nunca exclusão física |
| **AuditLog** | Tabela de rastreabilidade de todas as ações executadas no sistema |
| **Tenant** | Ministério/Igreja contratante do Ekklesia — isolamento total entre tenants |
| **institution_id** | Identificador da congregação específica dentro de um tenant |

---

*Ekklesia — Documento interno · Versão 1.1 · Julho 2026*