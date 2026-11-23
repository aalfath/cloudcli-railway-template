// Creates or updates CloudCLI's single login from CLOUDCLI_USERNAME and
// CLOUDCLI_PASSWORD before the public port opens. CloudCLI itself lets the first
// visitor create the account and has no way to change the password later, so on
// Railway the variables are the source of truth: change them and redeploy.
import { createRequire } from 'node:module';

const APP = '/opt/cloudcli';
const require = createRequire(`${APP}/package.json`);
const bcrypt = require('bcrypt');
const { initializeDatabase } = await import(`${APP}/dist-server/server/modules/database/init-db.js`);
const { getConnection, closeConnection } = await import(`${APP}/dist-server/server/modules/database/connection.js`);

const say = (m) => console.log(`[railway] ${m}`);
const username = (process.env.CLOUDCLI_USERNAME || '').trim();
const password = process.env.CLOUDCLI_PASSWORD || '';

if (username.length < 3 || password.length < 8) {
  say('CLOUDCLI_USERNAME (3+ characters) and CLOUDCLI_PASSWORD (8+ characters) must be set in the service Variables.');
  say('Refusing to start: without them the first visitor to this URL could take over the app.');
  process.exit(1);
}

// The app's own schema and migrations, so the file matches what the server expects.
const log = console.log;
console.log = () => {};
await initializeDatabase();
console.log = log;
const db = getConnection();
const users = db.prepare('SELECT id, username, password_hash FROM users ORDER BY id').all();

if (users.length === 0) {
  db.prepare('INSERT INTO users (username, password_hash) VALUES (?, ?)').run(username, bcrypt.hashSync(password, 12));
  say(`Login "${username}" created.`);
} else {
  const user = users[0];
  if (user.username !== username || !bcrypt.compareSync(password, user.password_hash)) {
    db.prepare('UPDATE users SET username = ?, password_hash = ?, is_active = 1 WHERE id = ?')
      .run(username, bcrypt.hashSync(password, 12), user.id);
    // A new signing secret signs every browser out after a login change.
    db.prepare("DELETE FROM app_config WHERE key = 'jwt_secret'").run();
    say(`Login changed to "${username}" from the service Variables; every browser was signed out.`);
  } else {
    say(`Login "${username}" unchanged.`);
  }
}
closeConnection();
