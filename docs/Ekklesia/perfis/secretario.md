# Ekklesia — Regras de Negócio
## Perfil Secretário · Igreja Local & Igreja Sede

> **Versão 1.0 · Julho 2026**
> Documento interno — uso restrito à equipe de produto

---

## Sumário

1. [Visão Geral](#1-visão-geral)
2. [Princípios Gerais de Negócio](#2-princípios-gerais-de-negócio)
3. [Permissões por Módulo](#3-permissões-por-módulo)
4. [Módulo Membros](#4-módulo-membros)
5. [Módulo Eventos](#5-módulo-eventos)
6. [Módulo Departamentos](#6-módulo-departamentos)
7. [Módulo Escalas](#7-módulo-escalas)
8. [Módulo Formulários](#8-módulo-formulários)
9. [Usuários e Configurações](#9-usuários-e-configurações)
10. [Credenciais Oficiais](#10-credenciais-oficiais-exclusivo-secretário-sede)
11. [Regras de Segurança e Integridade](#11-regras-de-segurança-e-integridade)
12. [Glossário](#12-glossário)

---

## 1. Visão Geral

O secretário é o **braço operacional** do pastor/administrador. Enquanto o pastor define a visão e autoriza decisões estratégicas, o secretário executa, registra e organiza.

O Ekklesia distingue dois escopos do perfil secretário com atuação diferente:

| Característica | Secretário Local | Secretário Sede |
|---|---|---|
| Escopo de atuação | Própria congregação | Todo o campo (tenant) |
| Role no sistema | `secretario_local` | `secretario_sede` |
| Cria congregações filhas | ❌ | ✅ |
| Emite credenciais oficiais | ❌ | ✅ |
| Transfere membros entre congregações | Solicita apenas | Aprova e executa |
| Envia circulares institucionais | ❌ | ✅ |
| Visualiza relatórios consolidados | ❌ | ✅ |
| Gerencia usuários | Própria congregação | Qualquer congregação do campo |
| Altera perfil de secretário | ❌ | ❌ (exclusivo do master) |

---

## 2. Princípios Gerais de Negócio

### 2.1 Nunca deletar, sempre inativar

Membros, usuários e departamentos **nunca são excluídos fisicamente** do banco de dados. Toda remoção gera um registro de inativação com:

- Data e hora da inativação
- Motivo (campo obrigatório)
- ID do usuário que executou a ação
- Status anterior e novo

> **Regra técnica:** toda tabela que o secretário pode "excluir" deve ter colunas `status`, `inactivated_at`, `inactivated_by_id` e `inactivation_reason`. A exclusão física é proibida para esses registros.

### 2.2 Auditoria obrigatória

Toda ação executada pelo secretário é registrada no `AuditLog` com:

- `user_id` — quem executou
- `action` — o que foi feito (`created`, `updated`, `inactivated`, `approved`, `rejected`)
- `resource_type` e `resource_id` — o que foi afetado
- `changes` — snapshot antes/depois em JSON
- `created_at` — timestamp preciso

### 2.3 Aprovação em cascata

O fluxo de aprovação segue a hierarquia do sistema:

- **Líder** cria como rascunho → **Secretário** aprova ou recusa
- **Secretário local** cria ações cross-congregação → **Secretário sede** aprova
- **Secretário sede** cria ações estratégicas → **Administrador (pastor)** aprova

### 2.4 Isolamento multi-tenant

- Secretário local enxerga apenas dados da **própria congregação**
- Secretário sede enxerga apenas dados do **próprio tenant** (sede + filhas)
- Nenhum secretário enxerga dados de outro ministério/tenant

### 2.5 Separação de responsabilidades

O secretário **nunca altera permissões de módulos**. Essa responsabilidade é exclusiva do usuário master nas Configurações do sistema. O secretário gerencia *quem* são os usuários, não *o que* cada perfil pode fazer.

---

## 3. Permissões por Módulo

| Módulo | Sec. Local | Sec. Sede | Master |
|---|---|---|---|
| Visão Geral / Dashboard | ✅ Própria congregação | ✅ Todo o campo | ✅ Todo o campo |
| Calendário | ✅ Visualizar | ✅ Visualizar | ✅ Completo |
| Eventos | ✅ CRUD própria congregação | ✅ CRUD qualquer congregação | ✅ Completo |
| Departamentos | ✅ CRUD própria congregação | ✅ CRUD qualquer congregação | ✅ Completo |
| Membros | ✅ CRUD própria congregação | ✅ CRUD + transferência + credencial | ✅ Completo |
| Escalas | ✅ CRUD própria congregação | ✅ CRUD + compartilhar com filhas | ✅ Completo |
| Formulários | ✅ CRUD própria congregação | ✅ CRUD + padronizar para filhas | ✅ Completo |
| Acolhimento | ✅ Visualizar + registrar | ✅ Visualizar + registrar | ✅ Completo |
| Aniversariantes | ✅ Visualizar | ✅ Visualizar | ✅ Completo |
| Financeiro | ❌ Sem acesso* | ❌ Sem acesso* | ✅ Completo |
| Configurações — Sistema | ✅ Parcial (própria congregação) | ✅ Parcial (todo o campo) | ✅ Total |
| Configurações — Permissões | ❌ | ❌ | ✅ Exclusivo |
| Configurações — Congregações | ❌ | ✅ | ✅ |
| Relatórios consolidados | ❌ | ✅ | ✅ |
| Comunicação institucional | ❌ | ✅ | ✅ |

> \* O acesso ao módulo Financeiro pode ser concedido explicitamente pelo master nas Configurações de Permissões, caso a igreja necessite que o secretário tenha visibilidade financeira.

---

## 4. Módulo Membros

### 4.1 Secretário Local

**Pode fazer:**
- Criar novo membro com todos os campos do cadastro
- Editar dados cadastrais de qualquer membro da própria congregação
- Visualizar lista completa de membros da própria congregação
- Alterar cargo/função do membro (ex: promover a diácono, líder, auxiliar)
- Registrar eventos de vida: batismo, casamento, óbito
- Inativar membro (com motivo obrigatório — nunca excluir)
- Buscar membro por nome, CPF ou email
- Exportar lista de membros da própria congregação (PDF/CSV)

**Não pode fazer:**
- Excluir fisicamente um membro
- Ver membros de outras congregações
- Aprovar transferência entre congregações — apenas solicitar
- Emitir credenciais oficiais (pastor, presbítero, diácono)
- Alterar `tenant_id` ou `institution_id` de um membro

### 4.2 Secretário Sede

Tudo que o secretário local pode, mais:

- Visualizar e editar membros de todas as congregações do campo
- Aprovar ou recusar solicitações de transferência entre congregações
- Emitir credenciais oficiais com número de registro e data de validade
- Supervisionar registros de batismo, casamento e óbito de todo o campo
- Exportar relatório consolidado de membros de todo o campo
- Consultar histórico de transferências de qualquer membro

### 4.3 Fluxo de Transferência de Membros

| Etapa | Responsável | Status |
|---|---|---|
| 1. Secretário local solicita transferência | Secretário Local | `pendente` |
| 2. Sistema notifica secretário sede | Sistema (automático) | — |
| 3. Secretário sede revisa e decide | Secretário Sede | `aprovada` / `recusada` |
| 4. Se aprovada: membro muda de congregação | Sistema (automático) | `concluída` |
| 5. Ambos os secretários são notificados | Sistema (automático) | — |
| 6. Histórico de transferência é registrado | Sistema (automático) | — |

> **Regra técnica:** criar tabela `member_transfers` com campos: `member_id`, `from_institution_id`, `to_institution_id`, `requested_by_id`, `approved_by_id`, `status`, `reason`, `requested_at`, `resolved_at`.

---

## 5. Módulo Eventos

### 5.1 Permissões

- **Secretário local:** CRUD completo de eventos da própria congregação
- **Secretário sede:** CRUD de eventos em qualquer congregação do campo
- **Ambos:** visualizar calendário geral para evitar conflitos de data

### 5.2 Fluxo de Aprovação de Eventos (vindos de Líderes)

Quando um líder cria um evento como rascunho e solicita aprovação:

- Secretário recebe notificação com badge no sino
- Pode **Aprovar** → evento publicado no calendário
- Pode **Recusar** → deve informar motivo → líder é notificado
- Pode **Editar** antes de aprovar (ex: corrigir data ou local)

### 5.3 Status de Evento

```
rascunho → aguardando_aprovacao → aprovado
                               ↘ recusado
```

### 5.4 Assembleias Gerais _(exclusivo Secretário Sede)_

- Criar convocação de assembleia com pauta, data e lista de congregações convocadas
- Enviar convocação como circular para todos os secretários locais das filhas
- Registrar ata da assembleia no sistema
- Controlar presença das congregações convocadas

---

## 6. Módulo Departamentos

- Criar, editar e inativar departamentos
  - Local: apenas na própria congregação
  - Sede: em qualquer congregação do campo
- Definir e alterar o líder de um departamento
- Visualizar membros de qualquer departamento dentro do escopo permitido
- Não pode criar dois departamentos com o mesmo nome na mesma congregação

> **Regra de unicidade:** o sistema deve bloquear a criação de departamento com nome duplicado dentro da mesma `institution_id`. A validação deve acontecer tanto no front quanto no back-end (model validation + constraint no banco).

---

## 7. Módulo Escalas

### 7.1 Secretário Local

- Criar, editar e visualizar escalas da própria congregação
- Adicionar membros às colunas de cada culto/evento
- Publicar escala (muda status de `rascunho` para `publicado`)
- Não pode compartilhar escala com outras congregações

### 7.2 Secretário Sede

Tudo que o secretário local pode, mais:

- Visualizar escalas de todas as congregações do campo
- Compartilhar escala da sede com congregações filhas selecionadas
- Filhas recebem a escala compartilhada como **somente leitura** com badge _"Compartilhada pela sede"_

### 7.3 Regra de Conflito de Membros na Escala

Um membro pode pertencer a múltiplos departamentos. Ao escalá-lo em uma data:

1. Sistema verifica se o membro já está escalado em outro departamento na mesma data
2. Se houver conflito: exibir aviso ⚠ com nome do departamento conflitante
3. O secretário **pode confirmar** mesmo com conflito (não bloqueante)
4. O conflito fica registrado e visível no card do evento

---

## 8. Módulo Formulários

- Criar, editar, publicar e arquivar formulários
  - Local: apenas na própria congregação
  - Sede: pode criar formulários-padrão e distribuir para todas as filhas
- Formulário distribuído pela sede: filhas visualizam e aplicam, mas **não editam o modelo**
- Visualizar e exportar respostas dos formulários
- **Não pode excluir** formulário com respostas — apenas arquivar

---

## 9. Usuários e Configurações

### 9.1 Secretário Local

- Criar e editar usuários da própria congregação
- Inativar usuários (nunca excluir)
- Alterar perfil de usuários, **exceto:**
  - Administrador (pastor)
  - Secretário sede
  - Outro secretário local (não pode rebaixar a si mesmo)
- Editar informações da própria congregação: nome, logo, endereço, cor primária
- **Não pode** criar novas congregações filhas
- **Não pode** alterar permissões de módulos (exclusivo do master)

### 9.2 Secretário Sede

Tudo que o secretário local pode, mais:

- Criar e gerenciar usuários de qualquer congregação do campo
- Criar novas congregações filhas e definir seus responsáveis
- Editar informações de qualquer congregação do campo
- Padronizar configurações para todas as filhas (ex: tipos de culto, categorias)
- **Não pode** alterar o perfil do administrador master
- **Não pode** alterar permissões de módulos (exclusivo do master)

### 9.3 Comunicação Institucional _(exclusivo Secretário Sede)_

- Redigir e enviar circulares oficiais para todas ou algumas congregações filhas
- As filhas recebem a circular como notificação + registro no módulo de comunicação
- Histórico de circulares enviadas fica disponível para consulta
- Secretário local pode **visualizar** circulares recebidas, mas não responder pelo sistema

---

## 10. Credenciais Oficiais _(exclusivo Secretário Sede)_

O secretário da sede pode emitir credenciais para ministros do campo:

| Tipo de Credencial | Emitida para | Validade padrão |
|---|---|---|
| Pastor | Membro ordenado ao pastorado | 5 anos |
| Presbítero | Membro ordenado ao presbitério | 3 anos |
| Diácono | Membro ordenado ao diaconato | 3 anos |
| Auxiliar | Membro em cargo auxiliar | 1 ano |
| Missionário | Membro em missões | 2 anos |

**Regras:**
- Credencial tem **número de registro único** gerado pelo sistema
- Pode ser exportada como PDF para impressão
- Sistema alerta **60 dias antes** do vencimento
- Pode ser revogada com motivo registrado no histórico

> **Regra técnica:** criar tabela `credentials` com campos: `id`, `member_id`, `institution_id`, `tenant_id`, `type`, `registration_number`, `issued_by_id`, `issued_at`, `expires_at`, `status` (`ativa`, `expirada`, `revogada`), `revocation_reason`.

---

## 11. Regras de Segurança e Integridade

### 11.1 O que o secretário NUNCA pode fazer

> ⚠️ Estas são restrições absolutas — não podem ser alteradas nem pelo master.

- Excluir fisicamente membros, usuários ou departamentos
- Alterar permissões de módulos (exclusivo do master)
- Ver ou acessar dados de outro tenant/ministério
- Alterar o perfil do administrador master
- Aprovar a própria solicitação (**self-approval bloqueado** pelo sistema)
- Acessar módulo Financeiro sem concessão explícita do master

### 11.2 Validações obrigatórias no sistema

- `institution_id` e `tenant_id` são sempre preenchidos automaticamente pelo contexto do usuário logado — **nunca pelo secretário manualmente**
- Toda listagem filtra por `tenant_id` antes de qualquer outro critério
- O secretário local nunca recebe no payload dados fora do seu `institution_id`
- O secretário sede nunca recebe dados fora do seu `tenant_id`

---

## 12. Glossário

| Termo | Definição |
|---|---|
| **Tenant** | Ministério/Igreja contratante do Ekklesia. Isolamento total entre tenants. |
| **Sede** | Instituição raiz do tenant. `parent_institution_id IS NULL`. |
| **Congregação filha** | Unidade vinculada à sede. `parent_institution_id = id da sede`. |
| **Secretário Local** | Atua apenas na própria congregação. Role: `secretario_local`. |
| **Secretário Sede** | Atua em todo o campo do tenant. Role: `secretario_sede`. |
| **Master** | Usuário com permissão suprema. Único que altera permissões de módulos. |
| **Inativação** | Remoção lógica com histórico. Nunca exclusão física. |
| **AuditLog** | Tabela de rastreabilidade de todas as ações no sistema. |
| **Credencial** | Documento oficial emitido pelo secretário sede para ministros. |
| **Circular** | Comunicado oficial enviado da sede para as congregações filhas. |
| **Rascunho** | Status inicial de eventos criados por líderes — aguarda aprovação do secretário. |
| **Self-approval** | Auto-aprovação bloqueada — o secretário não pode aprovar suas próprias solicitações. |

---

*Ekklesia — Documento interno · Versão 1.0 · Julho 2026*