# Contexto do Sistema: Gestão de Igreja (Módulo: Departamentos)

Você é um [Arquiteto de Software / Engenheiro de Software Full-Stack]. Use o contexto abaixo para guiar o desenvolvimento do sistema, criação de tabelas, APIs ou regras de negócio.

---

## 1. Perfis de Usuário e Papéis (RBAC)

*   **Pastor (Líder Geral):**
    *   Autoridade máxima.
    *   Responsável por nomear/autorizar a criação de Líderes de Departamento.
    *   Aprova a adição de membros aos departamentos.
*   **Secretário(a):**
    *   Operador administrativo do sistema.
    *   Registra os Líderes de Departamento no sistema e gerencia seus acessos (CRUD de líderes).
    *   Valida e aprova rascunhos de eventos propostos pelos líderes no calendário da igreja.
*   **Líder de Departamento (Geral/Sede):**
    *   Possui acesso de leitura, escrita, edição e exclusão (CRUD) dentro do escopo do seu departamento.
    *   Gerencia membros (adiciona pós-permissão do Pastor, remove se saírem do departamento).
    *   Acompanha métricas, faltas, evolução espiritual e aniversariantes.
    *   Solicita eventos via rascunho.
    *   *Escopo Expandido:* Atua a nível de Campo (Sede e Congregações).
*   **Líder de Departamento Local (Congregação):**
    *   Mesmas funções de gestão interna do líder de sede, mas estrito **apenas** à sua congregação local.
    *   Não visualiza dados de outras congregações nem do campo geral.

---

## 2. Hierarquia e Escopo de Ação (Sede vs. Local)

### A. Nível Local (Líder Local)
*   **Ações permitidas:** Criar trabalhos locais (evangelismo, oração, pequenos grupos, visitas, retiros) envolvendo apenas os membros locais.
*   **Bloqueios:** Não acompanha líderes de outras congregações. Não agenda eventos de nível "Campo" (geral).

### B. Nível Campo/Sede (Líder Sede / Master)
*   **Ações locais:** Realiza as mesmas tarefas locais que o líder local na igreja sede.
*   **Ações de Campo:** 
    *   Acompanha e gerencia a liderança local das congregações (campo).
    *   Cria eventos de nível "Campo" que notificam todos os líderes locais.
    *   Configura regras de notificação (Ex: Exigir "Verificação de Leitura / Confirmação de Presença" onde o líder local deve marcar se vai comparecer ou não).

---

## 3. Fluxos de Trabalho (Workflows) e Regras de Negócio

### Fluxo de Eventos:
1. Líder de Departamento cria um **Rascunho de Evento**.
2. O sistema valida contra o Calendário Geral da Igreja para evitar conflitos.
3. O **Secretário** revisa, valida e aprova o rascunho.
4. O evento é publicado oficialmente no Calendário.

### Fluxo de Membros:
*   Para adicionar um membro: `Líder solicita` -> `Pastor autoriza` -> `Membro é vinculado`.
*   Para remover um membro: `Líder remove diretamente` (se o membro não pertencer mais ao departamento).

### Módulo de Engajamento e Relatórios:
*   **Dashboard / Visão Geral:** Exibe métricas de faltas, evolução espiritual e o próximo aniversariante do departamento.
*   **Automação de Aniversários:** O sistema envia uma notificação/mensagem no dia do aniversário do liderado para o Líder do Departamento, incentivando o parabéns da liderança e do grupo.
*   **Formulários:** Criação de formulários internos/externos para inscrições em eventos, com dashboard de métricas de inscritos.