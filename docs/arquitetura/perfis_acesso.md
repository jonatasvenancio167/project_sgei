# Perfis de acesso por igreja

A autorização continua no Pundit. Os menus consultam a mesma `Access::PermissionQuery` usada pelas policies. `Access::ScopeQuery` aplica as concessões às listagens, buscas e consultas de registros; exportações reutilizam o registro autorizado. Não existe mais liberação implícita quando falta uma permissão.

## Modelo

- `AccessProfile`: perfil da igreja, identificador estável, nome, descrição e indicador de padrão. `normalized_name` remove acentos, diferenças de caixa e espaços excedentes; seu índice único inclui `church_id`. Nomes iguais em igrejas diferentes são permitidos.
- `ChurchMembership`: vínculo usuário–igreja com situação e habilitação de acesso independentes. `users.church_id` continua indicando a igreja primária; a sessão pode selecionar outro vínculo ativo e habilitado.
- `ProfileAssignment`: associação de vários perfis a um vínculo. Chaves estrangeiras compostas impedem vincular perfis de outra igreja mesmo sem validações Rails.
- `RolePermission`: concessão por perfil, módulo, ação (`read`/`manage`) e alcance. A coluna antiga `role` fica disponível somente para migração; não é consultada na autorização.
- `Memberchip`: participação ou liderança explícita de um ministério. Não atribui perfil de acesso automaticamente. `users.position` é o cargo/função e não concede acesso.

Perfis personalizados herdam Membro. Os padrões também reutilizam a base Membro. Uma regra local substitui a regra herdada para o mesmo módulo e ação. As concessões de diferentes perfis se somam: uma regra desmarcada em um perfil não remove uma concessão válida de outro. Não há cache persistente de autorização.

Os alcances disponíveis são próprios registros, equipes participantes, ministérios liderados, própria igreja, hierarquia e eventos publicados para seu público. Eles são aplicados individualmente por módulo e ação. Hierarquia só amplia consulta nos módulos previstos pela arquitetura; nunca amplia edição de dados de congregações.

## Padrões efetivamente disponíveis

| Identificador | Nome | Concessões iniciais |
|---|---|---|
| `member` | Membro | Calendário/eventos publicados, próprios dados cadastrais e inscrições; consulta às escalas com atribuição própria. |
| `volunteer` | Voluntário | Base Membro, consulta aos ministérios participantes e suas escalas. |
| `leader` | Líder de ministério | Base Membro; consulta das equipes, gestão de ministérios e escalas explicitamente liderados, consulta dos participantes dessas equipes. |
| `secretary` | Secretaria | Base Membro; cadastros e vínculos organizacionais, eventos, formulários/inscrições e acolhimento; consulta de aniversariantes. Sem gestão de acessos. |
| `finance` | Financeiro / Tesouraria | Base Membro. Não cria acesso financeiro enquanto esse módulo não existir. |
| `pastor` | Pastoral | Base Membro; consulta de membros, ministérios, escalas e aniversariantes da igreja. Sem gestão de acessos. |
| `admin` | Administrador da igreja | Gestão de configurações, acessos e módulos administrativos existentes; consulta hierárquica onde prevista. |

A tela permite ao responsável pela gestão de acessos ajustar os menus, consulta, gestão e seus alcances. Essas escolhas podem ampliar os padrões, sempre dentro das regras do recurso e do isolamento entre igrejas. Mídia é um ministério; seus participantes usam Voluntário ou Líder de ministério, ou um perfil personalizado autorizado.

As capacidades ainda ausentes não foram criadas: disponibilidade, materiais privados de equipes, registros pastorais restritos, financeiro/aprovação de pagamentos e confirmação de escala. A consulta das próprias escalas já existentes é suportada; esses outros fluxos precisam de suas próprias implementações de domínio.

## Cadastro, edição e integridade

O formulário separa perfis, participação no ministério, ministérios liderados, cargo/função, situação cadastral e habilitação de acesso. Novos cadastros começam com Membro e sem senha. Habilitar acesso é uma ação explícita e exige senha para contas sem credenciais. O cadastro público por convite continua como fluxo explícito com senha, perfil base e aprovação pendente.

Somente concessão explícita de gestão de acessos permite mudar perfis e habilitar credenciais. Secretaria pode cadastrar e editar dados sem alterar concessões existentes. Valores privilegiados enviados sem autorização são rejeitados no servidor.

`Access::Integrity.guard` serializa alterações com bloqueio da igreja e impede remover o último administrador ativo, incluindo alterações concorrentes. Revogar acesso em uma igreja não remove o acesso do mesmo usuário em outra. Para contas compartilhadas entre igrejas, mudar e-mail ou redefinir senha de outra pessoa exige gestão de acessos em todas as igrejas vinculadas, evitando apropriação da conta por um administrador de apenas uma unidade. Exclusões de vínculo são lógicas. Alterações globais na situação do usuário também verificam os administradores das igrejas vinculadas.

O operador não pode ampliar os próprios perfis, liderança ou permissões, inclusive por alteração de um perfil herdado. Mudanças ficam registradas em `AuditLog`, com ator, igreja, destinatário e diferenças de concessões. Os perfis padrão não possuem opção de exclusão, e seus identificadores permanecem estáveis quando o nome é editado.

## Provisionamento e migração

Antes de atualizar um ambiente existente, faça o backup habitual do banco. Depois execute:

```bash
docker compose exec web bin/rails db:migrate
docker compose exec web bin/rails access_profiles:provision
```

A tarefa cria somente os perfis e regras ausentes. Repeti-la não duplica vínculos nem sobrescreve personalizações. Igrejas novas são provisionadas na criação, inclusive pelo onboarding e cadastro de congregações.

Contas antigas `admin` continuam Administrador da igreja. `leader`, `member` e `pastor` preservam seus identificadores; `co_pastor` é associado explicitamente a Pastoral. O vínculo organizacional de liderança só é preservado quando já existe em `memberchips`.

Configurações explícitas antigas de menus são transferidas para as regras de consulta correspondentes; onde não existiam, passam a valer os padrões acima. As credenciais existentes são preservadas. Igrejas sem administrador ativo são reportadas na saída da tarefa e precisam de regularização administrativa: a tarefa não promove ninguém automaticamente.

O banco mantém as colunas antigas durante a transição. Não execute uma reversão apenas de código após a migração de acessos: ela voltaria a consultar o enum antigo e perderia a semântica dos perfis múltiplos. Para reversão de ambiente, use o backup compatível com a versão anterior.

## Verificação

```bash
docker compose run --rm --no-deps test bundle exec rspec
docker compose exec web bin/rails zeitwerk:check
```

A cobertura inclui duplicidade e índice único, composição/revogação, isolamento com FKs compostas, cadastro sem credenciais, habilitação explícita, liderança por ministério, autoelevação, último administrador com duas revogações concorrentes, consulta hierárquica e troca autorizada de igreja.
