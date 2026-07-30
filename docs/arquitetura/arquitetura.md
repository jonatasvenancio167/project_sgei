<h1>Arquitetura</h1>

<p>
    A arquitetura é uma arquitetura monolitica utilizando conceito de modularização, já que cada tela acesso vai ser um módulo
    dentro do sistema. Isso impede que usuário não tenham acessos a menus ao qual não tem autorização e também facilite a
    comercialização do sistema, já que tem igrejas que deseja apenas ter um sistema para mídia, financeiros e etc.

    Atualmente o sistema é apenas um MVC para validar a utilização para igrejas com diferentes perfis e organização. A atual regra de negócio do sistema, permite que o usuário consiga customizar o sistema para se adaptar a seu modo de organização, fazendo
    com que o sistema utilize uma arquitetura separado em camadas de serviços, onde qualquer funcionalidade do sistema vai ser um serviço.
</p>

<h2>Serviços</h2>

<p>
    Algus modelos de serviços que vai ser utilizado no sistema será:
</p>

<ul>
    <li>Visão geral</li>
    <li>Calendário</li>
    <li>Eventos</li>
    <li>Departamentos</li>
    <li>Escalas</li>
    <li>Membros</li>
    <li>Aniversariantes</li>
    <li>Acolhimento</li>
    <li>Formulários</li>
    <li>Configurações</li>
</ul>

<p>
    Por conta disso, o sistema terá o seu serviço desacoplado com suas próprias regras de negócio
</p>

<h2>Multi-tenant</h2>

<p>
    Vamos utilizar o conceito de Multi-tenant, porque o sistema vai ter várias igrejas e essas igrejas pode ter igrejas filhas.
    Então cada igreja vai ter o seu login e sua configuração individual com seus respectivos dados e essas igrejas poderão 
    cadastrar as igrejas filhas ao qual vai tá ligado diretamente a essas igrejas, fazendo com quer a igreja que registrou a filha,
    possa ser a igreja mãe. 

    Exemplo: 

    tenho igreja A, B e C

    São igrejas distintas, então elas não conseguem visualizar os dados da outra. Se a igreja B cadastrar uma igreja AB dentro do sistema, então essa igreja AB vai pertencer a igreja B, levando em consideração a regra do coparticipante, onde a igreja AB vai tá ligado diretamente a igreja B e a igreja B poderá criar um registro de admin para o dirigente/secretário e esse dirigente/secretário poderá assim cadastrar os membros da sua congregação e assim realizar a gestão de sua igreja.
</p>

<p>
    A regra de isolamento multi-tenant e visibilidade entre igrejas no sistema Ekklesia. Essa é a regra de segurança mais crítica
    do sistema: nenhuma instituição pode ver dados de outra instituição que não tenha vínculo hierárquico com ela.

    ## 1. Conceito central

    O Ekklesia é um SaaS comercializado para múltiplos ministérios/igrejas. Cada ministério que contrata o sistema é um **tenant**
    completamente isolado dos demais.

    Dentro de um tenant, pode existir uma hierarquia:
    - **Sede (igreja mãe)**: instituição raiz do tenant. `parentInstitutionId === null`
    - **Congregação filha**: vinculada à sede. `parentInstitutionId === id da sede`
    - **Ponto de pregação**: vinculado a uma congregação ou à sede diretamente

    Regras fundamentais:
    1. **Tenants diferentes nunca se enxergam** — nem membros, nem departamentos, nem escalas, nem eventos, nem nada
    2. **Dentro do mesmo tenant**, a visibilidade depende da posição na hierarquia:
    - A **sede** enxerga seus próprios dados + dados de todas as filhas
    - Uma **congregação filha** enxerga apenas seus próprios dados
    - Uma filha **nunca enxerga dados de outra filha** da mesma sede

    ---

    ## 2. Modelagem de tenant (complementar ao que já existe)

    Aplicar `BaseEntity` em todas as entidades:
    - Membro, Departamento, Evento, Escala, RegistroAcolhimento, Formulário, AuditLog, etc.

    ---
   
    ## 4. Aplicação do escopo em cada módulo
        ### Membros
        - Usuário da sede: vê membros da sede + de todas as congregações filhas
        - Usuário de congregação filha: vê apenas membros da própria congregação
        - Na listagem, exibir coluna "Unidade" quando o usuário for da sede (para identificar de qual congregação é cada membro)

        ### Departamentos
        - Sede: vê departamentos de todas as unidades do tenant
        - Filha: vê apenas departamentos da própria unidade
        - Ao criar departamento, `institutionId` é preenchido automaticamente com a unidade do usuário logado

        ### Eventos / Cultos
        - Sede: vê e gerencia eventos da própria sede
        - Filha: vê e gerencia apenas seus próprios eventos
        - **Exceção — escala compartilhada**: o secretário/administrador da sede pode marcar um evento como "compartilhado com filhas". Nesse caso, as congregações filhas podem visualizar (mas não editar) o evento

    ### Escalas
    - Sede: visualiza escalas da própria sede
    - Filha: visualiza apenas suas próprias escalas
    - Secretário da sede pode **compartilhar uma escala** com congregações filhas específicas (ver seção 5)

    ### Acolhimento
    - Cada unidade vê apenas seus próprios registros de visita
    - Sede não acessa registros de acolhimento das filhas (dado sensível local)

    ### Formulários
    - Sede: vê e gerencia formulários de todas as unidades filhas (visão hierárquica, como Membros e Departamentos)
    - Filha: vê apenas os formulários da própria unidade
    - Gerenciar (criar/editar) um formulário continua restrito à unidade dona do registro, mesmo para a sede

    ### Aniversariantes
    - Filtrado pelos membros dentro de `allowedInstitutionIds`

    ### Configurações
    - Usuário da sede (administrador/secretário): vê e gerencia todas as unidades filhas
    - Usuário de congregação filha: vê apenas as configurações da própria unidade; não sabe da existência de outras filhas

    ## 5. Compartilhamento de escala (Sede → Filhas)

    O secretário ou administrador da **sede** pode compartilhar uma escala com congregações filhas selecionadas.

    UI na página de detalhe da escala (apenas para sede):
    - Botão "Compartilhar com congregações"
    - Modal com checklist das congregações filhas do tenant
    - Ao confirmar, as filhas selecionadas passam a ver a escala no módulo delas como somente leitura, com badge "Compartilhada pela sede"

    As filhas **não sabem** quais outras filhas receberam o compartilhamento.

    ## Observações técnicas
    - Todo filtro de tenant deve passar pelo `policy_scope` do Pundit (usando `BaseEntity`/`Church#accessible_church_ids` para os módulos com visão hierárquica) — nunca filtrar por `church_id` hardcodado em controllers ou queries
    - Todo model de domínio deve incluir o concern `BaseEntity`, que garante `belongs_to :church` + `validates :church_id, presence: true`, independente de mudanças futuras no `belongs_to`
    - Não alterar nenhuma outra página ou componente existente
</p>

<h2>stacks</h2>

<ul>
    <li><strong>Linguagem:</strong> Ruby 3.2.2</li>
    <li><strong>Framework:</strong> Rails 8</li>
    <li><strong>Banco de dados:</strong> PostgreSQL</li>
    <li><strong>Devops:</strong> Docker compose</li>
    <li><strong>Front-end:</strong> Hotwire/Tailwind</li>
</ul>