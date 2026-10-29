Atue como engenheiro de software sênior responsável pelo projeto Ekklesia, um sistema de gestão de igrejas.

Implemente perfis padrão de acesso para facilitar o cadastro de membros, respeitando a arquitetura, as convenções e o mecanismo de autorização existentes no repositório.

## 1. Analise o projeto antes de implementar

Identifique:

- Como igreja, usuário, membro, ministério, perfil e permissão estão representados.
- Como funciona a autenticação e a autorização.
- Como os dados são isolados entre igrejas.
- Como funciona o cadastro de membros.
- Se já existem perfis padrão, seeds, serviços de provisionamento ou componentes reutilizáveis.

Reutilize a estrutura existente. Não crie um segundo mecanismo de autorização. Quando algum conceito descrito neste prompt não existir, adapte sua implementação à arquitetura atual e explique a decisão.

## 2. Objetivo

Disponibilizar sete perfis padrão para cada igreja, permitindo selecionar os acessos adequados ao cadastrar ou editar um membro.

Separe os seguintes conceitos:

- **Perfil de acesso:** determina o que a pessoa pode fazer no sistema.
- **Ministério:** equipe ou área em que a pessoa participa.
- **Cargo ou função:** responsabilidade exercida na igreja.
- **Situação do membro:** condição cadastral, como ativo ou inativo.

Cargo, ordenação religiosa ou participação em um ministério não devem conceder permissões automaticamente.

## 3. Perfis padrão

Use identificadores estáveis, independentes dos nomes exibidos. Se o projeto já possui identificadores equivalentes, preserve-os.

### Membro — `member`

Perfil base, inicialmente selecionado no cadastro.

Permissões:

- Consultar agenda e eventos publicados para seu público.
- Realizar e consultar as próprias inscrições.
- Visualizar e responder às próprias escalas.
- Consultar e atualizar os campos permitidos do próprio cadastro.

Restrições:

- Não acessar cadastros de outros membros.
- Não administrar ministérios, usuários, perfis ou configurações.
- Não acessar dados financeiros ou registros pastorais restritos.

### Voluntário — `volunteer`

Permissões adicionais às de Membro:

- Informar disponibilidade para servir.
- Consultar atividades e materiais compartilhados com suas equipes.
- Participar e responder às escalas dos ministérios aos quais está vinculado.

Restrições:

- Não administrar integrantes ou escalas de outras pessoas.
- Não acessar materiais privados de equipes das quais não participa.

### Líder de ministério — `ministry_leader`

Permissões adicionais às de Voluntário:

- Organizar atividades e escalas dos ministérios sob sua liderança.
- Gerenciar os vínculos de participantes nesses ministérios.
- Consultar os dados cadastrais mínimos necessários para organizar a equipe.
- Gerenciar os materiais específicos da área.

Exemplos, quando os módulos existirem:

- Louvor: repertório, músicas e setlists.
- Mídia: acervo e materiais da equipe.
- Acolhimento: visitantes e acompanhamento atribuído à equipe.
- Almoxarifado: materiais e movimentações sob responsabilidade da área.

Restrições:

- A liderança de um ministério não concede acesso administrativo a outro.
- Não alterar perfis de acesso ou dados cadastrais gerais dos membros.
- Não receber acesso financeiro ou pastoral por ser líder.

O vínculo de liderança deve ser explícito. Apenas participar do ministério não é suficiente.

### Secretaria — `secretary`

Permissões adicionais às de Membro:

- Cadastrar e atualizar membros da própria igreja.
- Administrar informações cadastrais e vínculos organizacionais.
- Organizar eventos, inscrições e processos de acolhimento.
- Consultar relatórios cadastrais.

Restrições:

- Não consultar registros pastorais restritos.
- Não administrar movimentações financeiras.
- Não conceder perfis de acesso por padrão.

Cadastrar uma pessoa como líder, pastor ou tesoureiro no campo de cargo não concede o perfil de acesso correspondente.

### Financeiro / Tesouraria — `finance`

Permissões adicionais às de Membro:

- Gerenciar receitas, despesas, categorias e registros financeiros.
- Consultar relatórios financeiros.
- Consultar apenas os dados de pessoas necessários às operações financeiras.

Restrições:

- Não administrar membros, perfis ou configurações gerais.
- Não acessar registros pastorais restritos.
- Aprovar pagamentos deve ser uma permissão separada de registrar ou editar lançamentos. Não conceder aprovação automaticamente com este perfil.

### Pastoral — `pastoral`

Permissões adicionais às de Membro:

- Consultar informações cadastrais necessárias ao acompanhamento da comunidade.
- Consultar atividades e indicadores dos ministérios.
- Criar e acompanhar registros pastorais, quando o módulo existir.

Restrições:

- Registros pastorais restritos devem respeitar responsáveis e compartilhamentos explícitos.
- O perfil não concede acesso automático a todos os registros pastorais.
- Não concede acesso financeiro, gestão de perfis ou configurações administrativas.

### Administrador da igreja — `church_admin`

Permissões:

- Administrar configurações, usuários, perfis e permissões da própria igreja.
- Gerenciar os módulos administrativos existentes.
- Conceder e revogar acessos dentro da própria igreja.

Restrições:

- Não acessar ou administrar outras igrejas.
- Não conceder privilégios de administrador da plataforma.
- Não receber acesso automático ao conteúdo de registros pastorais restritos.
- Aprovação financeira continua dependendo da permissão específica.

