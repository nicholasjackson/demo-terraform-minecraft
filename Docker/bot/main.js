const mineflayer = require('mineflayer')
const { pathfinder, Movements, goals: { GoalNear } } = require('mineflayer-pathfinder')

async function createBot() {
  await sleep(10000);

  const bot = mineflayer.createBot({
    host: 'localhost',
    port: 25565,
    username: 'SRE',
  })

  bot.loadPlugin(pathfinder)

  bot.once('spawn', () => {
    bot.chat('Hello, I am SRE bot, I am keeping your server safe.');
    moveBot(bot);
  });

  bot.on('error', (err) => console.log(err))
  bot.on('end', createBot);
}

async function moveBot(bot) {
  while(true) {
    await sleep(20000);
    navigateTo(bot, 187, -3, 1072);

    await sleep(20000);
    navigateTo(bot, 200, -3, 1074);
  }
}

function navigateTo(bot, x, y, z) {
  const defaultMove = new Movements(bot)

  bot.pathfinder.setGoal(new GoalNear(x, y, z, 2))
}

function sleep(ms) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

// start the bot
createBot();