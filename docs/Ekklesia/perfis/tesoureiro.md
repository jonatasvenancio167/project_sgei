<h1>Tesoureiro</h1>

<p>A função do tesoureiro é gerenciar todas as entradas e saídas financeiras. Suas tarefas
    incluem registrar dizimos e ofertas, pagar contas de consumo e fornecedores, controlar o
    caixa e contas bancárias, guardar comprovantes, elaborar relatórios financeiros e prestar
    contas à liderança e à contabilidade.
</p>

<h3>Organização e Arrecadação</h2>

<ul>
    <li>Controlar o recebimento de dízimos, ofertas e doações</li>
    <li>Registrar todas as entradas e saídas no livro-caixa</li>
    <li>Organizar e arquivar notas fiscais, recibos e extratos bancários</li>
</ul>

<h3>Pagamentos e Gestão de Contas</h2>

<ul>
    <li>Pagar despesas fixas (como água, luz, aluguel e internet)</li>
    <li>Movimentar contas bancárias em conjunto com o pastor presidente</li>
    <li>Executar pagamentos de salários e encargos quando houver funcionários</li>
</ul>

<h3>Relatórios e Prestação de Contas</h2>

<ul>
    <li>Emitir relatórios e balancetes periódicos para a liderança e assembleia</li>
    <li>Enviar a documentação completa em dia para o escritório de contabilidade</li>
    <li>Participar do planejamento de custos e investimentos no templo ou em missões</li>
</ul>

<h2>Regra de negócio para o Tesoureiro</h2>

<h3>O que ele pode fazer</h3>

<p><strong>Financeiro - acesso total ao módulo:</strong></p>

<ul>
    <li>Registrar entradas: dízimos, ofertas, doações (com categoria, data, forma de pagamento: dinheiro, PIX, transferência)</li>
    <li>Registrar saídas: despesas fixas (água, luz, aluguel, internet), fornecedores, salários</li>
    <li>Anexar comprovantes (nota fiscal, recibo, extrato) em cada lançamento</li>
    <li>Controlar múltiplas contas (caixa físico, conta bancária)</li>
    <li>Emitir relatórios e balancetes por período</li>
    <li>Exportar documentação para contabilidade (PDF, CSV)</li>
    <li>Visualizar histórico completo de movimentações</li>
</ul>

<p><strong>Acesso de leitura em outros módulos - para cruzar dados financeiros com a operação da igreja:</strong></p>

<ul>
    <li>Membros: ver lista para registrar dízimos nominais, mas sem editar cadastro</li>
    <li>Eventos: visualizar para associar ofertas a cultos/eventos específicos</li>
    <li>Calendário: visualizar</li>
</ul>

<p><strong>O que ele não pode fazer</strong></p>

<ul>
    <li>Criar, editar ou excluir membros</li>
    <li>Criar ou editar departamentos, escalas, formulários</li>
    <li>Acessar Configurações do sistema</li>
    <li>Gerenciar usuários ou permissões</li>
    <li>Ver registros de acolhimento</li>
</ul>

<h2>Regras específicas que merecem atenção</h2>

<p>
    Dupla custódia em movimentações bancárias — historicamente igrejas exigem que movimentações em conta bancária sejam autorizadas por duas pessoas (tesoureiro + pastor). No sistema isso se traduz em:
</p>

<ul>
    <li>Lançamentos de conta bancária acima de um valor configurável ficam com status aguardando_aprovacao até o pastor aprovar</li>
    <li>Caixa físico o tesoureiro movimenta livremente</li>
</ul>

<p>
    <strong>Dízimos nominais vs. anônimos - </strong> o tesoureiro pode registrar um dízimo vinculado a um membro (para controle
    interno) ou como anônimo. Isso é sensível: só o tesoureiro e o pastor veem os dízimos nominais; outros perfis não têm acesso a
    essa informação.
    <strong>Isolamento multi-tenant - </strong> o tesoureiro de uma congregação filha só vê as finanças da própria congregação. O
    tesoureiro da sede vê as finanças da sede; para ver as filhas, o pastor/administrador precisa conceder explicitamente.
    <strong>Relatório para liderança - </strong>o tesoureiro gera o relatório, mas quem define o período e solicita é o pastor. O
    sistema pode ter uma funcionalidade de "solicitação de balancete" onde o pastor pede e o tesoureiro entrega dentro do sistema.
    <strong>Auditoria financeira - </strong> Todo lançamento registra created_by, updated_by e timestamp. Nenhum lançamento é
    deletado — apenas estornado (criando um lançamento inverso com referência ao original). Isso garante rastreabilidade total.
</p>

