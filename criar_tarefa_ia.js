const { Sequelize } = require('sequelize');

const sequelize = new Sequelize('bia', 'postgres', 'postgres', {
  host: 'localhost',
  port: 5433,
  dialect: 'postgres',
  logging: false
});

const Tarefa = sequelize.define('Tarefas', {
  uuid: { type: Sequelize.UUID, defaultValue: Sequelize.UUIDV1, primaryKey: true },
  titulo: { type: Sequelize.STRING, allowNull: false },
  dia_atividade: { type: Sequelize.STRING },
  importante: { type: Sequelize.BOOLEAN, defaultValue: false }
});

async function criarTarefa() {
  await sequelize.authenticate();
  const tarefa = await Tarefa.create({
    titulo: 'tarefa com IA Q',
    dia_atividade: 'hoje',
    importante: false
  });
  console.log('Tarefa criada:', tarefa.titulo);
  await sequelize.close();
}

criarTarefa();
