const { Sequelize } = require('sequelize');
const getConfig = require('./config/database');

async function listTables() {
  try {
    const config = await getConfig();
    const sequelize = new Sequelize(config);
    
    console.log('Conectando no banco...');
    await sequelize.authenticate();
    console.log('Conexão estabelecida com sucesso!');
    
    const [results] = await sequelize.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      ORDER BY table_name;
    `);
    
    console.log('\n=== TABELAS DO BANCO BIA ===');
    if (results.length === 0) {
      console.log('Nenhuma tabela encontrada no schema public.');
    } else {
      results.forEach((row, index) => {
        console.log(`${index + 1}. ${row.table_name}`);
      });
    }
    
    await sequelize.close();
  } catch (error) {
    console.error('Erro ao conectar no banco:', error.message);
  }
}

listTables();
