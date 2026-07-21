# Contexto do Sistema: Ekklesia (Módulo: Pastor, Co-Pastor e Acolhimento)

Você é um [Arquiteto de Software / Desenvolvedor Full-Stack especialista em Rails 8]. Use este documento para modelar as entidades, dashboards, fluxos de trabalho e permissões referentes à Liderança Religiosa e ao Acolhimento de Visitantes.

---

## 1. Pastor / Líder Religioso (Admin Geral)

O **Pastor** é o administrador geral da instituição. Seu perfil combina ferramentas de alta gestão estratégica e analítica com recursos de cuidado pastoral e acompanhamento comunitário.

### A. Fluxo de Validação de Eventos (Agenda):
*   O Pastor (assim como os Líderes de Departamento) cria solicitações/rascunhos de eventos.
*   **Papel do Secretário:** Atua estritamente como **Organizador e Gestor de Agenda**. Ele valida se há choque/conflito de datas/horários no calendário institucional antes de confirmar e publicar o evento.

### B. Funcionalidades Pastoral & Estratégica:
*   **Dashboards Analíticos:** Métricas de crescimento, batizados, retenção de membros e índice de influência comunitária.
*   **Gestão de Liderança:** Nomeação e visualização de Líderes de Departamentos, criação de novos departamentos e acompanhamento do pipeline de novos talentos (membros promissores para assumir cargos).
*   **Alertas e Cuidado:** Notificações diárias de aniversariantes, lista de membros ausentes/em risco de evasão ("limbo") e central de pedidos de oração.
*   **Agendamentos:** Módulo para gestão de mentorias, aconselhamentos e compromissos na agenda pastoral.

---

## 2. Módulo de Acolhimento e Recepção (Funil Evangelístico)

### A. Captação de Visitantes (Página de Acolhimento):
*   Interface otimizada para uso rápido pela **Equipe de Recepção/Acolhimento** durante os cultos e eventos.
*   **Campos de Registro do Visitante:**
    *   `nome_completo` (string)
    *   `telefone` / `whatsapp` (string)
    *   `pertence_a_outra_congregacao` (boolean)
    *   `nome_congregacao_origem` (string, opcional)
    *   `observacoes` (text)

### B. Fluxo Pastoral e Integração com Evangelismo:
*   **Apresentação de Visitantes:** O Pastor visualiza no seu painel em tempo real a lista de visitantes do dia para fazer a recepção/apresentação formal no culto.
*   **Encaminhamento Evangelístico:**
    *   Se o visitante **não pertencer a nenhuma igreja**, o sistema o classifica no funil de acolhimento.
    *   A liderança de evangelismo/integração ganha acesso a essa lista para realizar contatos pós-culto, acompanhamento e novos convites, promovendo a expansão do evangelho.

---

## 3. Co-Pastor (Perfil de Suporte à Liderança)

*   **Comportamento Padrão (Default Restrictions):** O Co-Pastor possui responsabilidades pastorais, porém seu acesso inicial ao sistema é **limitado por padrão** se comparado ao Pastor Titular (Admin).
*   **Delegação de Permissões:** O acesso a módulos críticos (como exclusão de dados, alterações na estrutura de departamentos ou relatórios financeiros estratégicos) é liberado dinamicamente **apenas se o Pastor Titular ou o Admin do sistema conceder autorização explicita**.
*   **Atuação:** Focado no acompanhamento local, ministração, recepção de pedidos de oração, acompanhamento de membros e condução de projetos autorizados.