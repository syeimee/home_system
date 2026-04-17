const Alexa = require('alexa-remote2');
const express = require('express');

const app = express();
app.use(express.json());

const PORT = process.env.ALEXA_PORT || 3100;
const PROXY_PORT = parseInt(process.env.ALEXA_PROXY_PORT || '3101', 10);
const AMAZON_HOST = process.env.AMAZON_HOST || 'alexa.amazon.co.jp';
const COOKIE_FILE = '/data/alexa-cookie.json';

let alexa = null;
let ready = false;

function initAlexa() {
  alexa = new Alexa();

  const options = {
    proxyOnly: true,
    proxyOwnIp: '0.0.0.0',
    proxyPort: PROXY_PORT,
    alexaServiceHost: AMAZON_HOST,
    cookieJustRecreate: false,
    cookieRefreshInterval: 7 * 24 * 60 * 60 * 1000,
    useWsMqtt: false,
    logger: console.log
  };

  // 保存済みCookieがあれば使う
  try {
    const fs = require('fs');
    if (fs.existsSync(COOKIE_FILE)) {
      const saved = JSON.parse(fs.readFileSync(COOKIE_FILE, 'utf8'));
      options.cookie = saved;
      console.log('Loaded saved cookie');
    }
  } catch (e) {
    console.log('No saved cookie found, proxy auth required');
  }

  alexa.init(options, function (err) {
    if (err) {
      console.error('Alexa init error:', err);
      if (String(err).includes('cookie')) {
        console.log(`\n========================================`);
        console.log(`Cookie auth required!`);
        console.log(`Open http://<server-ip>:${PROXY_PORT} in your browser`);
        console.log(`and log in with your Amazon account.`);
        console.log(`========================================\n`);
      }
      return;
    }

    // Cookie保存
    try {
      const fs = require('fs');
      fs.mkdirSync('/data', { recursive: true });
      fs.writeFileSync(COOKIE_FILE, JSON.stringify(alexa.cookieData));
      console.log('Cookie saved');
    } catch (e) {
      console.error('Failed to save cookie:', e.message);
    }

    ready = true;
    console.log('Alexa ready');
  });
}

// アナウンスAPI
app.post('/announce', (req, res) => {
  if (!ready) {
    return res.status(503).json({ error: 'Alexa not ready' });
  }

  const { message, devices } = req.body;
  if (!message) {
    return res.status(400).json({ error: 'message is required' });
  }

  // devicesが指定されていなければ全デバイスにアナウンス
  const target = devices && devices.length > 0 ? devices : null;

  if (target) {
    alexa.sendSequenceCommand(target, 'announcement', message, (err) => {
      if (err) {
        console.error('Announce error:', err);
        return res.status(500).json({ error: err.message || String(err) });
      }
      res.json({ status: 'ok' });
    });
  } else {
    // 全デバイス取得してアナウンス
    alexa.getDevices((err, deviceList) => {
      if (err) {
        return res.status(500).json({ error: err.message || String(err) });
      }

      const echoDevices = Object.values(deviceList.devices || {})
        .filter(d => d.capabilities && d.capabilities.includes('AUDIO_PLAYER'))
        .map(d => d.serialNumber);

      if (echoDevices.length === 0) {
        return res.status(404).json({ error: 'No Echo devices found' });
      }

      alexa.sendSequenceCommand(echoDevices, 'announcement', message, (err) => {
        if (err) {
          console.error('Announce error:', err);
          return res.status(500).json({ error: err.message || String(err) });
        }
        res.json({ status: 'ok', devices: echoDevices.length });
      });
    });
  }
});

// ヘルスチェック
app.get('/health', (_req, res) => {
  res.json({ status: ready ? 'ready' : 'initializing' });
});

app.listen(PORT, () => {
  console.log(`Alexa announce server listening on port ${PORT}`);
  initAlexa();
});