O perfil Administrador da plataforma, se existir, deve permanecer separado e não aparecer como opção no cadastro de membros.

## 4. Regras de cadastro e composição

1. Todo novo cadastro deve começar com Membro selecionado.
2. Cadastrar um membro não deve criar credenciais, enviar convite ou conceder acesso ao sistema automaticamente.
3. Se houver criação de acesso ou envio de convite, mantenha essa ação explícita e reutilize o fluxo existente.
4. Uma pessoa pode acumular perfis, como Secretaria e Voluntário.
5. As permissões são cumulativas, respeitando os escopos de cada concessão.
6. Uma permissão ampla de um módulo não deve ampliar o escopo de outro.
7. Recursos sem concessão explícita devem permanecer bloqueados.
8. A composição entre os perfis deve reutilizar o mecanismo existente, sem duplicar permissões desnecessariamente.
9. Ao remover uma concessão, revogue o acesso derivado dela, preservando acessos válidos obtidos por outros perfis.
10. Revogar liderança ou participação deve atualizar imediatamente o acesso aos respectivos recursos.

## 5. Isolamento e autorização

- Todas as concessões devem pertencer à igreja correta.
- Valide no backend tanto a ação quanto a igreja e o escopo do recurso.
- Não confie em IDs, perfis ou ministérios enviados pelo frontend.
- Bloqueie acessos indevidos por URL direta, chamadas à API e manipulação de parâmetros.
- Listagens, buscas, relatórios e exportações devem aplicar as mesmas regras.
- Um usuário que participa de mais de uma igreja deve possuir acessos independentes em cada uma.
- Apenas atores com permissão explícita de gestão de acessos podem conceder ou revogar perfis.
- Impeça que usuários ampliem os próprios privilégios.
- Preserve pelo menos um administrador ativo por igreja, considerando também desativação, exclusão e remoção de acesso.
- Registre alterações de perfis e permissões no mecanismo de auditoria existente. Se não houver, implemente um registro mínimo com ator, destinatário, igreja, alteração e data.

## 6. Experiência no formulário

Apresente separadamente:

- Perfis de acesso.
- Ministérios.
- Cargo ou função.
- Situação cadastral.
- Opção de acesso ao sistema, quando aplicável.

Para cada perfil, exiba nome e descrição curta.

Regras da interface:

- Permitir selecionar múltiplos perfis.
- Exibir Membro como seleção inicial.
- Mostrar controles de concessão apenas a quem possui autorização.
- Quando Líder de ministério for selecionado, exigir a indicação dos ministérios sob sua liderança.
- Distinguir participação de liderança.
- Se o operador não puder gerenciar acessos, o backend deve aplicar apenas o perfil base no novo cadastro e rejeitar tentativas de incluir perfis privilegiados.
- Na edição, preservar concessões existentes quando o operador não tiver permissão para alterá-las.

Evite apresentar listas extensas de permissões técnicas no cadastro. Use os perfis como atalhos compreensíveis.

## 7. Provisionamento dos perfis padrão

- Crie os sete perfis para igrejas existentes e para novas igrejas.
- Faça o processo ser idempotente: executá-lo novamente não deve duplicar perfis, permissões ou vínculos.
- Use identificadores estáveis e unicidade no escopo adequado.
- Preserve perfis personalizados e concessões existentes.
- Se um perfil equivalente já existir, reutilize-o por meio de uma associação explícita; não deduza equivalência apenas pelo nome.
- Não promova membros existentes nem atribua perfis privilegiados automaticamente.
- Identifique os perfis padrão para evitar exclusão acidental.
- Preserve identificadores usados pelo sistema mesmo que os nomes exibidos sejam personalizados.
- Se o mecanismo atual permitir personalização de permissões, não sobrescreva alterações da igreja silenciosamente em futuras execuções do provisionamento.
- Não crie permissões ou interfaces funcionais para módulos que ainda não existem. Informe quais capacidades ficaram pendentes.

## 8. Critérios de aceite

Verifique, com testes adequados à estrutura do projeto:

1. Um novo membro recebe somente o perfil base inicialmente.
2. Um cadastro pode existir sem credenciais de acesso.
3. Um voluntário visualiza apenas recursos compartilhados com suas equipes.
4. Um líder administra somente os ministérios sob sua liderança.
5. Secretaria cadastra membros sem conceder perfis privilegiados.
6. Financeiro não obtém acesso pastoral nem aprovação automática de pagamentos.
7. Pastoral respeita as restrições de cada registro de acompanhamento.
8. Administrador da igreja não acessa outra igreja nem privilégios da plataforma.
9. A combinação de perfis preserva os escopos de cada permissão.
10. A remoção de um perfil revoga somente os acessos derivados dele.
11. O sistema bloqueia alterações de perfil feitas sem autorização, inclusive por API.
12. Não é possível deixar a igreja sem administrador ativo.
13. O provisionamento pode ser repetido sem duplicações ou perda de personalizações.
14. As funcionalidades e concessões existentes continuam funcionando.

## 9. Entrega

Implemente a solução e apresente:

- Resumo do modelo de autorização encontrado.
- Alterações realizadas e decisões de adaptação.
- Matriz final dos perfis e permissões efetivamente disponíveis.
- Procedimento para provisionar igrejas existentes e novas.
- Testes executados e resultados.
- Limitações ou módulos ainda ausentes.

Não declare testes como executados se não foram realizados. Não assuma que os módulos ou estruturas deste prompt já existem no repositório.