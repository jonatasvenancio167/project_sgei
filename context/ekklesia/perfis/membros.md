# Contexto do Sistema: Ekklesia (Módulo: Gestão de Membros e Matriz de Perfis)

Você é um [Arquiteto de Software / Desenvolvedor Full-Stack especialista em Rails 8]. Use este documento para modelar a entidade de Membros, a matriz de permissões (RBAC), o controle de acesso por departamento e as regras de negócio de cada perfil.

---

## 1. Visão Geral (Domínio de Membros)

Os **Membros** são as pessoas vinculadas a uma congregação local que compõem o corpo da igreja. Eles formam a base do sistema e podem:
*   Participar de um ou mais departamentos simultaneamente.
*   Assumir cargos eclesiásticos/ministeriais (ex: Obreiro, Diácono, Presbítero).
*   Exercer papéis administrativos de liderança ou operação (ex: Líder de Departamento, Tesoureiro, Secretário, Mídia, etc.).

---

## 2. Regras do Cadastro de Membros

### Requisitos e Campos Obrigatórios:
*   `nome_completo` (string) — Obrigatório
*   `data_nascimento` (date) — Obrigatório
*   `endereco` (string/text) — Obrigatório
*   `congregacao_id` (foreign key) — Vínculo obrigatório com a congregação local.

### Regra de Autenticação e Acesso ao Sistema:
*   **Membros Comuns (Sem Departamento/Cargo):** Não possuem login ou conta de usuário (`User`) no sistema. Seu cadastro serve estritamente para controle interno da Secretaria (contagem de ativos, frequência, histórico e prevenção de evasão/limbo).
*   **Provisionamento de Acesso:** A conta de usuário para login é ativada apenas quando o membro é vinculado a pelo menos um **Departamento** ou **Cargo de Liderança/Administrativo**.
*   **Roadmap (Visão Futura):** Criação de um Portal do Membro institucional/White-label (sem acesso ao painel administrativo) para consulta de notícias, avisos e eventos locais.

---

## 3. Matriz de Perfis de Acesso (RBAC) e Responsabilidades

O sistema possui diferentes níveis de permissão. Cada perfil libera visualizações e ações específicas na aplicação:

### A. Pastor (Líder Geral / Administrador de Conteúdo)
*   **Nível de Acesso:** Administrador do Sistema.
*   **Responsabilidades:** Possui acesso total às funcionalidades estratégicas da igreja, relatórios gerais, acompanhamento do crescimento da comunidade, aprovações finais de nomeações de líderes e autorização para adição de novos membros aos departamentos.

### B. Secretário(a) (Super Administrador Operacional)
*   **Nível de Acesso:** Administrador Operacional Expandido (Acesso total + Funcionalidades exclusivas da Secretaria).
*   **Responsabilidades:**
    *   Cadastrar novos membros no sistema.
    *   Gerenciar acessos, permissões e perfis de usuários (inclusive definir o que membros com cargos eclesiásticos podem acessar).
    *   Validar e aprovar rascunhos de eventos solicitados pelos líderes para o calendário oficial.
    *   Criar escalas gerais de trabalho.
    *   Acompanhar o painel de aniversariantes da igreja.
    *   Emitir e registrar cartas de recomendação para membros saindo para outros ministérios.
    *   Receber e cadastrar cartas de recomendação de novos membros vindos de fora.

### C. Financeiro (Tesouraria)
*   **Nível de Acesso:** Gestão Financeira.
*   **Responsabilidades:**
    *   Controle do caixa da igreja (entradas e saídas).
    *   Análise, lançamento e aprovação de despesas operacionais.
    *   Registro e conferência de dízimos e ofertas (entradas recorrentes e avulsas).
    *   Aprovação de solicitações de compra enviadas por outros módulos (ex: Almoxarifado).

### D. Almoxarifado (Patrimônio e Insumos)
*   **Nível de Acesso:** Gestão de Estoque e Patrimônio.
*   **Responsabilidades:**
    *   Controle de bens materiais, limpeza e conservação da instituição.
    *   Gestão do estoque de produtos de limpeza, consumo e manutenção.
    *   Solicitação formal de compras de insumos para aprovação do setor Financeiro.

### E. Líder de Departamento
*   **Nível de Acesso:** Gestão Específica do(s) seu(s) Departamento(s).
*   **Responsabilidades:**
    *   Solicitar adição de novos membros ao departamento (sujeito à aprovação do Pastor).
    *   Visualizar e acompanhar a lista de membros ativos do departamento.
    *   Acompanhar datas de aniversário dos liderados e receber alertas diários.
    *   Gerenciar a caixinha/caixa interno do departamento.
    *   Criar atividades, escalas internas, comunidades e pequenos grupos.
    *   Propor eventos no calendário da igreja (via rascunho a ser aprovado pela Secretaria).

---

## 4. Regras Especiais de Modelagem e Permissões Dinâmicas

1. **Atribuição Granular pela Secretaria (RBAC Flexível):**
   * Membros com cargos eclesiásticos (ex: Diácono, Obreiro, Presbítero) que precisem acessar o sistema terão seus menus, telas e permissões (`criar`, `visualizar`, `editar`, `deletar`) customizados individualmente pelo **Secretário**, conforme as regras e necessidades da congregação.

2. **Multi-Departamentos e Múltiplos Papéis (Contexto Relativo N:N):**
   * Um mesmo membro pode pertencer a **múltiplos departamentos ao mesmo tempo**.
   * O papel do usuário muda de acordo com o contexto do departamento:
     * Pode ser **Líder** no *Departamento de Mídia* e **Membro Liderado** no *Grupo de Louvor*.
     * Pode ser **Líder simultaneamente** de dois departamentos diferentes (ex: Louvor e Mídia).
   * **Requisito de UI/UX:** A interface do sistema (construída via Rails + Hotwire) deve adaptar as permissões exibidas na tela de acordo com o departamento selecionado/gerenciado pelo usuário no momento.