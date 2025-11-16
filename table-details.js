const { Sequelize } = require('sequelize');
const getConfig = require('./config/database');

async function showTableDetails() {
  try {
    const config = await getConfig();
    const sequelize = new Sequelize(config);
    
    await sequelize.authenticate();
    
    // Estrutura da tabela Tarefas
    const [columns] = await sequelize.query(`
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns 
      WHERE table_name = 'Tarefas' AND table_schema = 'public'
      ORDER BY ordinal_position;
    `);
    
    console.log('\n=== ESTRUTURA DA TABELA TAREFAS ===');
    columns.forEach(col => {
      console.log(`${col.column_name}: ${col.data_type} ${col.is_nullable === 'NO' ? '(NOT NULL)' : ''} ${col.column_default ? `DEFAULT ${col.column_default}` : ''}`);
    });
    
    // Dados da tabela Tarefas
    const [data] = await sequelize.query('SELECT * FROM "Tarefas" LIMIT 5;');
    
    console.log('\n=== DADOS DA TABELA TAREFAS (5 primeiros) ===');
    if (data.length === 0) {
      console.log('Nenhum dado encontrado.');
    } else {
      console.table(data);
    }
    
    // Contagem total
    const [count] = await sequelize.query('SELECT COUNT(*) as total FROM "Tarefas";');
    console.log(`\nTotal de registros: ${count[0].total}`);
    
    await sequelize.close();
  } catch (error) {
    console.error('Erro:', error.message);
  }
}

showTableDetails();
