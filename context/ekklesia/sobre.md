# Contexto do Sistema: Ekklesia (Visão Geral e Arquitetura)

Você é um [Arquiteto de Software / Engenheiro de Software Full-Stack especialista em Ruby on Rails]. Use o contexto abaixo para compreender o ecossistema do projeto Ekklesia, suas diretrizes de negócio e sua pilha tecnológica.

---

## 1. O que é o Ekklesia?

O **Ekklesia** é um sistema completo de gestão para igrejas e comunidades religiosas, desenvolvido para simplificar a administração global — do controle financeiro à tomada de decisões estratégicas de alto impacto.

### Objetivos do Sistema:
*   **Tomada de Decisão Baseada em Dados:** Apoiar líderes religiosos com estatísticas precisas sobre a saúde da comunidade.
*   **Engajamento e Liderança:** Mapear o engajamento dos membros para nomeação assertiva em cargos de confiança.
*   **Mapeamento de Impacto:** Mensurar o crescimento da igreja e sua influência/impacto na região local.
*   **Expansão:** Facilitar a gestão administrativa para permitir um crescimento saudável da comunidade e a expansão do evangelho.

---

## 2. Arquitetura do Sistema

*   **Padrão Arquitetural:** Monolito Modular.
*   **Abordagem de Telas/Acessos:** O sistema possui módulos isolados por **Perfis de Usuário (Roles)**. Isso garante uma experiência limpa (UI/UX), onde cada usuário visualiza apenas as ferramentas e dados estritamente necessários para o seu papel.

---

## 3. Perfis e Módulos do Sistema

### Perfis de Acesso (Roles / RBAC):
1.  **Membro:** Acesso a informações pessoais, eventos, grupos e formulários.
2.  **Pastor / Líder Geral:** Visão macro, relatórios estratégicos, aprovações finais e gestão de líderes.
3.  **Secretaria:** Gestão de membros, cadastros, relatórios e aprovação de eventos.
4.  **Tesouraria / Financeiro:** Gestão de entradas, saídas, dízimos, ofertas e relatórios financeiros.
5.  **Almoxarifado:** Controle de patrimônio, inventário e recursos materiais da igreja.
6.  **Departamentos:** Gestão específica para líderes de ministérios (Sede e Congregações locais).
7.  **Mídias:** Comunicação, transmissões, artes e escala da equipe de mídia/som.
8.  **Master (T.I / Admin):** Controle total da plataforma, configurações de sistema e gestão de acessos do ecossistema.

---

## 4. Stack Tecnológica

*   **Linguagem:** Ruby 3.2.2
*   **Framework Web:** Ruby on Rails 8.0.0
*   **Banco de Dados:** PostgreSQL
*   **Frontend / Reatividade:** Hotwire (Turbo + Stimulus)
*   **Containerização:** Docker