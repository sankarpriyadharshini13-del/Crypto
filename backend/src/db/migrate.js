const db = require('./pool');
db.ensureSchema().then(() => db.close()).catch((e) => { console.error(e); process.exit(1); });
