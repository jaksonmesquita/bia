const { Sequelize } = require('sequelize');

// Configuração do banco
const sequelize = new Sequelize(
  process.env.DB_NAME || 'bia',
  process.env.DB_USER || 'postgres',
  process.env.DB_PASS || 'postgres',
  {
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5433,
    dialect: 'postgres',
    logging: false
  }
);

// Modelo da Tarefa
const Tarefa = sequelize.define('Tarefas', {
  uuid: {
    type: Sequelize.UUID,
    defaultValue: Sequelize.UUIDV1,
    primaryKey: true
  },
  titulo: {
    type: Sequelize.STRING,
    allowNull: false
  },
  dia_atividade: {
    type: Sequelize.STRING,
    allowNull: true
  },
  importante: {
    type: Sequelize.BOOLEAN,
    defaultValue: false
  }
});

async function criarTarefaOi() {
  try {
    await sequelize.authenticate();
    console.log('Conectado ao banco!');
    
    const tarefa = await Tarefa.create({
      titulo: 'Dizer oi para a equipe 👋',
      dia_atividade: 'hoje',
      importante: true
    });
    
    console.log('Tarefa criada:', tarefa.toJSON());
  } catch (error) {
    console.error('Erro:', error);
  } finally {
    await sequelize.close();
  }
}

criarTarefaOi();
